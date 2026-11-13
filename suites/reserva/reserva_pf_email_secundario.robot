*** Settings ***
Documentation     Toggle "Enviar cópia para outro e-mail": habilita, valida, reseta e grava.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Close Browser Session

Test Tags         reserva    pf    email-secundario

Name              Reserva PF - E-mail secundário


*** Test Cases ***
Deve habilitar o campo de e-mail secundário ao ligar o toggle
    Go To Contact Step
    Element Should Be Disabled    id=secondary-email
    Turn Secondary Email On
    Secondary Email Should Be Enabled

Deve resetar o e-mail secundário ao desligar o toggle
    Go To Contact Step
    Turn Secondary Email On
    Fill Secondary Email    copia@example.com
    Turn Secondary Email Off
    Secondary Email Should Be Reset

Deve bloquear o avanço com e-mail secundário inválido
    Go To Contact Step
    Turn Secondary Email On
    Fill Secondary Email    copia-sem-arroba.com
    Submit Reservation
    Contact Error Should Be    E-mail secundário inválido.
    Location Should Contain    /reservas/nova-pf

Deve manter o e-mail secundário no formulário com o toggle ligado
    Go To Contact Step    pickup_in_days=30
    Turn Secondary Email On
    Fill Secondary Email    copia.financeiro@example.com
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    email-secundario    copia.financeiro@example.com

Não deve manter o e-mail secundário com o toggle desligado
    Go To Contact Step    pickup_in_days=40
    Turn Secondary Email On
    Fill Secondary Email    nao.deve.gravar@example.com
    Turn Secondary Email Off
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    email-secundario    -

Deve zerar o toggle de e-mail secundário ao trocar o CPF
    Go To Contact Step
    Turn Secondary Email On
    Fill Secondary Email    copia@example.com
    ${other}    New Cpf
    Change Client Document    ${other}
    Secondary Email Should Be Reset
    Element Should Be Locked    id=step-6


*** Keywords ***
Prepare Suite
    [Documentation]    Navegador e cliente exclusivo da suíte.
    Start Browser Session
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE

Go To Contact Step
    [Documentation]    Preenche os passos 1 a 5 e para no contato, com telefone preenchido.
    [Arguments]    ${pickup_in_days}=10
    Fill PF Reservation Until Contact    ${CLIENT}    pickup_in_days=${pickup_in_days}
    Advance From Conductor Step
    Fill Phone    ${CLIENT}[phone]
