*** Settings ***
Documentation    Regras da tela que não dependem de comprar: opções de rota, lista de voos e
...              proteção do número do cartão na confirmação.

Resource         ../../resources/flows/reservation_flow.resource

Test Setup       Open Travel Agency
Test Teardown    Close Travel Agency

Test Tags        web    validacao    regressao


*** Test Cases ***
Origens disponíveis seguem a lista oficial
    [Tags]    smoke
    Origin Options Should Be
    ...    Paris    Philadelphia    Boston    Portland    San Diego    Mexico City    São Paolo

Pesquisa lista voos para a rota escolhida
    Search Flights    Philadelphia    Berlin
    Flights Page Should Show Route    Philadelphia    Berlin
    ${count}    Flight Count Should Be Greater Than Zero
    Log    ${count} voos listados

Confirmação mostra só os 4 últimos dígitos do cartão
    ${passenger}    New Passenger
    Reserve Flight    Portland    New York    ${passenger}
    Card Number Should Be Masked    ${passenger}[card_number]
