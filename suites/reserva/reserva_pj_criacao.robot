*** Settings ***
Documentation     Caminho feliz da reserva PJ no acordo ACME: tarifa do acordo com 15% de desconto.

Resource          ../../resources/flows/reserve_pj_flow.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pj    criacao

Name              Reserva PJ - Criação


*** Test Cases ***
Deve concluir a reserva PJ pelo caminho feliz
    [Tags]    smoke
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    ${_}    ${summary}    Create PJ Reservation    ACME    ${driver_cpf}    ${driver_name}
    ...    pickup_in_days=12    days=2
    Detail Field Should Be    status    Confirmada
    Detail Field Should Be    tipo    PJ
    Detail Field Should Be    cliente    ACME Logística
    Detail Field Should Be    tarifa    Tarifa do acordo ACME Logística
    Detail Field Should Be    condutor    ${driver_name} (CPF ${driver_cpf})
    Should Be Equal    ${summary}[total]    R$ 274,00
    Detail Field Should Be    total    ${summary}[total]
