#!/usr/bin/env python3
"""`preset_options.py` — 두 실행 모드가 **같은 preset** 에서 나오는지.

이 헬퍼가 모든 e2e 실행의 번역 옵션을 결정한다. 여기서 두 모드가 갈리면
"local 은 통과하는데 api 는 실패" 같은 모양이 되고, 그 원인이 번역 로직이
아니라 하네스라는 것을 알아내는 데 하루가 든다 — 실제로 갈려 있었다.

의존성 없이 돈다: `python3 scripts/test_preset_options.py`
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
HELPER = HERE / "preset_options.py"

# 배포된 권장 preset 의 실제 모양 (2026-09-26 조회) + 서버가 함께 주는 두 형태.
PAYLOAD = {"presets": [{
    "name": "recommended",
    "label": "권장 옵션",
    "args": ["--diff-granularity", "block", "--glossary-mode", "service",
             "--max-load-ratio", "4", "--table-rows", "--no-skip-full-table",
             "--load-exclude-tables", "--skip-anchor-only", "--assign-anchors",
             "--align-headings", "--list-items", "--unit-preserve"],
    "opts": {"diff_granularity": "block", "glossary_mode": "service",
             "max_load_ratio": "4", "table_rows": True,
             "skip_full_table": False, "load_exclude_tables": True,
             "skip_anchor_only": True, "assign_anchors": True,
             "align_headings": True, "list_items": True,
             "unit_preserve": True},
    "env_only_flags": {"--engine": ["TRANSLATE_TRANSLATE_ENGINE"],
                       "--model": ["TRANSLATE_ANTHROPIC_MODEL",
                                   "TRANSLATE_CLAUDE_CODE_MODEL"]},
}]}

FAILED = []


def check(name, cond, detail=""):
    print(f"  {'ok  ' if cond else 'FAIL'}  {name}")
    if not cond:
        FAILED.append(f"{name}{(' — ' + detail) if detail else ''}")


def run(payload, *args):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(payload, f)
        path = f.name
    r = subprocess.run([sys.executable, str(HELPER), "--payload", path, *args],
                       capture_output=True, text=True)
    return r


def main():
    print("preset_options.py")

    # ── 1) 두 모드가 같은 옵션을 말한다 ──────────────────────────────────
    api = json.loads(run(PAYLOAD, "--mode", "api", "--pr-url", "u").stdout)
    local = run(PAYLOAD, "--mode", "local").stdout
    args_line = [l for l in local.splitlines() if l.startswith("PRESET_ARGS=")][0]
    argv = args_line[len("PRESET_ARGS=("):-1].split()

    # preset 이 끈 것은 api 에서 명시 false, local 에서 --no- 형태여야 한다.
    check("skip-full-table: api 는 명시 false", api["skip_full_table"] is False)
    check("skip-full-table: local 은 --no- 형태", "--no-skip-full-table" in argv)
    check("load guard 가 preset 값(4)", api["max_load_ratio"] == "4"
          and "4" in argv)
    for flag, field in (("--load-exclude-tables", "load_exclude_tables"),
                        ("--unit-preserve", "unit_preserve"),
                        ("--list-items", "list_items"),
                        ("--table-rows", "table_rows")):
        check(f"{flag} 가 두 모드 모두에", flag in argv and api.get(field) is True)

    # ── 2) env 전용 플래그는 argv 에 절대 들어가지 않는다 ────────────────
    # `translate_pr.py` 에 그 이름의 플래그가 없어서 argparse 가 죽는다.
    local2 = run(PAYLOAD, "--mode", "local", "--model", "claude-haiku-4-5",
                 "--engine", "claude-code").stdout
    argv2 = [l for l in local2.splitlines() if l.startswith("PRESET_ARGS=")][0]
    check("local argv 에 --model 이 없다", "--model" not in argv2)
    check("local argv 에 --engine 이 없다", "--engine" not in argv2)
    check("--model 은 env 둘로 (CLI·API translator 가 서로 다른 것을 읽는다)",
          "export TRANSLATE_ANTHROPIC_MODEL=claude-haiku-4-5" in local2
          and "export TRANSLATE_CLAUDE_CODE_MODEL=claude-haiku-4-5" in local2)
    check("--engine 은 env 로", "export TRANSLATE_TRANSLATE_ENGINE=claude-code" in local2)
    # api 모드에서는 반대로 **body 필드**로 간다.
    api2 = json.loads(run(PAYLOAD, "--mode", "api", "--model", "claude-haiku-4-5",
                          "--engine", "claude-code").stdout)
    check("api body 는 model/engine 을 필드로",
          api2["model"] == "claude-haiku-4-5" and api2["engine"] == "claude-code")

    # ── 3) override 는 preset 을 덮는다 (중복 전달 금지) ─────────────────
    over = run(PAYLOAD, "--mode", "local",
               "--tm-top-k", "1", "--workers", "2").stdout
    argv3 = [l for l in over.splitlines() if l.startswith("PRESET_ARGS=")][0]
    check("override 가 한 번만 실린다", argv3.count("--tm-top-k") == 1)
    check("override 값이 반영된다", "--tm-top-k 1" in argv3)

    # ── 4) 옛 대시보드는 조용히 폴백하지 않고 실패한다 ───────────────────
    old = {"presets": [{"name": "recommended", "patch": {"tx-granularity": "block"}}]}
    r = run(old, "--mode", "api")
    check("args/opts 없으면 하드 실패", r.returncode != 0, f"rc={r.returncode}")
    check("실패 메시지가 필요한 빌드를 짚는다", "#1015" in r.stderr, r.stderr[:120])

    # ── 5) 없는 preset 이름은 있는 목록을 보여 준다 ──────────────────────
    r = run(PAYLOAD, "--mode", "api", "--preset", "nope")
    check("없는 preset 은 목록과 함께 실패",
          r.returncode != 0 and "recommended" in r.stderr, r.stderr[:120])

    print()
    if FAILED:
        print(f"FAILED {len(FAILED)}건")
        for f in FAILED:
            print(f"  - {f}")
        return 1
    print("all ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
