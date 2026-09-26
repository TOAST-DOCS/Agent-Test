#!/usr/bin/env python3
"""대시보드의 번역 preset 을 e2e 두 실행 모드의 인자로 바꾼다.

**왜 있나.** `e2e-align-and-translate.sh` 는 "권장 preset" 이라고 말하면서 그
목록을 두 벌 하드코딩하고 있었다 — `--translate local` 용 CLI 플래그와
`--translate api` 용 JSON body. 두 벌이라 서로도 갈리고, 배포된 preset 과도
갈렸다. 실측 (2026-09-26):

    옵션                   배포된 권장 preset   e2e 하드코딩
    max-load-ratio         4                    2
    skip-full-table        false                true      ← 정반대
    load-exclude-tables    true                 (없음)
    unit-preserve          true                 (기본 off)

즉 e2e 는 운영이 실제로 쓰는 조건을 한 번도 태우지 않고 "권장 preset 으로
돌렸다" 고 보고하고 있었다. 이 모듈은 그 목록을 **대시보드에서 받아** 두 모드의
인자를 만든다. 매핑을 여기 다시 적지 않는 것이 요점이다 — 적는 순간 그게 네
번째 사본이 된다.

**입력**은 `GET /api/translate/presets` 응답 그대로다. 서버가 같은 preset 을 세
형태로 실어 준다 (cloud-translate #1015):

    patch           SPA 다이얼로그용 UI element id — 여기서는 안 쓴다
    opts            /api/translate body 필드      → api 모드
    args            저장된 CLI 형태 그대로        → local 모드
    env_only_flags  args 중 CLI 가 받지 않는 것 → 그 값을 싣는 env 이름

`--engine`·`--model` 이 그 env 전용 플래그다. api 경로는 Jenkins 파라미터가
env 로 풀어 주지만 `translate_pr.py` 에는 그 이름의 argparse 플래그가 없어서,
argv 에 그대로 넣으면 죽는다. 목록을 서버가 주므로 여기서 이름을 외우지 않는다.

**override 는 preset 을 덮는다.** e2e 는 비용을 눌러야 해서 model·tm-top-k·
chunk-workers 를 운영값과 다르게 쓴다 (haiku / 1 / 2 vs sonnet / 10 / .env).
그 셋은 preset 이 아니라 e2e 의 선택이므로 호출부가 넘기고, 여기서는 preset
위에 얹기만 한다 — 그래야 "무엇이 preset 이고 무엇이 e2e 의 선택인지" 가 한
곳에서 읽힌다.
"""
from __future__ import annotations

import argparse
import json
import shlex
import sys


def pick_preset(payload, name="recommended"):
    """응답에서 preset 하나를 고른다. 없으면 이름을 들어 실패한다."""
    presets = (payload or {}).get("presets") or []
    for p in presets:
        if p.get("name") == name:
            return p
    have = ", ".join(sorted(str(p.get("name") or "?") for p in presets)) or "(없음)"
    raise SystemExit(
        f"error: preset '{name}' 을 찾을 수 없습니다. 대시보드가 준 목록: {have}")


