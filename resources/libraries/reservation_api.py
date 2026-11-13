"""Cliente da API da locadora: prepara massa (cliente, reserva) e garante a limpeza.

Tudo que a suíte cria pela API ou pela tela é registrado aqui, e o ``Suite Teardown`` apaga,
inclusive o que sobrou de cenário que falhou no meio. Assim a massa não se acumula.
"""

from datetime import date, timedelta

import requests
from robot.api import logger
from robot.api.deco import keyword, library

from http_retry import TIMEOUT_PADRAO, api_url, com_retentativa


@library(scope="SUITE")
class ReservationApi:
    """Keywords de preparação e limpeza pela API, com retentativa centralizada."""

    def __init__(self, base_url="http://127.0.0.1:8000", api_key="demo-key"):
        self.base_url = base_url
        self.api_key = api_key
        self._clients = []
        self._reservations = []

    def _call(self, method, path, **kwargs):
        url = api_url(self.base_url, path)
        resposta, erro = com_retentativa(lambda: requests.request(
            method, url, headers={"X-Api-Key": self.api_key}, timeout=TIMEOUT_PADRAO, **kwargs))
        if erro:
            raise AssertionError(f"{method} {path} sem resposta: {erro}")
        logger.info(f"{method} {path} -> {resposta.status_code}")
        return resposta

    @staticmethod
    def _expect(resposta, esperado):
        if resposta.status_code != int(esperado):
            raise AssertionError(f"Status {resposta.status_code}, esperado {esperado}: {resposta.text[:300]}")

    # ------------------------------------------------------------ clientes
    @keyword("Create Client Via Api")
    def create_client_via_api(self, client):
        resposta = self._call("POST", "/api/clients", json=client)
        self._expect(resposta, 201)
        criado = resposta.json()
        self._clients.append(criado["id"])
        return criado

    @keyword("Find Client Via Api")
    def find_client_via_api(self, doc, doc_type="CPF"):
        resposta = self._call("GET", "/api/clients", params={"doc": doc, "doc_type": doc_type})
        return resposta.json() if resposta.status_code == 200 else None

    @keyword("Register Client For Cleanup")
    def register_client_for_cleanup(self, doc, doc_type="CPF"):
        """Cliente criado pela tela entra na limpeza pelo documento."""
        client = self.find_client_via_api(doc, doc_type)
        if client:
            self._clients.append(client["id"])
        return client

    # ------------------------------------------------------------ reservas
    @keyword("Create Reservation Via Api")
    def create_reservation_via_api(self, client, pickup_in_days=10, days=3, group="A", store="PAU",
                                   **extra):
        """Reserva PF mínima e válida para preparar cenários de consulta e edição."""
        pickup = date.today() + timedelta(days=int(pickup_in_days))
        corpo = {
            "type": "PF", "client_id": client["id"], "pickup_store": store, "return_store": store,
            "pickup_date": pickup.isoformat(), "return_date": (pickup + timedelta(days=int(days))).isoformat(),
            "group": group, "protections": ["BASICA"],
            "driver": {"doc_type": client["doc_type"], "doc": client["doc"],
                       "name": f"{client['first_name']} {client['last_name']}"},
            "contact": {"phone": client["phone"], "email": client["email"]},
        }
        corpo.update(extra)
        resposta = self._call("POST", "/api/reservations", json=corpo)
        self._expect(resposta, 201)
        reserva = resposta.json()
        self._reservations.append(reserva["number"])
        return reserva

    @keyword("Get Reservation Via Api")
    def get_reservation_via_api(self, number):
        resposta = self._call("GET", f"/api/reservations/{number}")
        self._expect(resposta, 200)
        return resposta.json()

    @keyword("Register Reservation For Cleanup")
    def register_reservation_for_cleanup(self, number):
        if number and number not in self._reservations:
            self._reservations.append(number)

    @keyword("Pdf Should Be Downloadable")
    def pdf_should_be_downloadable(self, url):
        resposta, erro = com_retentativa(lambda: requests.get(url, timeout=TIMEOUT_PADRAO))
        if erro:
            raise AssertionError(f"PDF sem resposta: {erro}")
        self._expect(resposta, 200)
        if resposta.headers.get("content-type") != "application/pdf" or not resposta.content.startswith(b"%PDF"):
            raise AssertionError(f"Download não é PDF: {resposta.headers.get('content-type')}")
        if "attachment" not in resposta.headers.get("content-disposition", ""):
            raise AssertionError("PDF não vem como anexo para download.")
        return len(resposta.content)

    # ------------------------------------------------------------ API pura
    @keyword("Call Api")
    def call_api(self, method, path, body=None, expected_status=200):
        resposta = self._call(method, path, json=body)
        self._expect(resposta, expected_status)
        try:
            return resposta.json()
        except ValueError:
            return None

    @keyword("Call Api Without Key")
    def call_api_without_key(self, method, path):
        resposta, erro = com_retentativa(lambda: requests.request(
            method, api_url(self.base_url, path), timeout=TIMEOUT_PADRAO))
        if erro:
            raise AssertionError(erro)
        return resposta.status_code

    # ------------------------------------------------------------ limpeza
    @keyword("Delete Test Data Created By Suite")
    def delete_test_data_created_by_suite(self):
        """Limpeza do ``Suite Teardown``: nunca falha, só avisa o que sobrou."""
        for number in list(self._reservations):
            resposta = self._call("DELETE", f"/api/reservations/{number}")
            if resposta.status_code == 204:
                self._reservations.remove(number)
            else:
                logger.warn(f"Reserva {number} não apagada ({resposta.status_code})")
        for client_id in list(self._clients):
            resposta = self._call("DELETE", f"/api/clients/{client_id}")
            if resposta.status_code == 204:
                self._clients.remove(client_id)
