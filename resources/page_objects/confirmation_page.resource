*** Settings ***
Documentation    Confirmação da compra: id, status, valor e cartão mascarado.

Resource         ../common.resource


*** Variables ***
${CONFIRMATION_HEADER}    xpath=//h1[normalize-space()='Thank you for your purchase today!']
${ROW_VALUE}              xpath=//table//tr[td[normalize-space()='{label}']]/td[2]


*** Keywords ***
Confirmation Page Should Be Open
    [Documentation]    Garante que a compra terminou na tela de confirmação.
    Wait Until Element Is Visible    ${CONFIRMATION_HEADER}
    Title Should Be    BlazeDemo Confirmation

Get Confirmation Field
    [Documentation]    Lê um campo da tabela de confirmação (Id, Status, Amount...).
    [Arguments]    ${label}
    ${locator}    Format String    ${ROW_VALUE}    label=${label}
    ${value}    Get Text    ${locator}
    RETURN    ${value.strip()}

Card Number Should Be Masked
    [Documentation]    O cartão aparece mascarado, só com os 4 últimos dígitos.
    [Arguments]    ${full_number}
    ${shown}    Get Confirmation Field    Card Number
    ${last4}    Get Substring    ${full_number}    -4
    Should Match Regexp    ${shown}    ^x+${last4}$
    Should Not Contain    ${shown}    ${full_number}
