*** Settings ***
Documentation    Ponto único de import: suítes, fluxos e page objects importam só este arquivo.
...              As variáveis vêm primeiro porque os imports de biblioteca usam ${TIMEOUT} e ${APP_URL}.

Resource         variables/common_variables.resource
Library          Collections
Library          String
Library          SeleniumLibrary    timeout=${TIMEOUT}    run_on_failure=Capture Page Screenshot
Library          environment_health.py
Library          data_factory.py
Library          reservation_api.py    ${APP_URL}    ${API_KEY}
Resource         keywords/browser_keywords.resource
Resource         keywords/health_keywords.resource
Resource         keywords/ui_keywords.resource
