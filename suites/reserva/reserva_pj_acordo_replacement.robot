*** Settings ***
Documentation     Acordo de seguradora: exige número do sinistro, aceita reserva externa opcional e
...               grava is_replacement. Acordo comum não mostra esses campos.

Resource          ../../resources/flows/reserve_pj_flow.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pj    replacement

Name              Reserva PJ - Acordo de carro reserva (replacement)


*** Test Cases ***
Deve criar reserva em acordo replacement e registrar isReplacement no detalhe
    ${claim}    Generate Random String    8    [NUMBERS]
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Create PJ Reservation    ALFA    ${driver_cpf}    ${driver_name}    pickup_in_days=11
    ...    claim=SIN-${claim}    external=EXT-998877
    Detail Field Should Be    replacement    Sim
    Detail Field Should Be    sinistro    SIN-${claim}
    Detail Field Should Be    reserva-externa    EXT-998877

Deve bloquear a reserva sem o número do sinistro no acordo replacement
    Navigate To New PJ Reservation
    Select Agreement    ALFA
    Fill Replacement Data    external=EXT-1
    Advance From Client Step
    Wait Until Element Contains    id=step-1-error    Informe o número do sinistro.
    Element Should Be Locked    id=step-2

Deve manter Reserva Externa opcional e isReplacement falso no acordo comum
    Navigate To New PJ Reservation
    Select Agreement    ACME
    Replacement Fields Should Be Hidden
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Create PJ Reservation    ACME    ${driver_cpf}    ${driver_name}    pickup_in_days=13
    Detail Field Should Be    replacement    Não
    Detail Field Should Be    reserva-externa    -
