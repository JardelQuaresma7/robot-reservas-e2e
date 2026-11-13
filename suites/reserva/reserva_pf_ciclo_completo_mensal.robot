*** Settings ***
Documentation     Ciclo completo com 30 diárias: a tarifa vira Mensal sozinha e o desconto aparece
...               no total; depois edita e cancela.

Resource          ../../resources/flows/reserve_pf_flow.resource
Resource          ../../resources/page_objects/reserve/update/update_page.resource
Resource          ../../resources/page_objects/reserve/search/search_page.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    ciclo-completo    mensal

Name              Reserva PF mensal - Criação, edição e cancelamento


*** Test Cases ***
Deve percorrer o ciclo completo da reserva PF mensal
    ${client}    Create Client For Suite
    Fill PF Reservation Until Contact    ${client}    pickup_in_days=40    days=30
    Monthly Rate Should Be Applied
    Summary Field Should Contain    periodo    30 diárias
    Summary Field Should Contain    diarias    2700,00
    Advance From Conductor Step
    Fill Phone    ${client}[phone]
    ${summary}    Capture Summary
    Submit Reservation
    ${number}    Reservation Should Be Created
    Verify Details Match Summary    ${summary}
    Detail Field Should Be    tarifa    Mensal

    Edit From Details
    Add Accessory On Update    CADEIRINHA
    Save Update And Return To Details    ${number}
    Detail Field Should Contain    acessorios    Cadeirinha infantil
    Detail Field Should Be    tarifa    Mensal

    Navigate To Reservation Search
    Search Reservations    number=${number}
    Cancel Reservation From Search    ${number}    Mudança de data
    Row Status Should Be    ${number}    Cancelada
