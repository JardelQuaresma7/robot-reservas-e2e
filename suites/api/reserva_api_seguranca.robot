*** Settings ***
Documentation     Cenários negativos: alteração e cancelamento sem token, login inválido e id
...               inexistente. A API não pode aceitar escrita de quem não se autenticou.

Resource          ../../resources/common.resource
Library           booking_api.py    ${API_URL}

Suite Setup       Authenticate As Admin    ${API_USER}    ${API_PASSWORD}
Suite Teardown    Delete All Bookings Created By Suite

Test Tags         api    seguranca    regressao


*** Test Cases ***
Alterar reserva sem token é recusado
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    ${changed}    New Booking Payload
    Update Booking    ${created}[bookingid]    ${changed}    com_token=${FALSE}    status_esperado=403
    ${stored}    Get Booking    ${created}[bookingid]
    Dictionaries Should Be Equal    ${stored}    ${payload}

Cancelar reserva sem token é recusado
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    Delete Booking    ${created}[bookingid]    com_token=${FALSE}    status_esperado=403
    Get Booking    ${created}[bookingid]    status_esperado=200

Login com senha errada não devolve token
    Run Keyword And Expect Error    Login recusado*
    ...    Authenticate As Admin    ${API_USER}    senha-errada

Consultar id inexistente devolve 404
    Get Booking    999999999    status_esperado=404
