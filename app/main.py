"""Locadora Demo: sistema de reservas de carro feito só para ser o alvo dos testes.

Regras de negócio (as mesmas que a tela e a API aplicam):
- Reserva PF exige cliente cadastrado (CPF ou passaporte); PJ exige acordo.
- Pelo menos uma proteção; telefone de contato obrigatório; e-mail secundário opcional e válido.
- Grupo indisponível na loja: na criação pede decisão (forçar = Confirmada, solicitar = Solicitada).
  Na edição de reserva Confirmada, troca para grupo esgotado sem perguntar.
- Período com 28 dias ou mais vira tarifa Mensal (25% de desconto nas diárias).
- Motoristas adicionais: a tarifa (PF) ou o acordo (PJ) isenta uma quantidade; o resto é cobrado.
- Cliente com reserva ativa no mesmo período: pede confirmação.
- Acordo de carro reserva (replacement) exige número do sinistro e marca is_replacement.
Estado em memória: reiniciar o processo zera tudo.
"""

import os
import re
import threading
from datetime import date, datetime
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse, Response
from fastapi.templating import Jinja2Templates

from catalog import (
    ACCESSORIES, ADDITIONAL_DRIVER_DAILY, AGREEMENTS, CANCEL_REASONS, GROUPS, MONTHLY_MIN_DAYS,
    PROTECTIONS, RATES, STORES, ZIP_CODES,
)

API_KEY = os.environ.get("DEMO_API_KEY", "demo-key")
BASE = Path(__file__).parent
templates = Jinja2Templates(directory=str(BASE / "templates"))
app = FastAPI(title="Locadora Demo", docs_url="/api/docs")

_lock = threading.Lock()
_clients = {}
_reservations = {}
_seq = {"client": 0, "reservation": 100000}
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$")
PASSPORT_RE = re.compile(r"^[A-Z]{2}\d{6}$")


class BusinessError(Exception):
    def __init__(self, status, code, message):
        super().__init__(message)
        self.status, self.code, self.message = status, code, message


@app.exception_handler(BusinessError)
def _business_error(_, exc):
    return JSONResponse(status_code=exc.status, content={"code": exc.code, "message": exc.message})


# ---------------------------------------------------------------- validações

def only_digits(value):
    return re.sub(r"\D", "", str(value or ""))


def is_valid_cpf(value):
    cpf = only_digits(value)
    if len(cpf) != 11 or cpf == cpf[0] * 11:
        return False
    for size in (9, 10):
        total = sum(int(cpf[i]) * (size + 1 - i) for i in range(size))
        digit = (total * 10 % 11) % 10
        if digit != int(cpf[size]):
            return False
    return True


def normalize_doc(doc_type, doc):
    if doc_type == "PASSAPORTE":
        return str(doc or "").strip().upper()
    return only_digits(doc)


def is_valid_doc(doc_type, doc):
    if doc_type == "PASSAPORTE":
        return bool(PASSPORT_RE.match(normalize_doc(doc_type, doc)))
    return is_valid_cpf(doc)


def parse_date(value, field):
    try:
        return date.fromisoformat(str(value))
    except ValueError as exc:
        raise BusinessError(422, "INVALID_DATE", f"Data inválida em {field}.") from exc


def require_key(key):
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="X-Api-Key inválida")


# ---------------------------------------------------------------- preço

