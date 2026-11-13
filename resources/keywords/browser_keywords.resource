*** Settings ***
Documentation    Abertura e fechamento do navegador. Headless por padrão; ``--variable HEADLESS:False``
...              abre a janela para depurar.

Resource         ../common.resource


*** Keywords ***
Open Travel Agency
    [Documentation]    Abre o site já na home, com janela de tamanho fixo para o print sair igual.
    ${options}    Evaluate    selenium.webdriver.ChromeOptions()    modules=selenium.webdriver
    IF    ${HEADLESS}
        Call Method    ${options}    add_argument    --headless\=new
    END
    Call Method    ${options}    add_argument    --window-size\=1366,900
    Call Method    ${options}    add_argument    --disable-dev-shm-usage
    Call Method    ${options}    add_argument    --no-sandbox
    Open Browser    ${WEB_URL}    ${BROWSER}    options=${options}

Close Travel Agency
    [Documentation]    Fecha todos os navegadores abertos pelo cenário.
    Close All Browsers
