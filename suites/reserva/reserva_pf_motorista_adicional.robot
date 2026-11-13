*** Settings ***
Documentation     A tarifa "Diária família" isenta 1 motorista adicional; o excedente é cobrado
...               (R$ 20,00 por dia).

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    motorista-adicional

Name              Reserva PF - Motorista adicional


*** Test Cases ***
Deve isentar no resumo o motorista adicional que a tarifa oferece
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=12    days=3    rate=FAMILIA
    ${driver}    New Cpf
    Add Additional Driver    ${driver}
    Additional Driver Count Should Be    1
    Summary Field Should Contain    motoristas    1 isento(s), 0 cobrado(s)
    Summary Field Should Contain    motoristas-valor    R$ 0,00

Deve cobrar apenas o motorista excedente na reserva criada
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=20    days=3    rate=FAMILIA
    ${first}    New Cpf
    ${second}    New Cpf
    Add Additional Driver    ${first}
    Add Additional Driver    ${second}
    Summary Field Should Contain    motoristas    1 isento(s), 1 cobrado(s)
    Summary Field Should Contain    motoristas-valor    R$ 60,00
    Advance From Conductor Step
    Fill Phone    ${CLIENT}[phone]
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    motoristas    2 (1 isento(s), 1 cobrado(s))
    Detail Field Should Be    motoristas-valor    R$ 60,00


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE
