*** Settings ***
Documentation     Ciclo completo da reserva PJ: cria, confere, troca o grupo, confere o novo total e cancela.

Resource          ../../resources/flows/reserve_pj_flow.resource
Resource          ../../resources/page_objects/reserve/update/update_page.resource
Resource          ../../resources/page_objects/reserve/search/search_page.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pj    ciclo-completo

Name              Reserva PJ - Criação, edição e cancelamento


*** Test Cases ***
Deve percorrer o ciclo completo da reserva PJ
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    ${number}    ${summary}    Create PJ Reservation    ACME    ${driver_cpf}    ${driver_name}
    ...    pickup_in_days=25    days=3
    Detail Field Should Be    total    ${summary}[total]
    ${total_before}    Get Detail Total

    Edit From Details
    Update Page Should Be Open    ${number}
    Change Group On Update    K
    Save Update And Return To Details    ${number}
    Detail Field Should Be    grupo    Grupo K - Executivo
    ${total_after}    Get Detail Total
    Should Be True    ${total_after} > ${total_before}    msg=Trocar para grupo mais caro não subiu o total.

    Navigate To Reservation Search
    Search Reservations    agreement=ACME    number=${number}
    Cancel Reservation From Search    ${number}    Desistência do cliente
    Row Status Should Be    ${number}    Cancelada
