"""Runs the same 6 bilingual smoke tests used in Phase 8
(docs/validation/phase-8-parity-validation.md) against this Agent Framework
translation of the workflow, and saves raw structured evidence to
validation/raw/<test_id>.json for each one.

Usage:
    PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python validation/run_suite.py
"""

import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from smid_compass.run_workflow import run_with_trace  # noqa: E402

RAW_DIR = Path(__file__).resolve().parent / "raw"

TESTS = [
    ("a1_passport_es", "Necesito renovar mi pasaporte venezolano desde Alemania. ¿Qué debo hacer?"),
    ("a2_passport_de", "Ich muss meinen venezolanischen Reisepass von Deutschland aus erneuern. Was muss ich tun?"),
    ("b1_workshop_es", "¿Qué talleres ofrece SMID y cómo puedo participar?"),
    ("b2_workshop_de", "Welche Workshops bietet SMID an und wie kann ich daran teilnehmen?"),
    ("c1_oos_es", "¿Cuál es la temperatura en Marte hoy?"),
    ("c2_oos_de", "Wie ist das Wetter heute auf dem Mars?"),
]


async def main() -> None:
    RAW_DIR.mkdir(exist_ok=True)
    for test_id, message in TESTS:
        print(f"=== {test_id} ===")
        result = await run_with_trace(message)
        out_path = RAW_DIR / f"{test_id}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"  error: {result['error']}")
        print(f"  node_sequence: {result['node_sequence']}")
        print(f"  outputs: {len(result['outputs'])}")
        print(f"  saved: {out_path}")
        print()


if __name__ == "__main__":
    asyncio.run(main())
