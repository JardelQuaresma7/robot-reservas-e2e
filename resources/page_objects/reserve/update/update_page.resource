*** Settings ***
Documentation    Edição da reserva (PF e PJ): lojas, datas, grupo, proteções e acessórios.

Resource         ../../../common.resource


*** Variables ***
${EDIT_NUMBER}          id=edit-number
${SELECT_EDIT_GROUP}    id=group
${EDIT_ACCESSORY}       css=input[name='accessory'][value='{code}']
${EDIT_NEW_TOTAL}       id=edit-total-novo
${BTN_SAVE}             id=btn-salvar


*** Keywords ***
Update Page Should Be Open
    [Documentation]    Tela de edição da reserva informada.
    [Arguments]    ${number}
    Wait Until Element Contains    ${EDIT_NUMBER}    ${number}

Change Group On Update
    [Documentation]    Troca o grupo na edição.
    [Arguments]    ${group}
    Select From List By Value    ${SELECT_EDIT_GROUP}    ${group}

Add Accessory On Update
    [Documentation]    Marca um acessório na edição e espera o novo total.
    [Arguments]    ${code}
    ${locator}    Format String    ${EDIT_ACCESSORY}    code=${code}
    Select Checkbox    ${locator}
    Wait Until Keyword Succeeds    5x    300ms    Element Text Should Not Be    ${EDIT_NEW_TOTAL}    -

Save Update
    [Documentation]    Salva a edição.
    Click Button    ${BTN_SAVE}

Save Update And Return To Details
    [Documentation]    Salva e espera voltar ao detalhe.
    [Arguments]    ${number}
    Save Update
    Wait Until Location Is    ${APP_URL}/reservas/${number}
