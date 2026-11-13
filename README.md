# Reservas E2E — Robot Framework + Python

[![Regressao](https://github.com/JardelQuaresma7/robot-reservas-e2e/actions/workflows/regressao.yml/badge.svg)](https://github.com/JardelQuaresma7/robot-reservas-e2e/actions/workflows/regressao.yml)
[![Relatorio](https://img.shields.io/badge/relat%C3%B3rio-GitHub%20Pages-blue)](https://jardelquaresma7.github.io/robot-reservas-e2e/)
![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.4-000000?logo=robotframework)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Robocop](https://img.shields.io/badge/Robocop-0%20apontamentos-brightgreen)

Regressão automatizada de uma **central de reservas de locadora de veículos**: reserva PF e PJ,
edição, consulta, cancelamento, motorista adicional, grupo indisponível, rascunho, cadastro de
cliente e API.

**De onde vem:** este projeto é uma réplica da automação que eu criei e mantenho, como QA Sênior
(Blite Tecnologia), para a **Central de Reservas da Unidas** — **62 cenários E2E em 17 suítes**,
que levaram a regressão de **6 horas (manual) para cerca de 30 minutos** no pipeline.
O sistema e o repositório da Unidas são privados, então aqui estão **a mesma arquitetura e o
mesmo catálogo de cenários**, reescritos para rodar contra a **Locadora Demo** (`app/`), um sistema
de reservas pequeno que eu escrevi só para ser o alvo dos testes. Nenhum código, URL, credencial
ou dado da Unidas está neste repositório.

## Catálogo de cenários (69)

| Suíte | Cenários | O que cobre |
|---|---:|---|
| Reserva PF - Criação | 1 | Caminho feliz completo, resumo x detalhe |
| Reserva PF - Ciclo completo | 1 | Cria → confere → edita com acessório (total sobe) → cancela pela consulta |
| Reserva PF mensal - Ciclo completo | 1 | 30 diárias viram tarifa Mensal com desconto; edita e cancela |
| Reserva PF - Condutor diferente | 2 | Cliente paga, outra pessoa dirige |
| Reserva PF - E-mail secundário | 6 | Toggle habilita, valida, reseta, grava e zera ao trocar o CPF |
| Reserva PF - Motorista adicional | 2 | Tarifa isenta 1 motorista; excedente cobrado no resumo e no detalhe |
| Reserva PF - Passaporte | 2 | Cliente estrangeiro identificado pelo passaporte |
| Reserva PF - Rascunho | 6 | Modal de reserva em andamento: continuar, descartar, quando não aparece |
| Reserva PF - Validações | 6 | CPF inválido, reset dos passos, motorista duplicado, proteção obrigatória, telefone, reserva ativa no período |
| Reserva PJ - Criação | 1 | Acordo corporativo com desconto |
| Reserva PJ - Ciclo completo | 1 | Cria → troca de grupo (total sobe) → cancela |
| Reserva PJ - Motorista adicional | 2 | Acordo isenta 2; o terceiro é cobrado |
| Reserva PJ - Condutor com passaporte | 2 | Condutor estrangeiro do acordo |
| Reserva PJ - Acordo replacement | 3 | Sinistro obrigatório, reserva externa opcional, flag de carro reserva |
| Grupo indisponível (PF e PJ) | 6 | Modal na criação (forçar / solicitar) e edição de confirmada sem modal |
| Consulta de reserva | 12 | Filtros (número, CPF, condutor, acordo, status) e ações (ver, editar, e-mail, PDF, cancelar) |
| Cadastro de cliente PF | 8 | CPF, passaporte, estrangeiro, CEP, termos, obrigatórios, duplicado, cadastrar e reservar |
| API de reservas | 7 | Cálculo de preço, tarifa mensal, regras 409/422, chave de API, 404 |

## Arquitetura

- **Page Objects por seção do formulário** (`resources/page_objects/reserve/form/*`: cliente, lojas,
  grupo, proteções, condutor, contato) e **fluxos de negócio** por cima (`resources/flows`):
  a suíte diz *o quê*, o fluxo esconde *o como*.
- **Massa isolada por suíte:** cada suíte cria o próprio cliente pela API no `Suite Setup` e apaga
  tudo no `Suite Teardown` (`reservation_api.py`), inclusive o que sobrou de cenário que falhou.
  Por isso as suítes rodam **em paralelo** sem uma bloquear a reserva da outra.
- **Conferência por dado capturado, não por valor fixo:** o ciclo completo fotografa o resumo antes
  de reservar e compara com o detalhe gravado.
- **Gate de saúde** (`environment_health.py`): antes da bateria, confere o front e faz a mesma
  cotação da tela. Só aborta por causa externa; resposta estranha vira *WARN*, porque defeito tem
  que aparecer como cenário vermelho.
- **Retentativa de HTTP centralizada** (`http_retry.py`) e **massa dinâmica com Faker**
  (CPF válido, passaporte, nomes).
- **pabot + rerun dos vermelhos + merge** (`scripts/run_regression.py`): o instável aparece verde
  com a primeira falha registrada no log, nunca escondida.
- **Robocop** (lint + format) como primeira etapa da esteira; as exceções de regra estão
  justificadas no `robocop.toml`.
- **GitHub Actions:** lint → sobe a Locadora Demo → regressão → relatório no GitHub Pages;
  agendada nos dias úteis e com disparo manual por tag (ex.: `smoke`).

```
app/                          # Locadora Demo (FastAPI + Jinja): só o alvo dos testes
resources/
  common.resource             # ponto único de import
  variables/                  # URL, chave, lojas e grupos de teste (sobrescrevíveis)
  keywords/                   # navegador, gate de saúde, ações genéricas de UI
  libraries/                  # Python: API/limpeza, saúde, retentativa, massa
  page_objects/reserve/       # form/, shared/, details/, update/, search/
  page_objects/client/        # cadastro de cliente
  flows/                      # reserva PF e PJ de ponta a ponta
suites/
  reserva/  cliente/  api/
scripts/run_regression.py     # pabot + rerun + rebot --merge + xunit
```

## Como rodar

```bash
pip install -r requirements.txt
python -m uvicorn main:app --app-dir app --port 8000        # sobe a Locadora Demo
python scripts/run_regression.py                            # bateria completa (~1 min)
python scripts/run_regression.py --include smoke            # smoke
robot --pythonpath resources/libraries --variable HEADLESS:False suites/reserva/reserva_pf_criacao.robot
robocop check
```

---

**EN —** End-to-end regression of a car-rental reservation system in Robot Framework and Python:
individual and corporate reservations, update, search, cancellation, additional drivers,
sold-out car groups, drafts, customer registration and API rules — 69 scenarios. It is a replica
of the automation I built for the Reservation Center of Unidas, a large Brazilian car-rental
company (62 E2E scenarios in 17 suites, regression cut from 6 h to ~30 min): same architecture and
scenario catalogue, rewritten to run against a small demo app written only as the test target.
No Unidas code, URLs, credentials or data are included. Highlights: section-level page objects + business flows, per-suite isolated test
data with guaranteed cleanup, parallel execution with pabot, rerun with merged results,
environment health gate, Robocop and a GitHub Actions pipeline publishing the report.
