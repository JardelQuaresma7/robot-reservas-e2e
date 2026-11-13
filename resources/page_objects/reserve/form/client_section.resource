*** Settings ***
Documentation    Passo 1 da reserva PF: identificação do cliente por CPF ou passaporte.

Resource         ../../../common.resource


*** Variables ***
${SELECT_DOC_TYPE}      id=doc-type
${INPUT_CLIENT_DOC}     id=client-doc
${BTN_SEARCH_CLIENT}    id=btn-buscar-cliente
${CLIENT_FOUND}         id=client-found
${STEP_1_ERROR}         id=step-1-error
${BTN_NEXT_1}           id=btn-avancar-1


*** Keywords ***
Identify Client
    [Documentation]    Busca o cliente pelo documento e espera o nome aparecer.
    [Arguments]    ${doc}    ${doc_type}=CPF
    Select From List By Value    ${SELECT_DOC_TYPE}    ${doc_type}
    Fill Field    ${INPUT_CLIENT_DOC}    ${doc}
    Click Button    ${BTN_SEARCH_CLIENT}
    Wait Until Element Contains    ${CLIENT_FOUND}    Cliente:

Search Client Expecting Error
    [Documentation]    Busca um documento que a tela deve recusar e devolve a mensagem.
    [Arguments]    ${doc}    ${doc_type}=CPF
    Select From List By Value    ${SELECT_DOC_TYPE}    ${doc_type}
    Fill Field    ${INPUT_CLIENT_DOC}    ${doc}
    Click Button    ${BTN_SEARCH_CLIENT}
    Wait Until Element Is Visible    ${STEP_1_ERROR}
    Wait Until Keyword Succeeds    5x    300ms    Element Text Should Not Be    ${STEP_1_ERROR}    ${EMPTY}
    ${message}    Get Text    ${STEP_1_ERROR}
    RETURN    ${message}

Change Client Document
    [Documentation]    Digita outro documento por cima do atual (dispara o reset dos passos).
    [Arguments]    ${doc}
    Clear Element Text    ${INPUT_CLIENT_DOC}
    Input Text    ${INPUT_CLIENT_DOC}    ${doc}

Advance From Client Step
    [Documentation]    Sai do passo 1.
    Click Button    ${BTN_NEXT_1}
