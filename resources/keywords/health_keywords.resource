*** Settings ***
Documentation    Gate de saúde chamado no ``__init__.robot`` de cada pasta de suítes.

Resource         ../common.resource


*** Keywords ***
Web Environment Must Be Up
    [Documentation]    Aborta a pasta inteira só se o site estiver fora do ar.
    ${web}    Check Web Is Up    ${WEB_URL}
    Abort Suite If Environment Is Down    ${web}

Api Environment Must Be Up
    [Documentation]    Aborta a pasta inteira só se a API de reservas não responder.
    ${api}    Check Booking Api Is Up    ${API_URL}
    Abort Suite If Environment Is Down    ${api}
