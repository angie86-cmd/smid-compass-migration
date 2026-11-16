"""Phase-equivalent smoke test for the Agent Framework modernization of SMID
Compass. Mirrors the first two tests from docs/validation/phase-8-parity-validation.md
(Spanish and German passport routes). NOT yet run end-to-end: see the "Open
decision" section in ../README.md (local .NET runtime required for the
declarative Power Fx expression evaluator used by the reused workflow YAML).

Run manually once that decision is made:
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
