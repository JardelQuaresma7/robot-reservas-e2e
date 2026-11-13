*** Settings ***
Documentation    Reserva de voo de ponta a ponta: pesquisa, escolha, passageiro, pagamento e
...              confirmação, em rotas diferentes.

Resource         ../../resources/flows/reservation_flow.resource

Test Setup       Open Travel Agency
Test Teardown    Close Travel Agency

Test Tags        web    reserva    regressao


*** Test Cases ***
Reserva Paris para Londres com o primeiro voo da lista
    [Tags]    smoke
    ${passenger}    New Passenger
    Reserve Flight    Paris    London    ${passenger}
    ${status}    Get Confirmation Field    Status
    Should Be Equal    ${status}    PendingCapture
    ${id}    Get Confirmation Field    Id
    Should Match Regexp    ${id}    ^\\d+$

Reserva Boston para Roma escolhendo o voo pelo número
    ${passenger}    New Passenger
    Search Flights    Boston    Rome
    @{numbers}    Get Flight Numbers
    ${last}    Get From List    ${numbers}    -1
    ${chosen}    Choose Flight    ${last}
    Should Be Equal    ${chosen}    ${last}
    Purchase Page Should Be Open
    Fill Passenger Data    ${passenger}
    Fill Payment Data    ${passenger}    remember_me=${TRUE}
    Submit Purchase
    Confirmation Page Should Be Open

Reserva em todas as rotas de saída
    [Documentation]    Uma reserva por cidade de origem, mesmo destino: cobre a matriz de rotas.
    [Template]    Reserva Da Origem Deve Ser Confirmada
    Paris
    Philadelphia
    Boston
    Portland
    San Diego
    Mexico City
    São Paolo


*** Keywords ***
Reserva Da Origem Deve Ser Confirmada
    [Documentation]    Template: volta para a home e reserva da origem informada para Dublin.
    [Arguments]    ${origin}
    ${passenger}    New Passenger
    Go To    ${WEB_URL}
    Reserve Flight    ${origin}    Dublin    ${passenger}
