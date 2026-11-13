*** Settings ***
Documentation    Detalhe da reserva: confere o que foi gravado.

Resource         ../../../common.resource


*** Variables ***
${DETAIL_NUMBER}    id=detail-number
${DETAIL_FIELD}     id=detail-{field}
${ALERT_CREATED}    id=alert-criada
${BTN_EDIT}         id=btn-editar


*** Keywords ***
Reservation Should Be Created
    [Documentation]    Espera o detalhe com o aviso de criação e devolve o número.
    Wait Until Element Is Visible    ${ALERT_CREATED}
    ${number}    Get Text    ${DETAIL_NUMBER}
    Register Reservation For Cleanup    ${number}
    RETURN    ${number}

Open Reservation Details
    [Documentation]    Abre o detalhe direto pela URL.
    [Arguments]    ${number}
    Go To    ${APP_URL}/reservas/${number}
    Wait Until Element Contains    ${DETAIL_NUMBER}    ${number}

Get Detail Field
    [Documentation]    Texto de um campo do detalhe (status, cliente, tarifa, grupo, total...).
    [Arguments]    ${field}
    ${locator}    Format String    ${DETAIL_FIELD}    field=${field}
    ${text}    Get Text    ${locator}
    RETURN    ${text}

Detail Field Should Be
    [Documentation]    Compara um campo do detalhe com o valor esperado.
    [Arguments]    ${field}    ${expected}
    ${text}    Get Detail Field    ${field}
    Should Be Equal    ${text}    ${expected}

Detail Field Should Contain
    [Documentation]    O campo do detalhe contém o trecho esperado.
    [Arguments]    ${field}    ${expected}
    ${text}    Get Detail Field    ${field}
    Should Contain    ${text}    ${expected}

Get Detail Total
    [Documentation]    Total gravado como número.
    ${text}    Get Detail Field    total
    ${total}    Money To Number    ${text}
    RETURN    ${total}

Edit From Details
    [Documentation]    Abre a edição pelo botão do detalhe.
    Click Element    ${BTN_EDIT}
