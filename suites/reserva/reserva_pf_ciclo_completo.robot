*** Settings ***
Documentation     Ciclo completo da reserva PF em fases encadeadas. As conferências usam os dados
...               capturados na criação, sem valor fixo.

Resource          ../../resources/flows/reserve_pf_flow.resource
Resource          ../../resources/page_objects/reserve/update/update_page.resource
Resource          ../../resources/page_objects/reserve/search/search_page.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    ciclo-completo

Name              Reserva PF - Criação, edição e cancelamento


*** Test Cases ***
Deve percorrer o ciclo completo da reserva PF
    [Documentation]    Fase 1: cria e captura o resumo. Fase 2: confere no detalhe.
    ...                Fase 3: edita, adiciona acessório e confere que o total subiu.
    ...                Fase 4: confere o acessório no detalhe e cancela pela consulta.
    [Tags]    smoke
    ${client}    Create Client For Suite
    ${number}    ${summary}    Create PF Reservation    ${client}    pickup_in_days=20    days=4
    Verify Details Match Summary    ${summary}
    ${total_before}    Get Detail Total

    Edit From Details
    Update Page Should Be Open    ${number}
    Add Accessory On Update    GPS
    Save Update And Return To Details    ${number}
    Detail Field Should Contain    acessorios    GPS
    ${total_after}    Get Detail Total
    Should Be True    ${total_after} > ${total_before}    msg=O total não subiu depois do acessório.

    Navigate To Reservation Search
    Search Reservations    number=${number}
    Cancel Reservation From Search    ${number}    Teste automatizado
    Row Status Should Be    ${number}    Cancelada
    Open Reservation Details    ${number}
    Detail Field Should Be    motivo    Teste automatizado
    Page Should Not Contain Element    id=btn-editar
