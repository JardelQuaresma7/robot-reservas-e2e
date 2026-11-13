"""Catálogo fixo do app de demonstração: lojas, grupos, tarifas, proteções, acessórios e acordos.

Os valores são fictícios. O app existe só para ser o alvo dos testes deste repositório.
"""

STORES = {
    "CGH": {"name": "SP - Aeroporto de Congonhas", "unavailable_groups": ["F"]},
    "PAU": {"name": "SP - Avenida Paulista", "unavailable_groups": []},
    "SDU": {"name": "RJ - Aeroporto Santos Dumont", "unavailable_groups": ["K"]},
}

GROUPS = {
    "A": {"name": "Grupo A - Econômico", "daily": 120.0},
    "C": {"name": "Grupo C - Intermediário", "daily": 160.0},
    "F": {"name": "Grupo F - SUV", "daily": 260.0},
    "K": {"name": "Grupo K - Executivo", "daily": 320.0},
}

# free_drivers: motoristas adicionais que a tarifa já inclui (isentos no resumo).
RATES = {
    "LIVRE": {"name": "Diária livre", "free_drivers": 0, "discount": 0.0},
    "FAMILIA": {"name": "Diária família", "free_drivers": 1, "discount": 0.0},
    "MENSAL": {"name": "Mensal", "free_drivers": 0, "discount": 0.25},
}
MONTHLY_MIN_DAYS = 28

PROTECTIONS = {
    "BASICA": {"name": "Proteção básica", "daily": 35.0},
    "TOTAL": {"name": "Proteção total", "daily": 70.0},
}

ACCESSORIES = {
    "CADEIRINHA": {"name": "Cadeirinha infantil", "daily": 15.0},
    "GPS": {"name": "GPS", "daily": 10.0},
}

ADDITIONAL_DRIVER_DAILY = 20.0

AGREEMENTS = {
    "ACME": {
        "name": "ACME Logística", "cnpj": "11222333000181", "discount": 0.15,
        "free_drivers": 2, "replacement": False, "payment": "Faturado",
    },
    "ALFA": {
        "name": "Seguradora Alfa (carro reserva)", "cnpj": "44555666000177", "discount": 0.0,
        "free_drivers": 0, "replacement": True, "payment": "Faturado",
    },
}

CANCEL_REASONS = ["Desistência do cliente", "Mudança de data", "Teste automatizado"]

# CEPs conhecidos pelo "serviço de endereço" do app.
ZIP_CODES = {
    "01310100": {"street": "Avenida Paulista", "district": "Bela Vista", "city": "São Paulo", "state": "SP"},
    "20021130": {"street": "Rua Santa Luzia", "district": "Centro", "city": "Rio de Janeiro", "state": "RJ"},
}
