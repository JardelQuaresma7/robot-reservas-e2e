"""Massa de teste gerada na hora com Faker: cada execução usa clientes e documentos novos."""

import random
import string
from datetime import date, timedelta

from faker import Faker
from robot.api.deco import keyword, library

_fake = Faker("pt_BR")


def _cpf_digits():
    return "".join(ch for ch in _fake.cpf() if ch.isdigit())


@library(scope="GLOBAL")
class DataFactory:
    """Gera documentos válidos, clientes e datas relativas a hoje."""

    @keyword("New Cpf")
    def new_cpf(self):
        return _cpf_digits()

    @keyword("New Invalid Cpf")
    def new_invalid_cpf(self):
        cpf = _cpf_digits()
        ultimo = (int(cpf[-1]) + 1) % 10
        return cpf[:-1] + str(ultimo)

    @keyword("New Passport")
    def new_passport(self):
        return "".join(random.choices(string.ascii_uppercase, k=2)) + f"{random.randint(0, 999999):06d}"

    @keyword("New Client Data")
    def new_client_data(self, doc_type="CPF", nationality="Brasileira"):
        nome, sobrenome = _fake.first_name(), _fake.last_name()
        return {
            "doc_type": doc_type,
            "doc": self.new_passport() if doc_type == "PASSAPORTE" else _cpf_digits(),
            "nationality": nationality, "first_name": nome, "last_name": sobrenome,
            "email": f"{nome}.{sobrenome}.{random.randint(1000, 9999)}@example.com".lower(),
            "phone": f"119{random.randint(10000000, 99999999)}",
        }

    @keyword("New Person Name")
    def new_person_name(self):
        return _fake.name()

    @keyword("Date From Today")
    def date_from_today(self, dias):
        """Data ISO (AAAA-MM-DD) a ``dias`` de hoje."""
        return (date.today() + timedelta(days=int(dias))).isoformat()
