*** Settings ***
Documentation    Modais da reserva: grupo indisponível, reserva ativa no período e rascunho.

Resource         ../../../common.resource


*** Variables ***
${MODAL_GROUP}            id=modal-grupo
${BTN_FORCE}              id=btn-forcar
${BTN_REQUEST}            id=btn-solicitar
${MODAL_ACTIVE}           id=modal-reserva-ativa
${MODAL_ACTIVE_TEXT}      id=modal-reserva-ativa-texto
${BTN_CONTINUE_ANYWAY}    id=btn-continuar-mesmo-assim
${MODAL_DRAFT}            id=modal-rascunho
${BTN_CONTINUE_DRAFT}     id=btn-continuar-rascunho
${BTN_DISCARD_DRAFT}      id=btn-descartar-rascunho


*** Keywords ***
Unavailable Group Modal Should Open
    [Documentation]    Modal "Grupo selecionado indisponível".
    Wait Until Element Is Visible    ${MODAL_GROUP}
    Element Should Contain    ${MODAL_GROUP}    Grupo selecionado indisponível

Force Reservation
    [Documentation]    Escolhe "Forçar reserva" no modal de grupo.
    Click Button    ${BTN_FORCE}

Request Reservation
    [Documentation]    Escolhe "Solicitar" no modal de grupo.
    Click Button    ${BTN_REQUEST}

Active Reservation Modal Should Open
    [Documentation]    Modal de reserva ativa no período, citando a reserva existente.
    [Arguments]    ${existing_number}
    Wait Until Element Is Visible    ${MODAL_ACTIVE}
    Element Should Contain    ${MODAL_ACTIVE_TEXT}    ${existing_number}

Continue Despite Active Reservation
    [Documentation]    Confirma a nova reserva mesmo com outra ativa no período.
    Click Button    ${BTN_CONTINUE_ANYWAY}

Draft Modal Should Open
    [Documentation]    Modal "Reserva em andamento".
    Wait Until Element Is Visible    ${MODAL_DRAFT}

Draft Modal Should Not Open
    [Documentation]    Página abre sem oferecer rascunho.
    Sleep    500ms    reason=o modal abre logo depois do load; meio segundo cobre a corrida
    Element Should Not Be Visible    ${MODAL_DRAFT}

Continue Draft
    [Documentation]    Restaura o formulário do rascunho.
    Click Button    ${BTN_CONTINUE_DRAFT}

Discard Draft
    [Documentation]    Descarta o rascunho salvo.
    Click Button    ${BTN_DISCARD_DRAFT}

Draft Storage Should Be Empty
    [Documentation]    Nada salvo no localStorage para o tipo de reserva.
    [Arguments]    ${kind}=PF
    ${raw}    Execute Javascript    return window.localStorage.getItem('rascunho-${kind}')
    Should Be Equal    ${raw}    ${None}