def load_from_checkout(catalog_dir):
    """cloud-translate 체크아웃의 preset 카탈로그를 **직접** 읽어 payload 를 만든다.

    HTTP 대신 이 길이 있는 이유는 **검증 대상이 어디냐** 다. 배포 파이프라인을
    태우는 스크립트는 배포된 대시보드에 물어야 맞지만, 로컬 `translate_pr.py`
    를 태우는 스크립트(`e2e-concurrent-prs.sh` · `e2e-translation-lag-order.sh`)
    는 그 체크아웃의 카탈로그를 읽는 편이 짝이 맞다 — 로컬 코드를 돌리면서
    옵션만 배포본에 물으러 갈 이유가 없다. 그리고 그 둘은 **대시보드 의존이 0**
    인 것이 문서화된 성질이라(헤더 주석), HTTP 를 넣으면 대시보드와 무관한
    머지 순서 테스트가 대시보드가 죽으면 못 돌게 된다.

    운영값은 env override(`TRANSLATE_TRANSLATE_PRESETS`)에 있고 그 출처는
    `<dir>/dashboard/.env` 다. **없으면 실패한다** — built-in 으로 조용히
    떨어지면 정확히 옛 값(`--max-load-ratio 2` · `--skip-full-table`)을 쓰게
    되어, 이 모듈이 없애려던 드리프트를 되살린다. 실측 2026-09-26 기준 그
    파일의 값은 배포본과 바이트 단위로 같다.
    """
    import os
    import re
    from pathlib import Path

    d = Path(catalog_dir).expanduser().resolve()
    dash = d / "dashboard"
    if not (dash / "api" / "translate_presets.py").exists():
        raise SystemExit(
            f"error: preset 카탈로그가 없습니다: {dash}/api/translate_presets.py")

    envf = dash / ".env"
    raw = None
    if envf.exists():
        for line in envf.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"\s*TRANSLATE_TRANSLATE_PRESETS\s*=\s*(.*)$", line)
            if m:
                raw = m.group(1).strip()
                if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"":
                    raw = raw[1:-1]
                break
    if not raw:
        raise SystemExit(
            f"error: {envf} 에서 TRANSLATE_TRANSLATE_PRESETS 를 찾지 못했습니다.\n"
            "       그 값이 운영 preset 의 정본이고, 없이 읽으면 built-in(옛 값:\n"
            "       max-load-ratio 2 · skip-full-table ON)으로 떨어지므로 진행하지 않습니다.")

    sys.path.insert(0, str(dash))
    os.environ["TRANSLATE_TRANSLATE_PRESETS"] = raw
    from api.translate_presets import ui_translate_presets  # noqa: E402
    return {"presets": ui_translate_presets()}


def require_new_shapes(preset):
    """`args`/`opts` 가 없으면 **조용히 폴백하지 않고** 실패한다.

    `patch`(UI id) 에서 되짚는 폴백을 두면 매핑 사본이 하나 더 생기고, 그게
    정확히 이 모듈이 없애려는 것이다. 그리고 조용히 폴백하면 옛 대시보드에
    대고 돌린 e2e 가 '권장 preset 으로 돌았다' 고 말하면서 또 다른 값을 쓰게
    된다 — 지금까지의 결함과 같은 모양이다.
    """
    missing = [k for k in ("args", "opts") if k not in preset]
    if missing:
        raise SystemExit(
            "error: 대시보드 preset 응답에 {} 이(가) 없습니다.\n"
            "       cloud-translate #1015 이후 빌드가 필요합니다 "
            "(그 전 빌드는 UI 형태 `patch` 만 내보냅니다).".format(
                "/".join(missing)))


def _split_env_only(args, env_only_flags):
    """argv 를 (CLI 로 넘길 args, env dict) 로 가른다.

    `env_only_flags` 는 {플래그: [env 이름, ...]} — `--model` 처럼 env 를 둘
    세팅해야 하는 경우가 있다 (CLI 엔진은 TRANSLATE_CLAUDE_CODE_MODEL 만, API
    translator 는 TRANSLATE_ANTHROPIC_MODEL 만 읽어서 하나만 주면 다른 경로가
    조용히 .env 기본값으로 돈다 — Jenkinsfile 의 MODEL_ENV 와 같은 이유).
    """
    cli, env = [], {}
    i = 0
    while i < len(args):
        flag = args[i]
        names = env_only_flags.get(flag)
        if names and i + 1 < len(args):
            for n in names:
                env[n] = args[i + 1]
            i += 2
            continue
        cli.append(flag)
        i += 1
    return cli, env


