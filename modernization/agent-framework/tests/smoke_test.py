"""Phase-equivalent smoke test for the Agent Framework modernization of SMID
Compass. Mirrors the first two tests from docs/validation/phase-8-parity-validation.md
(Spanish and German passport routes). Both passed locally against the live
Foundry agents on 2026-11-16, after installing a local .NET Runtime 10 for
the declarative Power Fx expression evaluator (see ../README.md). The full
6-test bilingual parity suite (this file's 2 tests plus workshop and
out-of-scope, ES/DE) also passed — see ../validation/run_suite.py and
../validation/agent-framework-smoke-validation.md for that complete evidence.

Run:
    PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python tests/smoke_test.py
"""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from smid_compass.run_workflow import run_once  # noqa: E402

SPANISH_PASSPORT = "Necesito renovar mi pasaporte venezolano desde Alemania. ¿Qué debo hacer?"
GERMAN_PASSPORT = "Ich muss meinen venezolanischen Reisepass von Deutschland aus erneuern. Was muss ich tun?"


async def main() -> None:
    print("=== Spanish passport test ===")
    await run_once(SPANISH_PASSPORT)
    print()
    print("=== German passport test ===")
    await run_once(GERMAN_PASSPORT)


if __name__ == "__main__":
    asyncio.run(main())
