*** Settings ***
Documentation    Home: escolha de origem e destino do voo.

Resource         ../common.resource


*** Variables ***
${HOME_TITLE}            xpath=//h1[normalize-space()='Welcome to the Simple Travel Agency!']
${SELECT_ORIGIN}         name=fromPort
${SELECT_DESTINATION}    name=toPort
${BTN_FIND_FLIGHTS}      css=input[type='submit'][value='Find Flights']


*** Keywords ***
Home Page Should Be Open
    [Documentation]    Espera a home carregar.
    Wait Until Element Is Visible    ${HOME_TITLE}

Search Flights
    [Documentation]    Escolhe origem e destino e pesquisa os voos.
    [Arguments]    ${origin}    ${destination}
    Home Page Should Be Open
    Select From List By Label    ${SELECT_ORIGIN}    ${origin}
    Select From List By Label    ${SELECT_DESTINATION}    ${destination}
    Click Button    ${BTN_FIND_FLIGHTS}

Origin Options Should Be
    [Documentation]    Compara a lista de origens com a esperada, na mesma ordem.
    [Arguments]    @{expected}
    ${labels}    Get List Items    ${SELECT_ORIGIN}
    Lists Should Be Equal    ${labels}    ${expected}
