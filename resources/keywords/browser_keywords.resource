*** Settings ***
Documentation    Sessão do navegador: uma janela por suíte, página limpa por cenário.
...              Headless por padrão; ``--variable HEADLESS:False`` abre a janela para depurar.

Resource         ../common.resource


*** Keywords ***
Start Browser Session
    [Documentation]    Abre o Chrome na home do sistema, com janela de tamanho fixo.
    ${options}    Evaluate    selenium.webdriver.ChromeOptions()    modules=selenium.webdriver
    IF    ${HEADLESS}
        Call Method    ${options}    add_argument    --headless\=new
    END
    Call Method    ${options}    add_argument    --window-size\=1440,1000
    Call Method    ${options}    add_argument    --disable-dev-shm-usage
    Call Method    ${options}    add_argument    --no-sandbox
    Open Browser    ${APP_URL}    ${BROWSER}    options=${options}

Close Browser Session
    [Documentation]    Fecha o navegador e apaga a massa que a suíte criou.
    Close All Browsers
    Delete Test Data Created By Suite

Open Clean Page
    [Documentation]    Abre a página sem rascunho salvo de cenário anterior (localStorage zerado).
    [Arguments]    ${path}
    Go To    ${APP_URL}/
    Execute Javascript    window.localStorage.clear()
    Go To    ${APP_URL}${path}