def _apply_overrides_to_args(cli_args, overrides):
    """preset args 위에 e2e override 를 얹는다 (같은 플래그는 교체)."""
    out, i = [], 0
    over_flags = set(overrides)
    while i < len(cli_args):
        flag = cli_args[i]
        # 값 플래그인지 판단할 표가 없으므로, override 대상만 값까지 걷어낸다.
        if flag in over_flags:
            i += 2 if i + 1 < len(cli_args) and not cli_args[i + 1].startswith("--") else 1
            continue
        out.append(flag)
        i += 1
    for flag, val in overrides.items():
        if val is None or val == "":
            continue
        out.extend([flag, str(val)])
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--payload",
                     help="GET /api/translate/presets 응답 JSON 파일 ('-' = stdin)")
    src.add_argument("--catalog-dir",
                     help="cloud-translate 체크아웃 경로 — 대시보드를 거치지 않고 "
                          "그 카탈로그를 직접 읽는다 (로컬 전용 e2e 용)")
    ap.add_argument("--preset", default="recommended")
    ap.add_argument("--mode", required=True, choices=("api", "local"))
    ap.add_argument("--pr-url", default="", help="api 모드 body 의 pr_url")
    ap.add_argument("--pipeline-branch", default="")
    # e2e 고유의 비용 억제 override — preset 이 아니라 e2e 의 선택이다.
    ap.add_argument("--model", default="")
    ap.add_argument("--engine", default="")
    ap.add_argument("--tm-top-k", default="")
    ap.add_argument("--chunk-workers", default="")
    ap.add_argument("--workers", default="")
    ap.add_argument("--guidelines-variant-en", default="")
    ap.add_argument("--guidelines-variant-ja", default="")
    # plan 이 요구하는 추가 플래그 (local 전용; api 는 필드가 없어 호출부가 막는다)
    ap.add_argument("--extra-arg", action="append", default=[],
                    help="local 모드 argv 에 그대로 덧붙일 플래그")
    a = ap.parse_args(argv)

    if a.catalog_dir:
        payload = load_from_checkout(a.catalog_dir)
    else:
        raw = (sys.stdin.read() if a.payload == "-"
               else open(a.payload, encoding="utf-8").read())
        payload = json.loads(raw)
    preset = pick_preset(payload, a.preset)
    require_new_shapes(preset)

    overrides = {
        "--model": a.model, "--engine": a.engine,
        "--tm-top-k": a.tm_top_k, "--chunk-workers": a.chunk_workers,
        "--workers": a.workers,
        "--guidelines-variant-en": a.guidelines_variant_en,
        "--guidelines-variant-ja": a.guidelines_variant_ja,
    }
    overrides = {k: v for k, v in overrides.items() if v}

    if a.mode == "api":
        # body 필드는 서버가 준 `opts` 가 정본. override 는 같은 필드명으로 얹는다.
        body = dict(preset["opts"])
        field_of = {
            "--model": "model", "--engine": "engine", "--tm-top-k": "tm_top_k",
            "--chunk-workers": "chunk_workers", "--workers": "workers",
            "--guidelines-variant-en": "guidelines_variant_en",
            "--guidelines-variant-ja": "guidelines_variant_ja",
        }
        for flag, val in overrides.items():
            body[field_of[flag]] = str(val)
        if a.pr_url:
            body["pr_url"] = a.pr_url
        if a.pipeline_branch:
            body["pipeline_branch"] = a.pipeline_branch
        print(json.dumps(body, ensure_ascii=False, indent=2))
        return 0

    # local — preset args 에서 env 전용 플래그를 걷어내고 override 를 얹는다.
    cli_args, env = _split_env_only(list(preset["args"]),
                                    preset.get("env_only_flags") or {})
    env_only = preset.get("env_only_flags") or {}
    for flag, val in list(overrides.items()):
        if flag in env_only:
            for n in env_only[flag]:
                env[n] = str(val)
            overrides.pop(flag)
    cli_args = _apply_overrides_to_args(cli_args, overrides)
    cli_args.extend(a.extra_arg)
    # shell eval 용 — `env` 는 `K=V` 줄, `args` 는 quote 된 한 줄.
    for k in sorted(env):
        print(f"export {k}={shlex.quote(env[k])}")
    print("PRESET_ARGS=({})".format(" ".join(shlex.quote(x) for x in cli_args)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
