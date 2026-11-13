*** Settings ***
Documentation    Fluxos de negócio montados a partir dos page objects. A suíte descreve o
...              "o quê"; o fluxo esconde o "como".

Resource         ../common.resource
Resource         ../page_objects/home_page.resource
Resource         ../page_objects/flights_page.resource
Resource         ../page_objects/purchase_page.resource
Resource         ../page_objects/confirmation_page.resource


*** Keywords ***
Reserve Flight
    [Documentation]    Fluxo completo: pesquisa, escolha, passageiro, pagamento e confirmação.
    [Arguments]    ${origin}    ${destination}    ${passenger}    ${flight}=${EMPTY}
    Search Flights    ${origin}    ${destination}
    Flights Page Should Show Route    ${origin}    ${destination}
    ${chosen}    Choose Flight    ${flight}
    Purchase Page Should Be Open
    Fill Passenger Data    ${passenger}
    Fill Payment Data    ${passenger}
    Submit Purchase
    Confirmation Page Should Be Open
    RETURN    ${chosen}
