*** Settings ***
Documentation     Regras que impedem a reserva PF de seguir com dado errado ou em conflito.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    validacao

Name              Reserva PF - Validações


*** Test Cases ***
Deve bloquear o avanço com CPF inválido
    Navigate To New PF Reservation
    ${invalid}    New Invalid Cpf
    ${message}    Search Client Expecting Error    ${invalid}
    Should Be Equal    ${message}    CPF inválido.
    Advance From Client Step
    Element Should Be Locked    id=step-2

Deve resetar os steps ao trocar o CPF
    Fill PF Reservation Until Contact    ${CLIENT}
    ${other}    New Cpf
    Change Client Document    ${other}
    FOR    ${step}    IN RANGE    2    7
        Element Should Be Locked    id=step-${step}
    END
    Element Text Should Be    id=client-found    ${EMPTY}

Deve validar a disponibilidade do condutor adicional
    Fill PF Reservation Until Contact    ${CLIENT}
    ${invalid}    New Invalid Cpf
    Add Additional Driver    ${invalid}
    Conductor Error Should Be    CPF do motorista adicional inválido.
    Add Additional Driver    ${CLIENT}[doc]
    Conductor Error Should Be    Motorista já informado nesta reserva.
    Additional Driver Count Should Be    0

Deve liberar o avanço só com proteção marcada
    Navigate To New PF Reservation
    Identify Client    ${CLIENT}[doc]
    Advance From Client Step
    Fill Stores And Period    10    3
    Choose Car Group    A
    Advance From Protections Should Be Blocked
    Select Protection    TOTAL
    Element Should Be Enabled    id=btn-avancar-4

Deve exigir telefone no contato
    Fill PF Reservation Until Contact    ${CLIENT}
    Advance From Conductor Step
    Fill Phone    ${EMPTY}
    Submit Reservation
    Contact Error Should Be    Informe o telefone de contato.

Deve exibir o modal de reserva ativa no período
    ${existing}    Create Reservation Via Api    ${CLIENT}    pickup_in_days=50    days=5
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=52    days=2
    Advance From Conductor Step
    Fill Phone    ${CLIENT}[phone]
    Submit Reservation
    Active Reservation Modal Should Open    ${existing}[number]
    Continue Despite Active Reservation
    Reservation Should Be Created


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE
