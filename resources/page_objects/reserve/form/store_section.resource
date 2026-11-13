*** Settings ***
Documentation    Passo 2: lojas, período e tarifa (a mensal entra sozinha a partir de 28 diárias).

Resource         ../../../common.resource


*** Variables ***
${STEP_2}                 id=step-2
${SELECT_PICKUP_STORE}    id=pickup-store
${SELECT_RETURN_STORE}    id=return-store
${SELECT_RATE}            id=rate
${MONTHLY_INFO}           id=monthly-info
${STEP_2_ERROR}           id=step-2-error
${BTN_NEXT_2}             id=btn-avancar-2


*** Keywords ***
Fill Stores And Period
    [Documentation]    Lojas e datas relativas a hoje; tarifa opcional (só PF).
    [Arguments]    ${pickup_in_days}    ${days}    ${pickup_store}=${STORE}    ${return_store}=${STORE}
    ...    ${rate}=${EMPTY}
    Wait Until Keyword Succeeds    5x    300ms    Element Should Be Unlocked    ${STEP_2}
    Select From List By Value    ${SELECT_PICKUP_STORE}    ${pickup_store}
    Select From List By Value    ${SELECT_RETURN_STORE}    ${return_store}
    # A tarifa vem antes das datas: com 28 diárias ou mais o seletor trava em Mensal.
    IF    '${rate}' != '${EMPTY}'
        Select From List By Value    ${SELECT_RATE}    ${rate}
    END
    ${pickup}    Date From Today    ${pickup_in_days}
    ${return_in_days}    Evaluate    ${pickup_in_days} + ${days}
    ${return}    Date From Today    ${return_in_days}
    Set Date Field    pickup-date    ${pickup}
    Set Date Field    return-date    ${return}
    Click Button    ${BTN_NEXT_2}

Monthly Rate Should Be Applied
    [Documentation]    A partir de 28 diárias a tarifa vira Mensal e o seletor trava.
    Wait Until Element Contains    ${MONTHLY_INFO}    Tarifa mensal aplicada
    ${rate}    Get Selected List Value    ${SELECT_RATE}
    Should Be Equal    ${rate}    MENSAL
    Element Should Be Disabled    ${SELECT_RATE}
