"""Roda a bateria em paralelo, reexecuta só os vermelhos e junta tudo num relatório.

Fluxo:
1. ``pabot`` roda as suítes em paralelo (uma por processo).
2. Se houver falha, ``robot --rerunfailed`` roda de novo só os cenários vermelhos.
3. ``rebot --merge`` junta as duas execuções: o cenário que passou na segunda vez aparece
   verde, com a primeira falha registrada no log (instabilidade fica visível, não escondida).
4. Gera ``xunit.xml`` para a aba de testes da esteira.

Uso: ``python scripts/run_regression.py [--processes 4] [--include smoke] [-- <args extras do robot>]``
O código de saída é o do resultado final (0 = tudo verde).
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RESULTADOS = RAIZ / "results"
PYTHONPATH = str(RAIZ / "resources" / "libraries")


def executar(comando):
    print(">>", " ".join(comando), flush=True)
    return subprocess.call(comando, cwd=RAIZ)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--processes", type=int, default=4)
    parser.add_argument("--include", action="append", default=[])
    parser.add_argument("extras", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    extras = [a for a in args.extras if a != "--"]
    filtros = [item for tag in args.include for item in ("--include", tag)]

    shutil.rmtree(RESULTADOS, ignore_errors=True)
    RESULTADOS.mkdir()
    primeira = RESULTADOS / "output_1.xml"

    status = executar([
        sys.executable, "-m", "pabot.pabot", "--processes", str(args.processes),
        "--pythonpath", PYTHONPATH, "--outputdir", str(RESULTADOS),
        "--output", primeira.name, "--log", "NONE", "--report", "NONE",
        *filtros, *extras, "suites",
    ])

    saidas = [str(primeira)]
    if status != 0 and primeira.exists():
        segunda = RESULTADOS / "output_2.xml"
        executar([
            sys.executable, "-m", "robot", "--rerunfailed", str(primeira),
            "--pythonpath", PYTHONPATH, "--outputdir", str(RESULTADOS),
            "--output", segunda.name, "--log", "NONE", "--report", "NONE",
            *extras, "suites",
        ])
        if segunda.exists():
            saidas.append(str(segunda))

    final = executar([
        sys.executable, "-m", "robot.rebot", "--merge" if len(saidas) > 1 else "--name",
        *([] if len(saidas) > 1 else ["Reservas E2E"]),
        "--outputdir", str(RESULTADOS), "--output", "output.xml",
        "--xunit", "xunit.xml", "--log", "log.html", "--report", "report.html",
        *saidas,
    ])
    return final


if __name__ == "__main__":
    sys.exit(main())
