*** Settings ***
Documentation     Caminho feliz da reserva PF: cliente, lojas, grupo, proteção, condutor e contato.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    criacao

Name              Reserva PF - Criação


*** Test Cases ***
Deve concluir a reserva PF pelo caminho feliz
    [Tags]    smoke
    ${client}    Create Client For Suite
    ${number}    ${summary}    Create PF Reservation    ${client}    pickup_in_days=12    days=3
    Should Match Regexp    ${number}    ^R\\d{6}$
    Detail Field Should Be    status    Confirmada
    Detail Field Should Be    tipo    PF
    Verify Details Match Summary    ${summary}
    Detail Field Should Contain    retirada    ${STORE_NAME}