def quote(body):
    pickup = parse_date(body.get("pickup_date"), "retirada")
    ret = parse_date(body.get("return_date"), "devolução")
    if ret <= pickup:
        raise BusinessError(422, "INVALID_PERIOD", "A devolução precisa ser depois da retirada.")
    days = (ret - pickup).days
    group = GROUPS.get(body.get("group") or "A")
    if not group:
        raise BusinessError(422, "INVALID_GROUP", "Grupo inexistente.")

    if body.get("type") == "PJ":
        agreement = AGREEMENTS.get(body.get("agreement") or "")
        if not agreement:
            raise BusinessError(422, "AGREEMENT_REQUIRED", "Selecione o acordo.")
        discount, free_drivers, rate_code = agreement["discount"], agreement["free_drivers"], "ACORDO"
        rate_name = f"Tarifa do acordo {agreement['name']}"
    else:
        rate_code = "MENSAL" if days >= MONTHLY_MIN_DAYS else (body.get("rate") or "LIVRE")
        if rate_code == "MENSAL" and days < MONTHLY_MIN_DAYS:
            rate_code = "LIVRE"
        rate = RATES[rate_code]
        discount, free_drivers, rate_name = rate["discount"], rate["free_drivers"], rate["name"]

    daily_total = round(group["daily"] * days * (1 - discount), 2)
    protections = round(sum(PROTECTIONS[p]["daily"] for p in body.get("protections") or []) * days, 2)
    accessories = round(sum(ACCESSORIES[a]["daily"] for a in body.get("accessories") or []) * days, 2)
    drivers = len(body.get("additional_drivers") or [])
    exempt = min(drivers, free_drivers)
    charged = drivers - exempt
    drivers_total = round(charged * ADDITIONAL_DRIVER_DAILY * days, 2)
    return {
        "days": days, "rate": rate_code, "rate_name": rate_name, "group_name": group["name"],
        "daily_total": daily_total, "protections_total": protections,
        "accessories_total": accessories, "drivers_exempt": exempt, "drivers_charged": charged,
        "drivers_total": drivers_total,
        "total": round(daily_total + protections + accessories + drivers_total, 2),
    }


# ---------------------------------------------------------------- reservas

def _overlaps(a_start, a_end, b_start, b_end):
    return a_start < b_end and b_start < a_end


def _active_overlap(client_id, pickup, ret, ignore=None):
    for r in _reservations.values():
        if r["number"] == ignore or r["status"] == "Cancelada" or r.get("client_id") != client_id:
            continue
        if _overlaps(pickup, ret, date.fromisoformat(r["pickup_date"]), date.fromisoformat(r["return_date"])):
            return r["number"]
    return None


def _validate_common(body):
    if body.get("pickup_store") not in STORES or body.get("return_store") not in STORES:
        raise BusinessError(422, "STORE_REQUIRED", "Selecione as lojas de retirada e devolução.")
    if not body.get("protections"):
        raise BusinessError(422, "PROTECTION_REQUIRED", "Selecione pelo menos uma proteção.")
    contact = body.get("contact") or {}
    if not only_digits(contact.get("phone")):
        raise BusinessError(422, "PHONE_REQUIRED", "Informe o telefone de contato.")
    secondary = contact.get("secondary_email")
    if secondary and not EMAIL_RE.match(secondary):
        raise BusinessError(422, "INVALID_EMAIL", "E-mail secundário inválido.")
    driver = body.get("driver") or {}
    if not is_valid_doc(driver.get("doc_type", "CPF"), driver.get("doc")):
        raise BusinessError(422, "INVALID_DRIVER", "Documento do condutor inválido.")
    seen = {normalize_doc(driver.get("doc_type", "CPF"), driver.get("doc"))}
    for extra in body.get("additional_drivers") or []:
        if not is_valid_cpf(extra):
            raise BusinessError(422, "INVALID_ADDITIONAL_DRIVER", "Documento do motorista adicional inválido.")
        if only_digits(extra) in seen:
            raise BusinessError(422, "DUPLICATED_DRIVER", "Motorista já informado nesta reserva.")
        seen.add(only_digits(extra))


