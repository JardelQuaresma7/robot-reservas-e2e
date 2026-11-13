*** Settings ***
Documentation    Passo 4: proteções (pelo menos uma) e acessórios.

Resource         ../../../common.resource


*** Variables ***
${STEP_4}              id=step-4
${CHECK_PROTECTION}    css=input[name='protection'][value='{code}']
${CHECK_ACCESSORY}     css=input[name='accessory'][value='{code}']
${BTN_NEXT_4}          id=btn-avancar-4


*** Keywords ***
Select Protection
    [Documentation]    Marca uma proteção pelo código (BASICA, TOTAL).
    [Arguments]    ${code}
    Wait Until Keyword Succeeds    5x    300ms    Element Should Be Unlocked    ${STEP_4}
    ${locator}    Format String    ${CHECK_PROTECTION}    code=${code}
    Select Checkbox    ${locator}

Select Accessory
    [Documentation]    Marca um acessório pelo código (CADEIRINHA, GPS).
    [Arguments]    ${code}
    ${locator}    Format String    ${CHECK_ACCESSORY}    code=${code}
    Select Checkbox    ${locator}

Choose Protections And Accessories
    [Documentation]    Marca proteções e acessórios e avança.
    [Arguments]    ${protections}    ${accessories}=${EMPTY}
    FOR    ${code}    IN    @{protections}
        Select Protection    ${code}
    END
    IF    $accessories
        FOR    ${code}    IN    @{accessories}
            Select Accessory    ${code}
        END
    END
    Click Button    ${BTN_NEXT_4}

Advance From Protections Should Be Blocked
    [Documentation]    Sem proteção marcada, o botão de avançar fica desabilitado.
    Element Should Be Disabled    ${BTN_NEXT_4}
