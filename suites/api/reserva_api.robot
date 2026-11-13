*** Settings ***
Documentation     Regras de negócio direto na API: cálculo de preço, tarifa mensal, grupo
...               indisponível, reserva ativa, acordo replacement e segurança por chave.

Resource          ../../resources/flows/reserve_pf_flow.resource

Suite Setup       Prepare Suite
Suite Teardown    Delete Test Data Created By Suite

Test Tags         api

Name              API de reservas


*** Test Cases ***
Deve calcular a cotação com diárias, proteção, acessório e motorista excedente
    ${pickup}    Date From Today    10
    ${return}    Date From Today    13
    ${extra}    New Cpf
    VAR    &{body}    type=PF    pickup_store=PAU    return_store=PAU    group=C    rate=LIVRE
    ...    pickup_date=${pickup}    return_date=${return}    protections=${{['TOTAL']}}
    ...    accessories=${{['GPS']}}    additional_drivers=${{['${extra}']}}
    ${quote}    Call Api    POST    /api/quotation    ${body}
    Should Be Equal As Numbers    ${quote}[daily_total]    480
    Should Be Equal As Numbers    ${quote}[protections_total]    210
    Should Be Equal As Numbers    ${quote}[accessories_total]    30
    Should Be Equal As Numbers    ${quote}[drivers_total]    60
    Should Be Equal As Numbers    ${quote}[total]    780

Deve aplicar a tarifa mensal a partir de 28 diárias
    ${pickup}    Date From Today    10
    ${return}    Date From Today    38
    VAR    &{body}    type=PF    pickup_store=PAU    return_store=PAU    group=A    rate=LIVRE
    ...    pickup_date=${pickup}    return_date=${return}    protections=${{['BASICA']}}
    ${quote}    Call Api    POST    /api/quotation    ${body}
    Should Be Equal    ${quote}[rate]    MENSAL
    Should Be Equal As Numbers    ${quote}[daily_total]    2520

Deve recusar grupo indisponível sem decisão de forçar ou solicitar
    ${error}    Call Reservation Expecting Error    pickup_in_days=60    store=${STORE_SOLD_OUT}
    ...    group=${GROUP_SOLD_OUT}    status=409
    Should Be Equal    ${error}[code]    GROUP_UNAVAILABLE

Deve recusar reserva ativa no mesmo período sem confirmação
    Create Reservation Via Api    ${CLIENT}    pickup_in_days=70    days=5
    ${error}    Call Reservation Expecting Error    pickup_in_days=72    status=409
    Should Be Equal    ${error}[code]    ACTIVE_RESERVATION

Deve exigir número do sinistro no acordo replacement
    ${driver}    New Cpf
    ${pickup}    Date From Today    10
    ${return}    Date From Today    12
    VAR    &{body}    type=PJ    agreement=ALFA    pickup_store=PAU    return_store=PAU    group=A
    ...    pickup_date=${pickup}    return_date=${return}    protections=${{['BASICA']}}
    ...    driver=${{ {'doc_type': 'CPF', 'doc': '${driver}', 'name': 'Condutor'} }}
    ...    contact=${{ {'phone': '11999990000'} }}
    ${error}    Call Api    POST    /api/reservations    ${body}    expected_status=422
    Should Be Equal    ${error}[code]    CLAIM_REQUIRED

Deve recusar chamada sem chave de API
    ${status}    Call Api Without Key    GET    /api/reservations?number=R000000
    Should Be Equal As Integers    ${status}    401

Deve devolver 404 para reserva inexistente
    ${error}    Call Api    GET    /api/reservations/R999999    expected_status=404
    Should Be Equal    ${error}[code]    NOT_FOUND


*** Keywords ***
Prepare Suite
    [Documentation]    Cliente exclusivo da suíte (sem navegador).
    ${client}    Create Client For Suite
    VAR    ${CLIENT}    ${client}    scope=SUITE

Call Reservation Expecting Error
    [Documentation]    Tenta criar reserva PF do cliente da suíte e devolve o erro.
    [Arguments]    ${pickup_in_days}    ${status}    ${store}=${STORE}    ${group}=A
    ${pickup}    Date From Today    ${pickup_in_days}
    ${return_in}    Evaluate    ${pickup_in_days} + 2
    ${return}    Date From Today    ${return_in}
    VAR    &{body}    type=PF    client_id=${CLIENT}[id]    pickup_store=${store}    return_store=${store}
    ...    group=${group}    pickup_date=${pickup}    return_date=${return}    protections=${{['BASICA']}}
    ...    driver=${{ {'doc_type': 'CPF', 'doc': '${CLIENT}[doc]', 'name': 'Cliente'} }}
    ...    contact=${{ {'phone': '11999990000'} }}
    ${error}    Call Api    POST    /api/reservations    ${body}    expected_status=${status}
    RETURN    ${error}
