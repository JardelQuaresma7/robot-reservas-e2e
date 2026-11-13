*** Settings ***
Documentation     Reserva em andamento fica salva no navegador: oferece continuar ou descartar.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    rascunho

Name              Reserva PF - Rascunho


*** Test Cases ***
Deve exibir o modal de rascunho ao voltar com progresso
    Start Draft With Progress
    Reload Page
    Draft Modal Should Open

Deve restaurar o formulário ao continuar o rascunho
    Start Draft With Progress
    Reload Page
    Draft Modal Should Open
    Continue Draft
    Textfield Value Should Be    id=client-doc    ${CLIENT}[doc]
    List Selection Should Be    id=pickup-store    ${STORE}
    Radio Button Should Be Set To    group    C
    Element Should Be Unlocked    id=step-4
    Summary Field Should Contain    cliente    ${CLIENT}[first_name]

Deve limpar o armazenamento ao descartar o rascunho
    Start Draft With Progress
    Reload Page
    Draft Modal Should Open
    Discard Draft
    Draft Storage Should Be Empty    PF
    Element Should Be Locked    id=step-2

Não deve gravar rascunho sem progresso
    Navigate To New PF Reservation
    Draft Storage Should Be Empty    PF
    Reload Page
    Draft Modal Should Not Open

Não deve exibir o modal com apenas o CPF preenchido
    Navigate To New PF Reservation
    Identify Client    ${CLIENT}[doc]
    Reload Page
    Draft Modal Should Not Open

Não deve carregar rascunho PJ na tela PF
    Open Clean Page    /reservas/nova-pj
    Select From List By Value    id=agreement    ACME
    Advance From Client Step
    Fill Stores And Period    10    3
    ${pj_draft}    Execute Javascript    return window.localStorage.getItem('rascunho-PJ')
    Should Not Be Equal    ${pj_draft}    ${None}
    Go To    ${APP_URL}/reservas/nova-pf
    Draft Modal Should Not Open
    Draft Storage Should Be Empty    PF


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE

Start Draft With Progress
    [Documentation]    Avança até o grupo (passo 3) e para: é o progresso que vira rascunho.
    Navigate To New PF Reservation
    Identify Client    ${CLIENT}[doc]
    Advance From Client Step
    Fill Stores And Period    10    3
    Choose Car Group    C
