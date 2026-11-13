# Reservas E2E — Robot Framework + Python

[![Regressao](https://github.com/JardelQuaresma7/robot-reservas-e2e/actions/workflows/regressao.yml/badge.svg)](https://github.com/JardelQuaresma7/robot-reservas-e2e/actions/workflows/regressao.yml)
[![Relatorio](https://img.shields.io/badge/relat%C3%B3rio-GitHub%20Pages-blue)](https://jardelquaresma7.github.io/robot-reservas-e2e/)
![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.4-000000?logo=robotframework)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Robocop](https://img.shields.io/badge/Robocop-0%20apontamentos-brightgreen)

Regressão automatizada de um **fluxo de reservas** — interface e API — com a mesma arquitetura
que eu criei e mantenho num sistema de reservas de uma grande locadora de veículos.
Lá, a suíte tem **62 cenários E2E em 17 suítes** e levou a regressão de **6 horas (manual) para
cerca de 30 minutos**. Como o código do cliente não pode ser público, este repositório replica a
arquitetura contra sistemas públicos de prática:

| Camada | Sistema testado |
|---|---|
| Interface (SeleniumLibrary) | [BlazeDemo](https://blazedemo.com) — pesquisa, escolha de voo, passageiro, pagamento e confirmação |
| API (requests + Python) | [Restful-Booker](https://restful-booker.herokuapp.com) — ciclo de vida da reserva com autenticação por token |

## O que este projeto demonstra

- **Page Objects por tela** e uma camada de **fluxos de negócio**: a suíte diz *o quê*, o fluxo
  esconde *o como* (`resources/page_objects` → `resources/flows` → `suites`).
- **Gate de saúde do ambiente** antes da bateria (`environment_health.py`): aborta só por causa
  externa (site/API fora do ar). Resposta estranha de um sistema no ar vira *WARN*, porque defeito
  tem que aparecer como cenário vermelho, não como aborto silencioso.
- **Retentativa de HTTP centralizada** (`http_retry.py`) e **limpeza garantida da massa**: toda reserva
  criada pela API é registrada e apagada no `Suite Teardown`, mesmo quando o cenário falha.
- **Massa dinâmica com Faker** (`data_factory.py`): cada execução usa passageiros e reservas novos.
- **Execução paralela com pabot**, **reexecução só dos vermelhos** e **merge dos resultados**
  (`scripts/run_regression.py`): o cenário instável aparece verde *com a falha anterior registrada*.
- **Cenários negativos de segurança** na API: escrita sem token, login inválido, id inexistente.
- **Padrão de código com Robocop** (lint + format) rodando como primeira etapa da esteira.
- **Esteira no GitHub Actions**: lint → regressão → relatório publicado no GitHub Pages,
  com execução agendada nos dias úteis e disparo manual filtrando por tag.

## Estrutura

```
resources/
  common.resource            # ponto único de import
  variables/                 # URLs, timeout, credenciais (sobrescrevíveis por --variable / env)
  keywords/                  # navegador e gate de saúde
  libraries/                 # Python: API de reservas, saúde, retentativa, massa
  page_objects/              # home, voos, compra, confirmação
  flows/                     # fluxo de reserva de ponta a ponta
suites/
  web/                       # ciclo completo e validações de tela
  api/                       # ciclo de vida da reserva e segurança
scripts/run_regression.py    # pabot + rerun + rebot --merge + xunit
```

## Como rodar

```bash
pip install -r requirements.txt
python scripts/run_regression.py                    # bateria completa
python scripts/run_regression.py --include smoke    # só o smoke
robot --pythonpath resources/libraries --variable HEADLESS:False suites/web   # ver o navegador
robocop check                                       # padrão de código
```

Relatórios em `results/` (`report.html`, `log.html`, `xunit.xml`).

---

**EN —** End-to-end regression of a reservation flow (UI + API) in Robot Framework and Python,
replicating the architecture I built for a large car-rental company's reservation system
(62 E2E scenarios, regression cut from 6 h to ~30 min). Highlights: page objects + business flows,
environment health gate, centralized HTTP retry, guaranteed test-data cleanup, Faker data,
parallel run with pabot, rerun of failed tests with merged results, Robocop lint and a GitHub
Actions pipeline publishing the report to GitHub Pages.
