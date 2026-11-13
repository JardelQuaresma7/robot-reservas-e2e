*** Settings ***
Documentation     Cadastro de cliente PF pela tela, com dados do Faker: CPF, passaporte brasileiro e
...               estrangeiro, endereço pelo CEP, termos, campos obrigatórios e CPF duplicado.

Resource          ../../resources/flows/reserve_pf_flow.resource
Resource          ../../resources/page_objects/client/client_create_page.resource

Suite Setup       Start Browser Session
Suite Teardown    Close Browser Session
Test Setup        Navigate To Client Create

Test Tags         cliente    cadastro

Name              Cadastro de cliente PF


*** Test Cases ***
Deve cadastrar cliente PF com dados validos
    [Tags]    smoke
    ${client}    New Client Data
    Fill Client Form    ${client}
    Accept Terms
    Register Client
    Client Should Be Registered    ${client}

Deve cadastrar cliente com passaporte brasileiro
    ${client}    New Client Data    PASSAPORTE    Brasileira
    Fill Client Form    ${client}
    Accept Terms
    Register Client
    Client Should Be Registered    ${client}

Deve cadastrar cliente estrangeiro com passaporte
    ${client}    New Client Data    PASSAPORTE    Estrangeira
    Fill Client Form    ${client}
    List Selection Should Be    id=doc-type    PASSAPORTE
    Element Should Be Disabled    id=doc-type
    Accept Terms
    Register Client
    Client Should Be Registered    ${client}

Deve preencher o endereco pelo CEP
    Fill Address By Zip    01310-100
    Textfield Value Should Be    id=street    Avenida Paulista
    Textfield Value Should Be    id=city    São Paulo
    Textfield Value Should Be    id=state    SP

Deve manter o cadastro desabilitado sem aceitar os termos
    ${client}    New Client Data
    Fill Client Form    ${client}
    Register Button Should Be Disabled
    Accept Terms
    Element Should Be Enabled    id=btn-cadastrar

Deve exigir nome e sobrenome
    ${client}    New Client Data
    Set To Dictionary    ${client}    last_name=${EMPTY}
    Fill Client Form    ${client}
    Accept Terms
    Register Client
    Client Error Should Be    Informe nome e sobrenome.

Deve avisar que o CPF ja tem conta
    ${data}    New Client Data
    Create Client Via Api    ${data}
    ${again}    New Client Data
    Set To Dictionary    ${again}    doc=${data}[doc]
    Fill Client Form    ${again}
    Accept Terms
    Register Client
    Client Error Should Be    Este documento já possui cadastro.

Deve cadastrar e reservar com o cliente novo
    ${client}    New Client Data
    Fill Client Form    ${client}
    Accept Terms
    Register Client
    Client Should Be Registered    ${client}
    Reserve For Registered Client
    Wait Until Element Contains    id=client-found    ${client}[first_name] ${client}[last_name]
    Advance From Client Step
    Fill Stores And Period    15    2
    Choose Car Group    C
    VAR    @{protections}    TOTAL
    Choose Protections And Accessories    ${protections}
    Advance From Conductor Step
    Submit Reservation
    Reservation Should Be Created
    Detail Field Should Be    cliente    ${client}[first_name] ${client}[last_name]