def create_reservation(body):
    _validate_common(body)
    kind = body.get("type", "PF")
    client = None
    if kind == "PF":
        client = _clients.get(body.get("client_id"))
        if not client:
            raise BusinessError(422, "CLIENT_REQUIRED", "Cliente não encontrado.")
    else:
        agreement = AGREEMENTS.get(body.get("agreement") or "")
        if not agreement:
            raise BusinessError(422, "AGREEMENT_REQUIRED", "Selecione o acordo.")
        if agreement["replacement"] and not str(body.get("claim_number") or "").strip():
            raise BusinessError(422, "CLAIM_REQUIRED", "Informe o número do sinistro.")

    price = quote(body)
    pickup, ret = date.fromisoformat(body["pickup_date"]), date.fromisoformat(body["return_date"])
    if client and not body.get("confirm_overlap"):
        other = _active_overlap(client["id"], pickup, ret)
        if other:
            raise BusinessError(409, "ACTIVE_RESERVATION", f"Cliente já possui a reserva {other} ativa no período.")

    status = "Confirmada"
    if body.get("group") in STORES[body["pickup_store"]]["unavailable_groups"]:
        action = body.get("unavailable_action")
        if action not in ("FORCAR", "SOLICITAR"):
            raise BusinessError(409, "GROUP_UNAVAILABLE", "Grupo selecionado indisponível na loja de retirada.")
        status = "Confirmada" if action == "FORCAR" else "Solicitada"

    with _lock:
        _seq["reservation"] += 1
        number = f"R{_seq['reservation']}"
    agreement = AGREEMENTS.get(body.get("agreement") or "") if kind == "PJ" else None
    reservation = {
        "number": number, "type": kind, "status": status, "channel": body.get("channel", "Balcão"),
        "client_id": client["id"] if client else None,
        "client_name": f"{client['first_name']} {client['last_name']}" if client else agreement["name"],
        "client_doc": client["doc"] if client else agreement["cnpj"],
        "client_doc_type": client["doc_type"] if client else "CNPJ",
        "agreement": body.get("agreement") if kind == "PJ" else None,
        "is_replacement": bool(agreement and agreement["replacement"]),
        "claim_number": body.get("claim_number") or None,
        "external_reservation": body.get("external_reservation") or None,
        "driver": {
            "doc_type": body["driver"].get("doc_type", "CPF"),
            "doc": normalize_doc(body["driver"].get("doc_type", "CPF"), body["driver"]["doc"]),
            "name": body["driver"].get("name") or (reservation_name(client)),
        },
        "additional_drivers": [only_digits(d) for d in body.get("additional_drivers") or []],
        "pickup_store": body["pickup_store"], "return_store": body["return_store"],
        "pickup_date": body["pickup_date"], "return_date": body["return_date"],
        "group": body.get("group") or "A", "rate": price["rate"],
        "protections": list(body["protections"]), "accessories": list(body.get("accessories") or []),
        "contact": body.get("contact"), "price": price, "cancel_reason": None,
        "created_at": datetime.now().isoformat(timespec="seconds"), "emails_sent": 1,
    }
    _reservations[number] = reservation
    return reservation


def reservation_name(client):
    return f"{client['first_name']} {client['last_name']}" if client else ""


def update_reservation(number, body):
    current = _get(number)
    if current["status"] == "Cancelada":
        raise BusinessError(409, "CANCELLED", "Reserva cancelada não pode ser editada.")
    merged = {**current, **{k: v for k, v in body.items() if v is not None}}
    merged["driver"] = current["driver"]
    _validate_common(merged)
    group_down = merged["group"] in STORES[merged["pickup_store"]]["unavailable_groups"]
    if group_down and current["status"] != "Confirmada" and not body.get("unavailable_action"):
        raise BusinessError(409, "GROUP_UNAVAILABLE", "Grupo selecionado indisponível na loja de retirada.")
    merged["price"] = quote(merged)
    merged["rate"] = merged["price"]["rate"]
    _reservations[number] = merged
    return merged


def _get(number):
    reservation = _reservations.get(number)
    if not reservation:
        raise BusinessError(404, "NOT_FOUND", f"Reserva {number} não encontrada.")
    return reservation


