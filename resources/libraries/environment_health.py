"""Gate de saúde: confere se o ambiente está de pé antes de gastar a bateria.

A regra é só abortar por causa externa (site fora do ar, API sem responder). Resposta inesperada
de uma API que está no ar vira ``suspect`` e só gera WARN: defeito do sistema tem que aparecer
como cenário vermelho, nunca como aborto silencioso da bateria.
"""

import requests
from robot.api import logger
from robot.api.deco import keyword, library

from http_retry import api_url, com_retentativa, TIMEOUT_PADRAO


def _resultado(status, detalhe):
    """status: ok | down | suspect."""
    return {"status": status, "detail": detalhe}


@library(scope="GLOBAL")
class EnvironmentHealth:
    """Keywords do gate de saúde, usadas no ``__init__.robot`` de cada pasta de suítes."""

    @keyword("Check Web Is Up")
    def check_web_is_up(self, base_url, texto_esperado="Welcome to the Simple Travel Agency!"):
        resposta, erro = com_retentativa(lambda: requests.get(base_url, timeout=TIMEOUT_PADRAO))
        if erro:
            return _resultado("down", f"front não respondeu em {base_url} ({erro})")
        if resposta.status_code >= 500:
            return _resultado("down", f"front respondeu {resposta.status_code} em {base_url}")
        if texto_esperado not in resposta.text:
            return _resultado("suspect", f"front no ar, mas sem o texto '{texto_esperado}'")
        return _resultado("ok", f"front respondeu {resposta.status_code} em {base_url}")

    @keyword("Check Booking Api Is Up")
    def check_booking_api_is_up(self, api_base_url):
        url = api_url(api_base_url, "/ping")
        resposta, erro = com_retentativa(lambda: requests.get(url, timeout=TIMEOUT_PADRAO))
        if erro:
            return _resultado("down", f"API não respondeu em {url} ({erro})")
        if resposta.status_code != 201:
            return _resultado("suspect", f"/ping respondeu {resposta.status_code}, esperado 201")
        return _resultado("ok", "API de reservas respondeu ao /ping")

    @keyword("Abort Suite If Environment Is Down")
    def abort_suite_if_environment_is_down(self, *resultados):
        """Falha a suíte inteira (Suite Setup) só quando algum item está ``down``."""
        fora = [r["detail"] for r in resultados if r["status"] == "down"]
        for r in resultados:
            if r["status"] == "suspect":
                logger.warn(f"Gate de saúde: {r['detail']}")
            else:
                logger.info(f"Gate de saúde: {r['detail']}")
        if fora:
            raise AssertionError("Ambiente fora do ar, bateria abortada: " + " | ".join(fora))
