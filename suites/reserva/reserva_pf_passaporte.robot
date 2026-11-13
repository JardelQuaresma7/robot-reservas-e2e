*** Settings ***
Documentation     Cliente estrangeiro identificado pelo passaporte, do resumo até o detalhe.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    passaporte

Name              Reserva PF - Cliente com passaporte


*** Test Cases ***
Deve identificar o cliente pelo passaporte e mostrar no resumo
    Navigate To New PF Reservation
    Identify Client    ${CLIENT}[doc]    PASSAPORTE
    Summary Field Should Contain    cliente    ${CLIENT}[first_name] ${CLIENT}[last_name]
    Summary Field Should Contain    documento    Passaporte ${CLIENT}[doc]

Deve criar reserva PF para cliente cadastrado com passaporte
    Create PF Reservation    ${CLIENT}    pickup_in_days=15
    Detail Field Should Be    documento    PASSAPORTE ${CLIENT}[doc]
    Detail Field Should Be    condutor    ${CLIENT}[first_name] ${CLIENT}[last_name] (PASSAPORTE ${CLIENT}[doc])


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente estrangeiro com passaporte.
    Start Browser Session
    ${client}    Create Client For Suite    PASSAPORTE    Estrangeira
    VAR    ${CLIENT}    ${client}    scope=SUITE
