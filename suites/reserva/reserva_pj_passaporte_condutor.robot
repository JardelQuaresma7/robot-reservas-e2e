*** Settings ***
Documentation     Condutor estrangeiro do acordo, identificado pelo passaporte.

Resource          ../../resources/flows/reserve_pj_flow.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pj    passaporte

Name              Reserva PJ - Condutor com passaporte


*** Test Cases ***
Deve identificar o condutor PJ pelo passaporte
    ${passport}    New Passport
    ${name}    New Person Name
    Fill PJ Reservation Until Contact    ACME    ${passport}    ${name}    driver_doc_type=PASSAPORTE
    Advance From Conductor Step
    Wait Contact Step
    Element Text Should Be    id=step-5-error    ${EMPTY}

Deve criar reserva PJ com condutor identificado por passaporte
    ${passport}    New Passport
    ${name}    New Person Name
    Create PJ Reservation    ACME    ${passport}    ${name}
    ...    pickup_in_days=14    driver_doc_type=PASSAPORTE
    Detail Field Should Be    condutor    ${name} (PASSAPORTE ${passport})
