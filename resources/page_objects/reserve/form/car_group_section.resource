*** Settings ***
Documentation    Passo 3: escolha do grupo de carro, com aviso de esgotado por loja.

Resource         ../../../common.resource


*** Variables ***
${STEP_3}            id=step-3
${RADIO_GROUP}       css=input[name='group'][value='{group}']
${SOLD_OUT_BADGE}    id=group-sold-out-{group}
${BTN_NEXT_3}        id=btn-avancar-3


*** Keywords ***
Choose Car Group
    [Documentation]    Marca o grupo pelo código (A, C, F, K) e avança.
    [Arguments]    ${group}
    Wait Until Keyword Succeeds    5x    300ms    Element Should Be Unlocked    ${STEP_3}
    ${locator}    Format String    ${RADIO_GROUP}    group=${group}
    Click Element    ${locator}
    Click Button    ${BTN_NEXT_3}

Group Should Be Marked As Sold Out
    [Documentation]    O card do grupo mostra o aviso de esgotado na loja escolhida.
    [Arguments]    ${group}
    ${locator}    Format String    ${SOLD_OUT_BADGE}    group=${group}
    Element Should Be Visible    ${locator}
