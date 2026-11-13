*** Settings ***
Documentation    Fluxos de reserva PJ: acordo corporativo, condutor do acordo e contato.

Resource         ../common.resource
Resource         reserve_pf_flow.resource
Resource         ../page_objects/reserve/form/agreement_section.resource


*** Keywords ***
Navigate To New PJ Reservation
    [Documentation]    Abre a reserva PJ sem rascunho de cenário anterior.
    Open Clean Page    /reservas/nova-pj
    Wait Until Element Is Visible    id=agreement

Fill PJ Reservation Until Contact
    [Documentation]    Passos 1 a 5 da reserva PJ, com condutor informado.
    [Arguments]    ${agreement}    ${driver_doc}    ${driver_name}    ${pickup_in_days}=10    ${days}=3
    ...    ${group}=A    ${store}=${STORE}    ${claim}=${EMPTY}    ${external}=${EMPTY}
    ...    ${driver_doc_type}=CPF
    Navigate To New PJ Reservation
    Select Agreement    ${agreement}
    IF    '${agreement}' == 'ALFA'
        Fill Replacement Data    ${claim}    ${external}
    END
    Advance From Client Step
    Fill Stores And Period    ${pickup_in_days}    ${days}    ${store}    ${store}
    Choose Car Group    ${group}
    VAR    @{protections}    BASICA
    Choose Protections And Accessories    ${protections}
    Fill Different Conductor    ${driver_doc}    ${driver_name}    ${driver_doc_type}

Create PJ Reservation
    [Documentation]    Caminho feliz da reserva PJ: devolve número e resumo.
    [Arguments]    ${agreement}    ${driver_doc}    ${driver_name}    ${pickup_in_days}=10    ${days}=3
    ...    ${group}=A    ${store}=${STORE}    ${claim}=${EMPTY}    ${external}=${EMPTY}
    ...    ${driver_doc_type}=CPF
    Fill PJ Reservation Until Contact    ${agreement}    ${driver_doc}    ${driver_name}    ${pickup_in_days}
    ...    ${days}    ${group}    ${store}    ${claim}    ${external}    ${driver_doc_type}
    Advance From Conductor Step
    Fill Phone    11988887777
    ${summary}    Capture Summary
    Submit Reservation
    ${number}    Reservation Should Be Created
    RETURN    ${number}    ${summary}
