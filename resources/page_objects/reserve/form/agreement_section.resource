*** Settings ***
Documentation    Passo 1 da reserva PJ: acordo corporativo e, no acordo de carro reserva,
...              número do sinistro (obrigatório) e reserva externa (opcional).

Resource         ../../../common.resource


*** Variables ***
${SELECT_AGREEMENT}      id=agreement
${REPLACEMENT_FIELDS}    id=replacement-fields
${INPUT_CLAIM_NUMBER}    id=claim-number
${INPUT_EXTERNAL_RES}    id=external-reservation


*** Keywords ***
Select Agreement
    [Documentation]    Escolhe o acordo pelo código (ACME, ALFA).
    [Arguments]    ${agreement}
    Select From List By Value    ${SELECT_AGREEMENT}    ${agreement}

Fill Replacement Data
    [Documentation]    Sinistro e reserva externa do acordo de carro reserva; vazio não digita.
    [Arguments]    ${claim}=${EMPTY}    ${external}=${EMPTY}
    Wait Until Element Is Visible    ${INPUT_CLAIM_NUMBER}
    IF    '${claim}' != '${EMPTY}'
        Fill Field    ${INPUT_CLAIM_NUMBER}    ${claim}
    END
    IF    '${external}' != '${EMPTY}'
        Fill Field    ${INPUT_EXTERNAL_RES}    ${external}
    END

Replacement Fields Should Be Hidden
    [Documentation]    Acordo comum não mostra sinistro nem reserva externa.
    Element Should Not Be Visible    ${INPUT_CLAIM_NUMBER}
