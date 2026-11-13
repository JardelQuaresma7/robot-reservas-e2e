*** Settings ***
Documentation    Passo 5: condutor (próprio cliente ou outra pessoa) e motoristas adicionais.

Resource         ../../../common.resource


*** Variables ***
${STEP_5}                     id=step-5
${CHECK_DRIVER_IS_CLIENT}     id=driver-is-client
${SELECT_DRIVER_DOC_TYPE}     id=driver-doc-type
${INPUT_DRIVER_DOC}           id=driver-doc
${INPUT_DRIVER_NAME}          id=driver-name
${INPUT_ADDITIONAL_DRIVER}    id=additional-driver-doc
${BTN_ADD_DRIVER}             id=btn-add-driver
${ADDITIONAL_DRIVERS_LIST}    css=#additional-drivers li
${STEP_5_ERROR}               id=step-5-error
${BTN_NEXT_5}                 id=btn-avancar-5


*** Keywords ***
Wait Conductor Step
    [Documentation]    Espera o passo 5 liberar.
    Wait Until Keyword Succeeds    5x    300ms    Element Should Be Unlocked    ${STEP_5}

Fill Different Conductor
    [Documentation]    Condutor diferente do cliente (PF) ou condutor do acordo (PJ).
    [Arguments]    ${doc}    ${name}    ${doc_type}=CPF
    Wait Conductor Step
    ${is_pf}    Run Keyword And Return Status    Element Should Be Visible    ${CHECK_DRIVER_IS_CLIENT}
    IF    ${is_pf}    Unselect Checkbox    ${CHECK_DRIVER_IS_CLIENT}
    Select From List By Value    ${SELECT_DRIVER_DOC_TYPE}    ${doc_type}
    Fill Field    ${INPUT_DRIVER_DOC}    ${doc}
    Fill Field    ${INPUT_DRIVER_NAME}    ${name}

Add Additional Driver
    [Documentation]    Inclui um motorista adicional pelo CPF.
    [Arguments]    ${cpf}
    Wait Conductor Step
    Fill Field    ${INPUT_ADDITIONAL_DRIVER}    ${cpf}
    Click Button    ${BTN_ADD_DRIVER}

Additional Driver Count Should Be
    [Documentation]    Quantidade de motoristas adicionais na lista.
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    5x    300ms
    ...    Page Should Contain Element    ${ADDITIONAL_DRIVERS_LIST}    limit=${expected}

Conductor Error Should Be
    [Documentation]    Mensagem de erro do passo 5.
    [Arguments]    ${message}
    Wait Until Element Contains    ${STEP_5_ERROR}    ${message}

Advance From Conductor Step
    [Documentation]    Sai do passo 5.
    Wait Conductor Step
    Click Button    ${BTN_NEXT_5}
