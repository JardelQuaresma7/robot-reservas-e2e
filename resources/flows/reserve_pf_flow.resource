*** Settings ***
Documentation    Fluxos de reserva PF montados a partir dos page objects. A suíte descreve o
...              "o quê"; o fluxo esconde o "como" (passo a passo do formulário).

Resource         ../common.resource
Resource         ../page_objects/reserve/form/client_section.resource
Resource         ../page_objects/reserve/form/store_section.resource
Resource         ../page_objects/reserve/form/car_group_section.resource
Resource         ../page_objects/reserve/form/protections_section.resource
Resource         ../page_objects/reserve/form/conductor_section.resource
Resource         ../page_objects/reserve/form/contact_section.resource
Resource         ../page_objects/reserve/shared/summary_panel.resource
Resource         ../page_objects/reserve/shared/reservation_modals.resource
Resource         ../page_objects/reserve/details/details_page.resource


*** Keywords ***
Create Client For Suite
    [Documentation]    Cliente novo e exclusivo da suíte, criado pela API (sai no teardown).
    [Arguments]    ${doc_type}=CPF    ${nationality}=Brasileira
    ${data}    New Client Data    ${doc_type}    ${nationality}
    ${client}    Create Client Via Api    ${data}
    RETURN    ${client}

Navigate To New PF Reservation
    [Documentation]    Abre a reserva PF sem rascunho de cenário anterior.
    Open Clean Page    /reservas/nova-pf
    Wait Until Element Is Visible    id=client-doc

Fill PF Reservation Until Contact
    [Documentation]    Passos 1 a 5 da reserva PF. Devolve quando o passo de contato libera.
    [Arguments]    ${client}    ${pickup_in_days}=10    ${days}=3    ${group}=A    ${store}=${STORE}
    ...    ${rate}=LIVRE    ${protections}=${None}    ${accessories}=${None}
    IF    $protections is None    VAR    @{protections}    BASICA
    Navigate To New PF Reservation
    Identify Client    ${client}[doc]    ${client}[doc_type]
    Advance From Client Step
    Fill Stores And Period    ${pickup_in_days}    ${days}    ${store}    ${store}    ${rate}
    Choose Car Group    ${group}
    Choose Protections And Accessories    ${protections}    ${accessories}
    Wait Conductor Step

Create PF Reservation
    [Documentation]    Caminho feliz completo: devolve o número e o resumo capturado antes de reservar.
    [Arguments]    ${client}    ${pickup_in_days}=10    ${days}=3    ${group}=A    ${store}=${STORE}
    ...    ${rate}=LIVRE    ${protections}=${None}    ${accessories}=${None}
    Fill PF Reservation Until Contact    ${client}    ${pickup_in_days}    ${days}    ${group}    ${store}
    ...    ${rate}    ${protections}    ${accessories}
    Advance From Conductor Step
    Fill Phone    ${client}[phone]
    ${summary}    Capture Summary
    Submit Reservation
    ${number}    Reservation Should Be Created
    RETURN    ${number}    ${summary}

Verify Details Match Summary
    [Documentation]    O detalhe gravado bate com o resumo mostrado antes de reservar.
    [Arguments]    ${summary}
    Detail Field Should Be    cliente    ${summary}[cliente]
    Detail Field Should Be    tarifa    ${summary}[tarifa]
    Detail Field Should Be    grupo    ${summary}[grupo]
    Detail Field Should Be    total    ${summary}[total]
