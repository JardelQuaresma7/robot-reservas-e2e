*** Settings ***
Documentation    Ações de interface genéricas, reaproveitadas pelos page objects.

Resource         ../common.resource


*** Keywords ***
Set Date Field
    [Documentation]    Preenche input type=date pelo valor ISO, sem depender do idioma do navegador.
    [Arguments]    ${element_id}    ${iso_date}
    Execute Javascript
    ...    const el = document.getElementById('${element_id}'); el.value = '${iso_date}';
    ...    el.dispatchEvent(new Event('input', {bubbles: true}));
    ...    el.dispatchEvent(new Event('change', {bubbles: true}));

Fill Field
    [Documentation]    Limpa e digita, disparando o change que recalcula o resumo.
    [Arguments]    ${locator}    ${text}
    Clear Element Text    ${locator}
    Input Text    ${locator}    ${text}
    Press Keys    ${locator}    TAB

Element Should Be Locked
    [Documentation]    Passo do formulário ainda bloqueado (classe ``locked``).
    [Arguments]    ${locator}
    ${classes}    Get Element Attribute    ${locator}    class
    Should Contain    ${classes}    locked

Element Should Be Unlocked
    [Documentation]    Passo do formulário liberado para preenchimento.
    [Arguments]    ${locator}
    ${classes}    Get Element Attribute    ${locator}    class
    Should Not Contain    ${classes}    locked

Money To Number
    [Documentation]    "R$ 1.234,50" -> 1234.5, para comparar valores do resumo.
    [Arguments]    ${text}
    ${clean}    Replace String Using Regexp    ${text}    [^0-9,]    ${EMPTY}
    ${clean}    Replace String    ${clean}    ,    .
    ${value}    Convert To Number    ${clean}
    RETURN    ${value}

Toast Should Show
    [Documentation]    Mensagem de confirmação no canto da tela.
    [Arguments]    ${text}
    Wait Until Element Is Visible    id=toast
    Element Should Contain    id=toast    ${text}
