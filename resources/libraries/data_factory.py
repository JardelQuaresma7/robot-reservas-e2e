"""Massa de teste gerada na hora com Faker: cada execução usa dados novos e independentes."""

from datetime import date, timedelta

from faker import Faker
from robot.api.deco import keyword, library

_fake = Faker("pt_BR")

# Cartão de teste público (Visa), aceito por qualquer ambiente de demonstração.
CARTAO_DE_TESTE = "4111111111111111"


@library(scope="GLOBAL")
class DataFactory:
    """Gera passageiro e reserva com dados válidos e únicos."""

    @keyword("New Passenger")
    def new_passenger(self):
        nome = _fake.first_name()
        sobrenome = _fake.last_name()
        return {
            "name": f"{nome} {sobrenome}",
            "address": _fake.street_address(),
            "city": _fake.city(),
            "state": _fake.estado_sigla(),
            "zip_code": _fake.postcode().replace("-", ""),
            "card_type": "visa",
            "card_number": CARTAO_DE_TESTE,
            "card_month": "12",
            "card_year": str(date.today().year + 3),
            "name_on_card": f"{nome} {sobrenome}".upper(),
        }

    @keyword("New Booking Payload")
    def new_booking_payload(self, noites=3, dias_ate_checkin=30, deposito=True):
        checkin = date.today() + timedelta(days=int(dias_ate_checkin))
        checkout = checkin + timedelta(days=int(noites))
        return {
            "firstname": _fake.first_name(),
            "lastname": _fake.last_name(),
            "totalprice": _fake.random_int(min=150, max=2500),
            "depositpaid": bool(deposito),
            "bookingdates": {"checkin": checkin.isoformat(), "checkout": checkout.isoformat()},
            "additionalneeds": _fake.random_element(["Breakfast", "Late checkout", "Parking"]),
        }
