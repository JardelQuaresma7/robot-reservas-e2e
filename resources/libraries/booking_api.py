"""Cliente da API de reservas (Restful-Booker) com registro do que foi criado.

Toda reserva criada pela bateria entra num registro, e o ``Suite Teardown`` apaga todas,
inclusive as de cenários que falharam no meio. Assim a massa não se acumula no ambiente.
"""

import requests
from robot.api import logger
from robot.api.deco import keyword, library

from http_retry import api_url, com_retentativa, TIMEOUT_PADRAO


@library(scope="SUITE")
class BookingApi:
    """Keywords de reserva via API, com token, retentativa e limpeza."""

    def __init__(self, base_url="https://restful-booker.herokuapp.com"):
        self.base_url = base_url
        self._token = None
        self._criadas = []

    def _chamar(self, metodo, caminho, **kwargs):
        url = api_url(self.base_url, caminho)
        headers = {"Accept": "application/json", **kwargs.pop("headers", {})}
        resposta, erro = com_retentativa(
            lambda: requests.request(metodo, url, headers=headers, timeout=TIMEOUT_PADRAO, **kwargs)
        )
        if erro:
            raise AssertionError(f"{metodo} {caminho} sem resposta: {erro}")
        logger.info(f"{metodo} {caminho} -> {resposta.status_code}")
        return resposta

    def _auth_header(self):
        if not self._token:
            raise AssertionError("Sem token: chame 'Authenticate As Admin' antes.")
        return {"Cookie": f"token={self._token}"}

    @keyword("Authenticate As Admin")
    def authenticate_as_admin(self, usuario, senha):
        resposta = self._chamar("POST", "/auth", json={"username": usuario, "password": senha})
        token = resposta.json().get("token")
        if not token:
            raise AssertionError(f"Login recusado: {resposta.text}")
        self._token = token
        return token

    @keyword("Create Booking")
    def create_booking(self, reserva):
        resposta = self._chamar("POST", "/booking", json=reserva)
        if resposta.status_code != 200:
            raise AssertionError(f"Criação recusada ({resposta.status_code}): {resposta.text}")
        corpo = resposta.json()
        self._criadas.append(corpo["bookingid"])
        return corpo

    @keyword("Get Booking")
    def get_booking(self, booking_id, status_esperado=200):
        resposta = self._chamar("GET", f"/booking/{booking_id}")
        self._conferir_status(resposta, status_esperado)
        return resposta.json() if resposta.status_code == 200 else None

    @keyword("Search Bookings By Name")
    def search_bookings_by_name(self, nome, sobrenome):
        resposta = self._chamar("GET", "/booking", params={"firstname": nome, "lastname": sobrenome})
        self._conferir_status(resposta, 200)
        return [item["bookingid"] for item in resposta.json()]

    @keyword("Update Booking")
    def update_booking(self, booking_id, reserva, com_token=True, status_esperado=200):
        headers = self._auth_header() if com_token else {}
        resposta = self._chamar("PUT", f"/booking/{booking_id}", json=reserva, headers=headers)
        self._conferir_status(resposta, status_esperado)
        return resposta.json() if resposta.status_code == 200 else None

    @keyword("Partial Update Booking")
    def partial_update_booking(self, booking_id, **campos):
        resposta = self._chamar(
            "PATCH", f"/booking/{booking_id}", json=campos, headers=self._auth_header()
        )
        self._conferir_status(resposta, 200)
        return resposta.json()

    @keyword("Delete Booking")
    def delete_booking(self, booking_id, com_token=True, status_esperado=201):
        headers = self._auth_header() if com_token else {}
        resposta = self._chamar("DELETE", f"/booking/{booking_id}", headers=headers)
        self._conferir_status(resposta, status_esperado)
        if resposta.status_code == 201 and int(booking_id) in self._criadas:
            self._criadas.remove(int(booking_id))

    @keyword("Delete All Bookings Created By Suite")
    def delete_all_bookings_created_by_suite(self):
        """Limpeza do ``Suite Teardown``: nunca falha, só avisa o que sobrou."""
        if not self._criadas:
            return
        if not self._token:
            logger.warn(f"Sem token para limpar as reservas {self._criadas}")
            return
        for booking_id in list(self._criadas):
            resposta = self._chamar("DELETE", f"/booking/{booking_id}", headers=self._auth_header())
            if resposta.status_code == 201:
                self._criadas.remove(booking_id)
            else:
                logger.warn(f"Reserva {booking_id} não apagada ({resposta.status_code})")

    @staticmethod
    def _conferir_status(resposta, esperado):
        if int(esperado) != resposta.status_code:
            raise AssertionError(
                f"Status {resposta.status_code}, esperado {esperado}: {resposta.text[:200]}"
            )
