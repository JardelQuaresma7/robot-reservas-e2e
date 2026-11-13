*** Settings ***
Documentation     Ciclo de vida da reserva pela API: criar, consultar, buscar, alterar e cancelar.
...               Toda reserva criada é apagada no teardown, mesmo se o cenário falhar.

Resource          ../../resources/common.resource
Library           booking_api.py    ${API_URL}

Suite Setup       Authenticate As Admin    ${API_USER}    ${API_PASSWORD}
Suite Teardown    Delete All Bookings Created By Suite

Test Tags         api    reserva    regressao


*** Test Cases ***
Criar reserva devolve o id e os mesmos dados enviados
    [Tags]    smoke
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    Should Be True    ${created}[bookingid] > 0
    Dictionaries Should Be Equal    ${created}[booking]    ${payload}

Consultar reserva pelo id devolve o que foi gravado
    ${payload}    New Booking Payload    noites=7    deposito=${FALSE}
    ${created}    Create Booking    ${payload}
    ${stored}    Get Booking    ${created}[bookingid]
    Dictionaries Should Be Equal    ${stored}    ${payload}

Buscar por nome encontra a reserva criada
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    ${ids}    Search Bookings By Name    ${payload}[firstname]    ${payload}[lastname]
    List Should Contain Value    ${ids}    ${created}[bookingid]

Alterar reserva inteira troca datas e valor
    ${original}    New Booking Payload
    ${created}    Create Booking    ${original}
    ${changed}    New Booking Payload    noites=2    dias_ate_checkin=60
    ${updated}    Update Booking    ${created}[bookingid]    ${changed}
    Dictionaries Should Be Equal    ${updated}    ${changed}

Alterar só o pedido adicional mantém o resto
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    ${patched}    Partial Update Booking    ${created}[bookingid]    additionalneeds=Airport transfer
    Should Be Equal    ${patched}[additionalneeds]    Airport transfer
    Should Be Equal    ${patched}[bookingdates]    ${payload}[bookingdates]

Cancelar reserva remove o registro
    ${payload}    New Booking Payload
    ${created}    Create Booking    ${payload}
    Delete Booking    ${created}[bookingid]
    Get Booking    ${created}[bookingid]    status_esperado=404
