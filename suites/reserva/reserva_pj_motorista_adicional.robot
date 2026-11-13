*** Settings ***
Documentation     O acordo ACME isenta 2 motoristas adicionais; o terceiro é cobrado (R$ 20,00 por dia).

Resource          ../../resources/flows/reserve_pj_flow.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session

Test Tags         reserva    pj    motorista-adicional

Name              Reserva PJ - Motorista adicional


*** Test Cases ***
Deve isentar no resumo os motoristas adicionais que o acordo oferece
    Go To PJ Conductor Step    pickup_in_days=12
    Add Drivers    2
    Summary Field Should Contain    motoristas    2 isento(s), 0 cobrado(s)
    Summary Field Should Contain    motoristas-valor    R$ 0,00

Deve cobrar apenas o motorista excedente na reserva PJ criada
    Go To PJ Conductor Step    pickup_in_days=18
    Add Drivers    3
    Summary Field Should Contain    motoristas    2 isento(s), 1 cobrado(s)
    Advance From Conductor Step
    Fill Phone    11988887777
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    motoristas    3 (2 isento(s), 1 cobrado(s))
    Detail Field Should Be    motoristas-valor    R$ 60,00


*** Keywords ***
Go To PJ Conductor Step
    [Documentation]    Reserva PJ no acordo ACME até o passo do condutor, 3 diárias.
    [Arguments]    ${pickup_in_days}
    ${driver_cpf}    New Cpf
    ${driver_name}    New Person Name
    Fill PJ Reservation Until Contact    ACME    ${driver_cpf}    ${driver_name}    ${pickup_in_days}    3

Add Drivers
    [Documentation]    Inclui N motoristas adicionais com CPFs novos.
    [Arguments]    ${count}
    FOR    ${_}    IN RANGE    ${count}
        ${cpf}    New Cpf
        Add Additional Driver    ${cpf}
    END
    Additional Driver Count Should Be    ${count}
