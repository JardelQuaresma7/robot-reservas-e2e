*** Settings ***
Documentation     Modal "Grupo selecionado indisponível" na criação (forçar ou solicitar) e edição de
...               reserva confirmada para grupo esgotado sem modal. Na loja CGH o Grupo F está esgotado.

Resource          ../../resources/flows/reserve_pj_flow.resource
Resource          ../../resources/page_objects/reserve/update/update_page.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    grupo-indisponivel

Name              Reserva PF e PJ - Grupo indisponível


*** Test Cases ***
Deve forçar a reserva com grupo indisponível na criação
    [Tags]    pf
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=10    group=${GROUP_SOLD_OUT}
    ...    store=${STORE_SOLD_OUT}
    Group Should Be Marked As Sold Out    ${GROUP_SOLD_OUT}
    Submit From Conductor Step    ${CLIENT}[phone]
    Unavailable Group Modal Should Open
    Force Reservation
    Reservation Should Be Created
    Detail Field Should Be    status    Confirmada
    Detail Field Should Be    grupo    Grupo F - SUV

Deve atualizar a reserva confirmada com grupo esgotado sem exibir o modal
    [Tags]    pf
    ${reservation}    Create Reservation Via Api    ${CLIENT}    pickup_in_days=20    store=${STORE_SOLD_OUT}
    Go To    ${APP_URL}/reservas/${reservation}[number]/editar
    Update Page Should Be Open    ${reservation}[number]
    Change Group On Update    ${GROUP_SOLD_OUT}
    Save Update
    # Sem modal no caminho: o salvar leva direto ao detalhe.
    Wait Until Location Is    ${APP_URL}/reservas/${reservation}[number]
    Detail Field Should Be    grupo    Grupo F - SUV
    Detail Field Should Be    status    Confirmada

Deve gravar a reserva como solicitada ao escolher Solicitar na criacao PF
    [Tags]    pf
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=30    group=${GROUP_SOLD_OUT}
    ...    store=${STORE_SOLD_OUT}
    Submit From Conductor Step    ${CLIENT}[phone]
    Unavailable Group Modal Should Open
    Request Reservation
    Reservation Should Be Created
    Detail Field Should Be    status    Solicitada

Deve forcar a reserva PJ com grupo indisponivel na criacao
    [Tags]    pj
    Fill PJ Group Sold Out Until Contact    pickup_in_days=12
    Submit From Conductor Step    11988887777
    Unavailable Group Modal Should Open
    Force Reservation
    Reservation Should Be Created
    Detail Field Should Be    status    Confirmada

Deve atualizar a reserva PJ confirmada com grupo esgotado sem exibir o modal
    [Tags]    pj
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    ${number}    ${_}    Create PJ Reservation    ACME    ${driver_cpf}    ${driver_name}
    ...    pickup_in_days=22    store=${STORE_SOLD_OUT}
    Edit From Details
    Change Group On Update    ${GROUP_SOLD_OUT}
    Save Update
    # Sem modal no caminho: o salvar leva direto ao detalhe.
    Wait Until Location Is    ${APP_URL}/reservas/${number}
    Detail Field Should Be    grupo    Grupo F - SUV

Deve gravar a reserva PJ como solicitada ao escolher Solicitar
    [Tags]    pj
    Fill PJ Group Sold Out Until Contact    pickup_in_days=32
    Submit From Conductor Step    11988887777
    Unavailable Group Modal Should Open
    Request Reservation
    Reservation Should Be Created
    Detail Field Should Be    status    Solicitada


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE

Submit From Conductor Step
    [Documentation]    Do passo 5 até clicar em Reservar.
    [Arguments]    ${phone}
    Advance From Conductor Step
    Fill Phone    ${phone}
    Submit Reservation

Fill PJ Group Sold Out Until Contact
    [Documentation]    Reserva PJ ACME na loja CGH com o Grupo F esgotado.
    [Arguments]    ${pickup_in_days}
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Fill PJ Reservation Until Contact    ACME    ${driver_cpf}    ${driver_name}    ${pickup_in_days}
    ...    group=${GROUP_SOLD_OUT}    store=${STORE_SOLD_OUT}
