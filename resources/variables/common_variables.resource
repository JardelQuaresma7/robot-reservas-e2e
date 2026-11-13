*** Settings ***
Documentation    Variáveis de ambiente da bateria. Tudo pode ser sobrescrito na linha de comando
...              (``--variable APP_URL:https://...``) ou por variável de ambiente, e é assim que a
...              esteira troca de ambiente.


*** Variables ***
${APP_URL}           %{APP_URL=http://127.0.0.1:8000}
${API_KEY}           %{DEMO_API_KEY=demo-key}
${BROWSER}           chrome
${HEADLESS}          ${TRUE}
${TIMEOUT}           10s
${STORE}             PAU
${STORE_NAME}        SP - Avenida Paulista
# Loja onde o Grupo F (SUV) está esgotado.
${STORE_SOLD_OUT}    CGH
${GROUP_SOLD_OUT}    F
