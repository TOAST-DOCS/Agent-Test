# e2e 의 모든 모델 호출을 haiku 로 — `source` 해서 쓴다 (실행하지 않는다).
#
#   source scripts/all-haiku.env.sh                 # 그 셸에서 돌리는 e2e 전부
#   scripts/e2e-suite.sh --all-haiku --translate local all   # suite 가 대신 source
#
# 기본 e2e 는 번역(`translate_pr.py`)만 haiku 로 돌리고 나머지는 운영과 같은 모델을
# 쓴다 — 한글 검수·깨진 표 정비·전체 재번역·align heading 번역은 cloud-translate
# `.env` 의 sonnet, align-v2 outline 분류는 opus, 하네스 판정은 fable 이다.
# 2026-10-14 suite 실측으로 그 넷이 호출 156/376 · 비용 $54.5/$87.9 (62%) 였다.
# 이 파일은 그 전부를 haiku 로 바꾼다 — **운영과 다른 조건**이므로 결과를 보고할 때
# "all-haiku" 로 돌렸다고 적는다. 모델 의존 판정(예: template-tags 의 태그 구조
# 충실도)은 haiku 에서 다르게 나올 수 있다.
#
# 덮지 못하는 것: webhook 계열 plan(webhook · webhook-concurrent · webhook-lag-order ·
# workflow-ignore)과 `--translate api` 의 Jenkins 잡은 배포된 파이프라인이 운영 모델로
# 돈다 — 로컬 env 가 닿지 않는다.
#
# cloud-translate 쪽은 pydantic-settings 라 프로세스 env 가 `.env` 보다 우선한다.

export E2E_ALL_HAIKU=1
export E2E_HAIKU_MODEL="claude-haiku-4-5"

# CLI 엔진(claude-code) 의 모든 호출 — 번역 · 한글 검수 · 깨진 표 정비 · 빈 번역 채우기 ·
# 한글 잔존 · 전체 재번역 · fix_headings 의 heading 번역 · 링크 정정 LLM 2차.
export TRANSLATE_CLAUDE_CODE_MODEL="$E2E_HAIKU_MODEL"
# 같은 도구를 api 엔진으로 돌릴 때 (shared.config.anthropic_model).
export TRANSLATE_ANTHROPIC_MODEL="$E2E_HAIKU_MODEL"
# pre-align align-v2 outline 분류 (pre-align/align_verify.py — 기본 claude-opus-4-5).
export TRANSLATE_DEBUG_VERIFY_MODEL="$E2E_HAIKU_MODEL"
# 하네스가 직접 부르는 `claude -p` 판정 (e2e-korean-review.sh 등 — 기본 fable).
export E2E_JUDGE_MODEL="$E2E_HAIKU_MODEL"   # 별칭 "haiku" 는 최신(haiku-5-5)으로 풀려 버전이 갈린다
# check_term_pin.py 의 probe 모델.
export TERM_PIN_PROBE_MODEL="$E2E_HAIKU_MODEL"