def search_reservations(filters):
    number = (filters.get("number") or "").strip().upper()
    client_doc = normalize_doc("CPF", filters.get("client_doc")) if filters.get("client_doc") else ""
    driver_doc = (filters.get("driver_doc") or "").strip().upper()
    agreement = filters.get("agreement") or ""
    if not (number or client_doc or driver_doc or agreement):
        raise BusinessError(
            422, "MAIN_FILTER_REQUIRED",
            "Informe número, CPF do cliente, documento do condutor ou acordo para pesquisar.",
        )
    found = []
    for r in _reservations.values():
        if number and r["number"] != number:
            continue
        if client_doc and r["client_doc"] != client_doc:
            continue
        if driver_doc and only_digits(driver_doc) != r["driver"]["doc"] and driver_doc != r["driver"]["doc"]:
            continue
        if agreement and r["agreement"] != agreement:
            continue
        if filters.get("status") and r["status"] != filters["status"]:
            continue
        if filters.get("channel") and r["channel"] != filters["channel"]:
            continue
        found.append(r)
    return sorted(found, key=lambda r: r["number"])


# ---------------------------------------------------------------- API

@app.get("/api/health")
def health():
    return {"status": "ok", "reservations": len(_reservations), "clients": len(_clients)}


@app.get("/api/catalog")
def catalog():
    return {
        "stores": STORES, "groups": GROUPS, "rates": RATES, "protections": PROTECTIONS,
        "accessories": ACCESSORIES, "agreements": AGREEMENTS, "cancel_reasons": CANCEL_REASONS,
        "monthly_min_days": MONTHLY_MIN_DAYS, "additional_driver_daily": ADDITIONAL_DRIVER_DAILY,
    }


@app.get("/api/zip/{zip_code}")
def zip_lookup(zip_code: str):
    found = ZIP_CODES.get(only_digits(zip_code))
    if not found:
        raise BusinessError(404, "ZIP_NOT_FOUND", "CEP não encontrado.")
    return found


