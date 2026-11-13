*** Settings ***
Documentation     O cliente paga, outra pessoa dirige: o condutor é gravado com o próprio documento.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    condutor

Name              Reserva PF - Condutor diferente do cliente


*** Test Cases ***
Deve aceitar condutor com CPF diferente do cliente
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=14
    Fill Different Conductor    ${driver_cpf}    ${driver_name}
    Advance From Conductor Step
    Wait Contact Step
    Element Text Should Be    id=step-5-error    ${EMPTY}

Deve criar reserva PF com condutor diferente do cliente
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=16
    Fill Different Conductor    ${driver_cpf}    ${driver_name}
    Advance From Conductor Step
    Fill Phone    ${CLIENT}[phone]
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    condutor    ${driver_name} (CPF ${driver_cpf})
    Detail Field Should Be    cliente    ${CLIENT}[first_name] ${CLIENT}[last_name]


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE
