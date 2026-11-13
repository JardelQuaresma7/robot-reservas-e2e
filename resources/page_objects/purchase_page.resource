*** Settings ***
Documentation    Dados do passageiro e pagamento.

Resource         ../common.resource


*** Variables ***
${PURCHASE_HEADER}       xpath=//h2[contains(normalize-space(), 'has been reserved')]
${INPUT_NAME}            id=inputName
${INPUT_ADDRESS}         id=address
${INPUT_CITY}            id=city
${INPUT_STATE}           id=state
${INPUT_ZIP}             id=zipCode
${SELECT_CARD_TYPE}      id=cardType
${INPUT_CARD_NUMBER}     id=creditCardNumber
${INPUT_CARD_MONTH}      id=creditCardMonth
${INPUT_CARD_YEAR}       id=creditCardYear
${INPUT_NAME_ON_CARD}    id=nameOnCard
${CHECK_REMEMBER_ME}     id=rememberMe
${BTN_PURCHASE}          css=input[type='submit'][value='Purchase Flight']


*** Keywords ***
Purchase Page Should Be Open
    [Documentation]    Espera a tela de passageiro e pagamento.
    Wait Until Element Is Visible    ${PURCHASE_HEADER}

Fill Passenger Data
    [Documentation]    Preenche nome e endereço do passageiro.
    [Arguments]    ${passenger}
    Input Text    ${INPUT_NAME}    ${passenger}[name]
    Input Text    ${INPUT_ADDRESS}    ${passenger}[address]
    Input Text    ${INPUT_CITY}    ${passenger}[city]
    Input Text    ${INPUT_STATE}    ${passenger}[state]
    Input Text    ${INPUT_ZIP}    ${passenger}[zip_code]

Fill Payment Data
    [Documentation]    Preenche o cartão; marca 'lembrar-me' quando pedido.
    [Arguments]    ${passenger}    ${remember_me}=${FALSE}
    Select From List By Value    ${SELECT_CARD_TYPE}    ${passenger}[card_type]
    Input Text    ${INPUT_CARD_NUMBER}    ${passenger}[card_number]
    Input Text    ${INPUT_CARD_MONTH}    ${passenger}[card_month]
    Input Text    ${INPUT_CARD_YEAR}    ${passenger}[card_year]
    Input Text    ${INPUT_NAME_ON_CARD}    ${passenger}[name_on_card]
    IF    ${remember_me}    Select Checkbox    ${CHECK_REMEMBER_ME}

Submit Purchase
    [Documentation]    Envia a compra.
    Click Button    ${BTN_PURCHASE}
