*** Settings ***
Documentation    Cadastro de cliente PF: documento, nome, contato, endereço pelo CEP e termos.

Resource         ../../common.resource


*** Variables ***
${SELECT_NATIONALITY}        id=nationality
${SELECT_CLIENT_DOC}         id=doc-type
${INPUT_DOC}                 id=doc
${INPUT_FIRST_NAME}          id=first-name
${INPUT_LAST_NAME}           id=last-name
${INPUT_CLIENT_EMAIL}        id=email
${INPUT_CLIENT_PHONE}        id=phone
${INPUT_ZIP}                 id=zip
${BTN_SEARCH_ZIP}            id=btn-buscar-cep
${INPUT_STREET}              id=street
${INPUT_CITY}                id=city
${INPUT_STATE}               id=state
${CHECK_TERMS}               id=terms
${BTN_REGISTER}              id=btn-cadastrar
${CLIENT_ERROR}              id=client-error
${CLIENT_SUCCESS}            id=client-success
${BTN_RESERVE_FOR_CLIENT}    id=btn-reservar-cliente


*** Keywords ***
Navigate To Client Create
    [Documentation]    Abre o cadastro de cliente limpo.
    Open Clean Page    /clientes/novo
    Wait Until Element Is Visible    ${INPUT_DOC}

Fill Client Form
    [Documentation]    Preenche o formulário com o dicionário do ``New Client Data``.
    [Arguments]    ${client}
    Select From List By Label    ${SELECT_NATIONALITY}    ${client}[nationality]
    IF    '${client}[nationality]' == 'Brasileira'
        Select From List By Value    ${SELECT_CLIENT_DOC}    ${client}[doc_type]
    END
    Input Text    ${INPUT_DOC}    ${client}[doc]
    Input Text    ${INPUT_FIRST_NAME}    ${client}[first_name]
    Input Text    ${INPUT_LAST_NAME}    ${client}[last_name]
    Input Text    ${INPUT_CLIENT_EMAIL}    ${client}[email]
    Input Text    ${INPUT_CLIENT_PHONE}    ${client}[phone]

Fill Address By Zip
    [Documentation]    Busca o CEP e espera o endereço preencher.
    [Arguments]    ${zip}
    Input Text    ${INPUT_ZIP}    ${zip}
    Click Button    ${BTN_SEARCH_ZIP}
    Wait Until Keyword Succeeds    5x    300ms    Textfield Should Not Be Empty    ${INPUT_STREET}

Accept Terms
    [Documentation]    Marca o aceite dos termos (libera o botão).
    Select Checkbox    ${CHECK_TERMS}

Register Client
    [Documentation]    Clica em Cadastrar.
    Click Button    ${BTN_REGISTER}

Client Should Be Registered
    [Documentation]    Mensagem de sucesso com o nome do cliente; entra na limpeza.
    [Arguments]    ${client}
    Wait Until Element Contains    ${CLIENT_SUCCESS}    ${client}[first_name] ${client}[last_name]
    Register Client For Cleanup    ${client}[doc]    ${client}[doc_type]

Client Error Should Be
    [Documentation]    Mensagem de erro do cadastro.
    [Arguments]    ${message}
    Wait Until Element Contains    ${CLIENT_ERROR}    ${message}

Register Button Should Be Disabled
    [Documentation]    Sem aceitar os termos, não dá para cadastrar.
    Element Should Be Disabled    ${BTN_REGISTER}

Textfield Should Not Be Empty
    [Documentation]    O campo tem algum valor.
    [Arguments]    ${locator}
    ${value}    Get Value    ${locator}
    Should Not Be Empty    ${value}

Reserve For Registered Client
    [Documentation]    Vai para a reserva PF com o cliente recém-cadastrado já identificado.
    Click Element    ${BTN_RESERVE_FOR_CLIENT}
