*** Settings ***
Documentation    Painel de resumo da reserva: cliente, tarifa, grupo e valores.

Resource         ../../../common.resource


*** Variables ***
${SUMMARY_FIELD}    id=summary-{field}


*** Keywords ***
Get Summary Field
    [Documentation]    Texto de um campo do resumo (cliente, documento, tarifa, grupo, total...).
    [Arguments]    ${field}
    ${locator}    Format String    ${SUMMARY_FIELD}    field=${field}
    ${text}    Get Text    ${locator}
    RETURN    ${text}

Summary Field Should Contain
    [Documentation]    Espera o resumo recalcular e conferir o texto.
    [Arguments]    ${field}    ${expected}
    ${locator}    Format String    ${SUMMARY_FIELD}    field=${field}
    Wait Until Element Contains    ${locator}    ${expected}

Get Summary Total
    [Documentation]    Total do resumo como número.
    ${text}    Get Summary Field    total
    ${total}    Money To Number    ${text}
    RETURN    ${total}

Capture Summary
    [Documentation]    Fotografa o resumo num dicionário, para conferir depois no detalhe.
    VAR    &{summary}    &{EMPTY}
    FOR    ${field}    IN    cliente    documento    periodo    tarifa    grupo    motoristas    total
        ${text}    Get Summary Field    ${field}
        Set To Dictionary    ${summary}    ${field}=${text}
    END
    RETURN    ${summary}
