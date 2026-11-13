*** Settings ***
Documentation     Consultar Reserva: filtros principais e ações da linha (detalhe, edição, e-mail,
...               PDF, cancelar). A massa nasce pela API no Suite Setup, para cada cenário testar só
...               a consulta.

Resource          ../../resources/flows/reserve_pf_flow.resource
Resource          ../../resources/page_objects/reserve/search/search_page.resource
Resource          ../../resources/page_objects/reserve/update/update_page.resource

Suite Setup       Prepare Search Suite
Suite Teardown    Close Browser Session
Test Setup        Navigate To Reservation Search

Test Tags         reserva    consulta

Name              Consulta de reserva


*** Test Cases ***
Deve encontrar a reserva pelo numero
    [Tags]    smoke
    Search Reservations    number=${RES_A}[number]
    Result Count Should Be    1
    Results Should Contain    ${RES_A}[number]

Deve listar as reservas do cliente pelo CPF
    Search Reservations    client_doc=${CLIENT}[doc]
    Results Should Contain    ${RES_A}[number]
    Results Should Contain    ${RES_B}[number]

Deve encontrar a reserva pelo documento do condutor
    Search Reservations    driver_doc=${DRIVER_CPF}
    Result Count Should Be    1
    Results Should Contain    ${RES_B}[number]

Deve filtrar por status junto com o CPF
    Search Reservations    client_doc=${CLIENT}[doc]    status=Solicitada
    Results Should Contain    ${RES_SOLICITADA}[number]
    Results Should Not Contain    ${RES_A}[number]

Deve encontrar a reserva PJ pelo acordo e numero
    Search Reservations    agreement=ACME    number=${RES_PJ}[number]
    Result Count Should Be    1
    Results Should Contain    ${RES_PJ}[number]

Deve exigir um campo principal para pesquisar por status ou canal
    Search Reservations    status=Confirmada    channel=Balcão
    Search Error Should Be    Informe número, CPF do cliente, documento do condutor ou acordo para pesquisar.
    Element Should Not Be Visible    id=results

Deve pesquisar pelo novo filtro depois de limpar
    Search Reservations    number=${RES_A}[number]
    Results Should Contain    ${RES_A}[number]
    Clear Search
    Textfield Value Should Be    id=filter-number    ${EMPTY}
    Element Should Not Be Visible    id=results
    Search Reservations    driver_doc=${DRIVER_CPF}
    Results Should Contain    ${RES_B}[number]
    Results Should Not Contain    ${RES_A}[number]

Deve abrir o detalhe pelo visualizar
    Search Reservations    number=${RES_A}[number]
    Click Row Action    ${RES_A}[number]    ver
    Open Reservation Details    ${RES_A}[number]
    Detail Field Should Be    cliente    ${CLIENT}[first_name] ${CLIENT}[last_name]

Deve abrir a edicao PF pelo lapis
    Search Reservations    number=${RES_A}[number]
    Click Row Action    ${RES_A}[number]    editar
    Update Page Should Be Open    ${RES_A}[number]

Deve reenviar o e-mail da reserva
    Search Reservations    number=${RES_A}[number]
    Click Row Action    ${RES_A}[number]    email
    Toast Should Show    reenviado para ${CLIENT}[email]
    ${reservation}    Get Reservation Via Api    ${RES_A}[number]
    Should Be True    ${reservation}[emails_sent] >= 2

Deve baixar o PDF da reserva
    Search Reservations    number=${RES_A}[number]
    ${url}    Get Row Action Link    ${RES_A}[number]    pdf
    ${size}    Pdf Should Be Downloadable    ${url}
    Should Be True    ${size} > 100

Deve cancelar a reserva pela consulta
    Search Reservations    number=${RES_CANCEL}[number]
    Cancel Reservation From Search    ${RES_CANCEL}[number]    Desistência do cliente
    Toast Should Show    cancelada
    Row Status Should Be    ${RES_CANCEL}[number]    Cancelada
    ${reservation}    Get Reservation Via Api    ${RES_CANCEL}[number]
    Should Be Equal    ${reservation}[cancel_reason]    Desistência do cliente


*** Keywords ***
Prepare Search Suite
    [Documentation]    Navegador + massa da consulta: 4 reservas PF do mesmo cliente (uma com condutor
    ...                diferente, uma solicitada, uma para cancelar) e 1 PJ.
    Start Browser Session
    ${client}    Create Client For Suite
    ${driver_cpf}    New Cpf
    VAR    &{driver}    doc_type=CPF    doc=${driver_cpf}    name=Condutor da Consulta
    ${res_a}    Create Reservation Via Api    ${client}    pickup_in_days=10
    ${res_b}    Create Reservation Via Api    ${client}    pickup_in_days=20    driver=${driver}
    ${res_solicitada}    Create Reservation Via Api    ${client}    pickup_in_days=30
    ...    store=${STORE_SOLD_OUT}    group=${GROUP_SOLD_OUT}    unavailable_action=SOLICITAR
    ${res_cancel}    Create Reservation Via Api    ${client}    pickup_in_days=40
    ${pj_driver}    New Cpf
    VAR    &{pj_driver_data}    doc_type=CPF    doc=${pj_driver}    name=Condutor PJ
    ${res_pj}    Create Reservation Via Api    ${client}    pickup_in_days=50    type=PJ    agreement=ACME
    ...    client_id=${None}    driver=${pj_driver_data}
    VAR    ${CLIENT}    ${client}    scope=SUITE
    VAR    ${DRIVER_CPF}    ${driver_cpf}    scope=SUITE
    VAR    ${RES_A}    ${res_a}    scope=SUITE
    VAR    ${RES_B}    ${res_b}    scope=SUITE
    VAR    ${RES_SOLICITADA}    ${res_solicitada}    scope=SUITE
    VAR    ${RES_CANCEL}    ${res_cancel}    scope=SUITE
    VAR    ${RES_PJ}    ${res_pj}    scope=SUITE
