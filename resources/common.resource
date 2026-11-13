*** Settings ***
Documentation    Ponto único de import: suítes e page objects importam só este arquivo.
...              As variáveis vêm primeiro porque o import da SeleniumLibrary usa ${TIMEOUT}.

Resource         variables/common_variables.resource
Library          Collections
Library          String
Library          SeleniumLibrary    timeout=${TIMEOUT}    run_on_failure=Capture Page Screenshot
Library          environment_health.py
Library          data_factory.py
Resource         keywords/browser_keywords.resource
Resource         keywords/health_keywords.resource