@app.post("/api/clients", status_code=201)
async def api_create_client(request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    body = await request.json()
    doc_type = body.get("doc_type", "CPF")
    if not str(body.get("first_name") or "").strip() or not str(body.get("last_name") or "").strip():
        raise BusinessError(422, "NAME_REQUIRED", "Informe nome e sobrenome.")
    if not is_valid_doc(doc_type, body.get("doc")):
        raise BusinessError(422, "INVALID_DOC", "Documento inválido.")
    doc = normalize_doc(doc_type, body.get("doc"))
    if any(c["doc"] == doc for c in _clients.values()):
        raise BusinessError(409, "DUPLICATED_DOC", "Este documento já possui cadastro.")
    with _lock:
        _seq["client"] += 1
        client_id = _seq["client"]
    client = {
        "id": client_id, "doc_type": doc_type, "doc": doc,
        "nationality": body.get("nationality", "Brasileira"),
        "first_name": body["first_name"].strip(), "last_name": body["last_name"].strip(),
        "email": body.get("email", ""), "phone": body.get("phone", ""), "address": body.get("address", {}),
    }
    _clients[client_id] = client
    return client


@app.get("/api/clients")
def api_find_client(doc: str, doc_type: str = "CPF", x_api_key: str = Header(None)):
    require_key(x_api_key)
    wanted = normalize_doc(doc_type, doc)
    for client in _clients.values():
        if client["doc"] == wanted:
            return client
    raise BusinessError(404, "CLIENT_NOT_FOUND", "Cliente não cadastrado.")


@app.delete("/api/clients/{client_id}", status_code=204)
def api_delete_client(client_id: int, x_api_key: str = Header(None)):
    require_key(x_api_key)
    _clients.pop(client_id, None)
    return Response(status_code=204)


@app.post("/api/quotation")
async def api_quotation(request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    return quote(await request.json())


@app.post("/api/reservations", status_code=201)
async def api_create_reservation(request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    return create_reservation(await request.json())


@app.get("/api/reservations")
def api_search(request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    return search_reservations(dict(request.query_params))


@app.get("/api/reservations/{number}")
def api_get(number: str, x_api_key: str = Header(None)):
    require_key(x_api_key)
    return _get(number)


@app.put("/api/reservations/{number}")
async def api_update(number: str, request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    return update_reservation(number, await request.json())


@app.post("/api/reservations/{number}/cancel")
async def api_cancel(number: str, request: Request, x_api_key: str = Header(None)):
    require_key(x_api_key)
    reason = (await request.json()).get("reason")
    if reason not in CANCEL_REASONS:
        raise BusinessError(422, "REASON_REQUIRED", "Selecione o motivo do cancelamento.")
    reservation = _get(number)
    reservation["status"], reservation["cancel_reason"] = "Cancelada", reason
    return reservation


@app.post("/api/reservations/{number}/resend-email")
def api_resend(number: str, x_api_key: str = Header(None)):
    require_key(x_api_key)
    reservation = _get(number)
    reservation["emails_sent"] += 1
    return {"sent_to": reservation["contact"].get("email"), "emails_sent": reservation["emails_sent"]}


@app.delete("/api/reservations/{number}", status_code=204)
def api_delete(number: str, x_api_key: str = Header(None)):
    require_key(x_api_key)
    _reservations.pop(number, None)
    return Response(status_code=204)


# ---------------------------------------------------------------- telas

def _page(request, name, **context):
    return templates.TemplateResponse(
        request, name, {"api_key": API_KEY, "stores": STORES, "groups": GROUPS, "rates": RATES,
                        "protections": PROTECTIONS, "accessories": ACCESSORIES,
                        "agreements": AGREEMENTS, "cancel_reasons": CANCEL_REASONS, **context},
    )


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return _page(request, "home.html")


@app.get("/clientes/novo", response_class=HTMLResponse)
def client_new(request: Request):
    return _page(request, "client_new.html")


@app.get("/reservas/nova-pf", response_class=HTMLResponse)
def reservation_new_pf(request: Request):
    return _page(request, "reservation_form.html", kind="PF")


@app.get("/reservas/nova-pj", response_class=HTMLResponse)
def reservation_new_pj(request: Request):
    return _page(request, "reservation_form.html", kind="PJ")


@app.get("/reservas", response_class=HTMLResponse)
def reservation_search(request: Request):
    return _page(request, "search.html")


@app.get("/reservas/{number}", response_class=HTMLResponse)
def reservation_detail(request: Request, number: str):
    return _page(request, "detail.html", r=_get(number), new=request.query_params.get("nova") == "1")


@app.get("/reservas/{number}/editar", response_class=HTMLResponse)
def reservation_edit(request: Request, number: str):
    return _page(request, "edit.html", r=_get(number))


@app.get("/reservas/{number}/pdf")
def reservation_pdf(number: str):
    r = _get(number)
    text = f"Reserva {r['number']} - {r['status']} - Total R$ {r['price']['total']:.2f}"
    stream = f"BT /F1 12 Tf 40 780 Td ({text}) Tj ET"
    objects = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R "
        "/Resources << /Font << /F1 5 0 R >> >> >>",
        f"<< /Length {len(stream)} >>\nstream\n{stream}\nendstream",
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    pdf, offsets = "%PDF-1.4\n", []
    for i, obj in enumerate(objects, 1):
        offsets.append(len(pdf))
        pdf += f"{i} 0 obj\n{obj}\nendobj\n"
    xref = len(pdf)
    pdf += f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n"
    pdf += "".join(f"{o:010d} 00000 n \n" for o in offsets)
    pdf += f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF"
    return Response(
        pdf.encode("latin-1", "replace"), media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="reserva-{number}.pdf"'},
    )
