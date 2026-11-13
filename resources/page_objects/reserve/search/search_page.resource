*** Settings ***
Documentation    Consultar Reserva: filtros principais e ações da linha
...              (visualizar, editar, reenviar e-mail, PDF e cancelar).

Resource         ../../../common.resource


*** Variables ***
${FILTER_NUMBER}         id=filter-number
${FILTER_CLIENT_DOC}     id=filter-client-doc
${FILTER_DRIVER_DOC}     id=filter-driver-doc
${FILTER_AGREEMENT}      id=filter-agreement
${FILTER_STATUS}         id=filter-status
${FILTER_CHANNEL}        id=filter-channel
${BTN_SEARCH}            id=btn-pesquisar
${BTN_CLEAR}             id=btn-limpar
${SEARCH_ERROR}          id=search-error
${RESULT_ROWS}           css=#results tbody tr
${ROW}                   id=row-{number}
${ROW_ACTION}            css=#row-{number} [data-action='{action}']
${CANCEL_REASON}         id=cancel-reason
${BTN_CONFIRM_CANCEL}    id=btn-confirmar-cancelamento


*** Keywords ***
Navigate To Reservation Search
    [Documentation]    Abre a consulta limpa.
    Open Clean Page    /reservas
    Wait Until Element Is Visible    ${BTN_SEARCH}

Search Reservations
    [Documentation]    Preenche os filtros informados (os outros ficam vazios) e pesquisa.
    [Arguments]    ${number}=${EMPTY}    ${client_doc}=${EMPTY}    ${driver_doc}=${EMPTY}
    ...    ${agreement}=${EMPTY}    ${status}=${EMPTY}    ${channel}=${EMPTY}
    IF    '${number}' != '${EMPTY}'
        Input Text    ${FILTER_NUMBER}    ${number}
    END
    IF    '${client_doc}' != '${EMPTY}'
        Input Text    ${FILTER_CLIENT_DOC}    ${client_doc}
    END
    IF    '${driver_doc}' != '${EMPTY}'
        Input Text    ${FILTER_DRIVER_DOC}    ${driver_doc}
    END
    IF    '${agreement}' != '${EMPTY}'
        Select From List By Value    ${FILTER_AGREEMENT}    ${agreement}
    END
    IF    '${status}' != '${EMPTY}'
        Select From List By Label    ${FILTER_STATUS}    ${status}
    END
    IF    '${channel}' != '${EMPTY}'
        Select From List By Label    ${FILTER_CHANNEL}    ${channel}
    END
    Click Button    ${BTN_SEARCH}

Clear Search
    [Documentation]    Limpa filtros e resultados.
    Click Button    ${BTN_CLEAR}

Results Should Contain
    [Documentation]    A reserva aparece na lista.
    [Arguments]    ${number}
    ${locator}    Format String    ${ROW}    number=${number}
    Wait Until Element Is Visible    ${locator}

Results Should Not Contain
    [Documentation]    A reserva não aparece na lista.
    [Arguments]    ${number}
    ${locator}    Format String    ${ROW}    number=${number}
    Page Should Not Contain Element    ${locator}

Result Count Should Be
    [Documentation]    Quantidade de linhas no resultado.
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    5x    300ms    Page Should Contain Element    ${RESULT_ROWS}    limit=${expected}

Search Error Should Be
    [Documentation]    Mensagem de validação da consulta.
    [Arguments]    ${message}
    Wait Until Element Contains    ${SEARCH_ERROR}    ${message}

Row Status Should Be
    [Documentation]    Status mostrado na linha da reserva.
    [Arguments]    ${number}    ${status}
    Wait Until Element Contains    css=#row-${number} .status    ${status}

Click Row Action
    [Documentation]    Ação da linha: ver, editar, email, pdf, cancelar.
    [Arguments]    ${number}    ${action}
    ${locator}    Format String    ${ROW_ACTION}    number=${number}    action=${action}
    Click Element    ${locator}

Get Row Action Link
    [Documentation]    URL de uma ação que é link (pdf, ver, editar).
    [Arguments]    ${number}    ${action}
    ${locator}    Format String    ${ROW_ACTION}    number=${number}    action=${action}
    ${href}    Get Element Attribute    ${locator}    href
    RETURN    ${href}

Cancel Reservation From Search
    [Documentation]    Cancela pela linha, escolhendo o motivo no modal.
    [Arguments]    ${number}    ${reason}=Teste automatizado
    Click Row Action    ${number}    cancelar
    Wait Until Element Is Visible    ${CANCEL_REASON}
    Select From List By Label    ${CANCEL_REASON}    ${reason}
    Click Button    ${BTN_CONFIRM_CANCEL}
