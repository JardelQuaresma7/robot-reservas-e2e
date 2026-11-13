*** Settings ***
Documentation    Passo 6: contato, e-mail secundário (toggle) e envio da reserva.

Resource         ../../../common.resource


*** Variables ***
${STEP_6}              id=step-6
${INPUT_PHONE}         id=contact-phone
${INPUT_EMAIL}         id=contact-email
${TOGGLE_SECONDARY}    id=secondary-toggle
${INPUT_SECONDARY}     id=secondary-email
${STEP_6_ERROR}        id=step-6-error
${BTN_RESERVE}         id=btn-reservar


*** Keywords ***
Wait Contact Step
    [Documentation]    Espera o passo 6 liberar.
    Wait Until Keyword Succeeds    5x    300ms    Element Should Be Unlocked    ${STEP_6}

Fill Phone
    [Documentation]    Telefone de contato (vazio limpa o campo).
    [Arguments]    ${phone}
    Wait Contact Step
    Clear Element Text    ${INPUT_PHONE}
    IF    '${phone}' != '${EMPTY}'    Input Text    ${INPUT_PHONE}    ${phone}

Turn Secondary Email On
    [Documentation]    Liga o toggle de cópia para outro e-mail.
    Wait Contact Step
    Select Checkbox    ${TOGGLE_SECONDARY}

Turn Secondary Email Off
    [Documentation]    Desliga o toggle de cópia para outro e-mail.
    Unselect Checkbox    ${TOGGLE_SECONDARY}

Fill Secondary Email
    [Documentation]    Digita o e-mail secundário (toggle precisa estar ligado).
    [Arguments]    ${email}
    Input Text    ${INPUT_SECONDARY}    ${email}

Secondary Email Should Be Enabled
    [Documentation]    Campo liberado para digitar.
    Element Should Be Enabled    ${INPUT_SECONDARY}

Secondary Email Should Be Reset
    [Documentation]    Campo vazio e desabilitado, toggle desligado.
    Element Should Be Disabled    ${INPUT_SECONDARY}
    Textfield Value Should Be    ${INPUT_SECONDARY}    ${EMPTY}
    Checkbox Should Not Be Selected    ${TOGGLE_SECONDARY}

Submit Reservation
    [Documentation]    Clica em Reservar.
    Wait Contact Step
    Click Button    ${BTN_RESERVE}

Contact Error Should Be
    [Documentation]    Mensagem de erro do passo 6.
    [Arguments]    ${message}
    Wait Until Element Contains    ${STEP_6_ERROR}    ${message}
