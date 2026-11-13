"""Gate de saúde: confere se o sistema está de pé e cotando antes de gastar a bateria.

Só aborta por causa externa (front fora do ar, API sem responder, cotação quebrada por erro
de servidor). Resposta inesperada de um sistema no ar vira ``suspect`` e só gera WARN:
defeito tem que aparecer como cenário vermelho, nunca como aborto silencioso.
"""

from datetime import date, timedelta

import requests
from robot.api import logger
from robot.api.deco import keyword, library

from http_retry import TIMEOUT_PADRAO, api_url, com_retentativa


def _resultado(status, detalhe):
    """status: ok | down | suspect."""
    return {"status": status, "detail": detalhe}


@library(scope="GLOBAL")
class EnvironmentHealth:
    """Keywords do gate de saúde, chamadas no ``__init__.robot`` de cada pasta de suítes."""

    @keyword("Check Front Is Up")
    def check_front_is_up(self, base_url):
        resposta, erro = com_retentativa(lambda: requests.get(base_url, timeout=TIMEOUT_PADRAO))
        if erro:
            return _resultado("down", f"front não respondeu em {base_url} ({erro})")
        if resposta.status_code >= 500:
            return _resultado("down", f"front respondeu {resposta.status_code} em {base_url}")
        return _resultado("ok", f"front respondeu {resposta.status_code}")

    @keyword("Check Quotation Chain")
    def check_quotation_chain(self, base_url, api_key, store="PAU", group="A"):
        """Faz a mesma cotação da tela: se a cadeia de preço quebrar, nenhuma reserva fecha."""
        hoje = date.today()
        corpo = {
            "type": "PF", "pickup_store": store, "return_store": store, "group": group,
            "pickup_date": (hoje + timedelta(days=5)).isoformat(),
            "return_date": (hoje + timedelta(days=7)).isoformat(), "protections": ["BASICA"],
        }
        url = api_url(base_url, "/api/quotation")
        resposta, erro = com_retentativa(lambda: requests.post(
            url, json=corpo, headers={"X-Api-Key": api_key}, timeout=TIMEOUT_PADRAO))
        if erro:
            return _resultado("down", f"cotação sem resposta ({erro})")
        if resposta.status_code >= 500:
            return _resultado("down", f"cotação respondeu {resposta.status_code}")
        if resposta.status_code != 200 or "total" not in resposta.json():
            return _resultado("suspect", f"cotação respondeu {resposta.status_code}: {resposta.text[:120]}")
        return _resultado("ok", f"cotação ok, total {resposta.json()['total']}")

    @keyword("Abort Suite If Environment Is Down")
    def abort_suite_if_environment_is_down(self, *resultados):
        """Falha o Suite Setup só quando algum item está ``down``."""
        fora = [r["detail"] for r in resultados if r["status"] == "down"]
        for r in resultados:
            if r["status"] == "suspect":
                logger.warn(f"Gate de saúde: {r['detail']}")
            else:
                logger.info(f"Gate de saúde: {r['detail']}")
        if fora:
            raise AssertionError("Ambiente fora do ar, bateria abortada: " + " | ".join(fora))
