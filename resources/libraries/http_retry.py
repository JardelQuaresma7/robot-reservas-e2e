"""Chamadas HTTP num lugar só: URL, timeout e retentativa.

As funções devolvem ``(resposta, erro)``. ``erro`` é texto quando a chamada não chegou a ter
resposta (timeout, conexão recusada) depois de todas as tentativas. Status HTTP diferente de 2xx
não é erro aqui: quem chama decide o que ele significa.
"""

import time

import requests

TIMEOUT_PADRAO = 30
TENTATIVAS = 3
ESPERA_ENTRE_TENTATIVAS = 2


def api_url(base_url, caminho):
    return f"{str(base_url).rstrip('/')}/{str(caminho).lstrip('/')}"


def com_retentativa(chamada, tentativas=TENTATIVAS, espera=ESPERA_ENTRE_TENTATIVAS):
    """Executa ``chamada`` até ``tentativas`` vezes. Devolve ``(resposta, erro)``."""
    erro = None
    for tentativa in range(1, tentativas + 1):
        try:
            return chamada(), None
        except requests.RequestException as falha:
            erro = f"{type(falha).__name__} na tentativa {tentativa}/{tentativas}"
            if tentativa < tentativas:
                time.sleep(espera)
    return None, erro


def erro_curto(falha):
    """Exceção do requests numa frase, sem o traceback do urllib3."""
    if isinstance(falha, requests.exceptions.ConnectTimeout):
        return "timeout ao conectar"
    if isinstance(falha, requests.exceptions.ReadTimeout):
        return "timeout esperando resposta"
    if isinstance(falha, requests.exceptions.SSLError):
        return "erro de SSL"
    if isinstance(falha, requests.exceptions.ConnectionError):
        return "conexão recusada, servidor provavelmente fora do ar"
    return type(falha).__name__
