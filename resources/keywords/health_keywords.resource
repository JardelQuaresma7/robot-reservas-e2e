*** Settings ***
Documentation    Gate de saúde chamado no ``__init__.robot`` de cada pasta de suítes.

Resource         ../common.resource


*** Keywords ***
Ensure Environment Is Healthy
    [Documentation]    Aborta a pasta inteira só se o front cair ou a cotação quebrar por erro de servidor.
    ${front}    Check Front Is Up    ${APP_URL}
    ${quotation}    Check Quotation Chain    ${APP_URL}    ${API_KEY}
    Abort Suite If Environment Is Down    ${front}    ${quotation}
