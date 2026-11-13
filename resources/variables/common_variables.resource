*** Settings ***
Documentation    Variáveis de ambiente da bateria. Tudo pode ser sobrescrito na linha de comando
...              (``--variable WEB_URL:https://...``), e é assim que a esteira troca de ambiente.


*** Variables ***
${WEB_URL}         https://blazedemo.com
${API_URL}         https://restful-booker.herokuapp.com
${BROWSER}         chrome
${HEADLESS}        ${TRUE}
${TIMEOUT}         15s
${API_USER}        %{BOOKER_USER=admin}
${API_PASSWORD}    %{BOOKER_PASSWORD=password123}
