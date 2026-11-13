*** Settings ***
Documentation    Lista de voos disponíveis para a rota pesquisada.

Resource         ../common.resource


*** Variables ***
${FLIGHTS_HEADER}      xpath=//h3[starts-with(normalize-space(), 'Flights from')]
${FLIGHT_ROWS}         css=table.table tbody tr
${CHOOSE_BY_NUMBER}    xpath=//tr[td[normalize-space()='{number}']]//input[@value='Choose This Flight']


*** Keywords ***
Flights Page Should Show Route
    [Documentation]    O cabeçalho da lista mostra a rota pesquisada.
    [Arguments]    ${origin}    ${destination}
    Wait Until Element Contains    ${FLIGHTS_HEADER}    Flights from ${origin} to ${destination}

Flight Count Should Be Greater Than Zero
    [Documentation]    Falha se a rota não trouxer nenhum voo; devolve a quantidade.
    ${count}    Get Element Count    ${FLIGHT_ROWS}
    Should Be True    ${count} > 0    msg=Nenhum voo listado para a rota.
    RETURN    ${count}

Get Flight Numbers
    [Documentation]    Devolve os números dos voos na ordem em que aparecem.
    @{cells}    Get WebElements    css=table.table tbody tr td:nth-child(2)
    VAR    @{numbers}    @{EMPTY}
    FOR    ${cell}    IN    @{cells}
        Append To List    ${numbers}    ${cell.text}
    END
    RETURN    ${numbers}

Choose Flight
    [Documentation]    Escolhe pelo número do voo; sem número, pega o primeiro da lista.
    [Arguments]    ${number}=${EMPTY}
    IF    '${number}' == '${EMPTY}'
        @{numbers}    Get Flight Numbers
        VAR    ${number}    ${numbers}[0]
    END
    ${locator}    Format String    ${CHOOSE_BY_NUMBER}    number=${number}
    Click Button    ${locator}
    RETURN    ${number}
