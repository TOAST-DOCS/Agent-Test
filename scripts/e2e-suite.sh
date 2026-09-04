#!/usr/bin/env bash
#
# e2e 전체 suite 러너 — 여러 plan 을 순차 실행하고 결과를 요약한다.
#
#   scripts/e2e-suite.sh [--translate api|local] [--engine api|cli] [--model haiku|sonnet|opus] \
#                        [--verify py|fable] [--no-reuse-align] \
#                        [--translate-pipeline-branch <jenkins-child>] \
#                        [--sleep-between <sec>] [plan ...]
#
#   --sleep-between <sec> — plan 과 plan 사이 대기 (기본 0). Jenkins agent 의
#       claude CLI (OAuth) 가 연속 실행으로 usage limit 에 걸려 align/ko-review
#       가 무더기 is_error 로 무너지는 것(2026-08-13 08:15Z 실측: align build
#       324=에러0 → 325/326=에러84)을 피하려면 3600(1시간) 권장. 마지막 plan
#       뒤에는 자지 않는다.
#
# plan 미지정 시 기본: webhook round1 table-suite markup-churn
#   webhook     — GitHub webhook 라우팅 검증. base=alpha 로 PR 을 열어
#                 pull_request/opened → Jenkins ko-review, PR merge →
#                 pull_request/closed → Jenkins translate 트리거를 dashboard
#                 /api/jobs 로 확인. 다른 plan 과 달리 e2e-align-and-translate.sh
#                 가 아니라 e2e-webhook.sh 를 실행. 기대: exit 0.
#                 ~1분. base=alpha 를 직접 쓰므로 매 실행마다 alpha 에 마커
#                 커밋 1개가 추가되지만 restore-alpha-origin 이 다음 e2e 에서
#                 정리한다.
#   korean-review — dashboard /api/ko-review 잡의 산출물(요약 리뷰 본문 규격,
#                 인라인 코멘트, ```suggestion``` 블록) 을 검증. e2e-align-and-
#                 translate.sh 가 아니라 e2e-korean-review.sh 를 실행.
#                 세션 브랜치에서 ko 변형 PR 하나만 만들고 검수 잡을 태워
#                 결과 리뷰의 구조 + fable 의미 품질을 확인 (align/translate
#                 단계는 건너뜀). 기대: exit 0. ~15~30분.
#   anchor-audit  — 한글 검수 **다음에** 도는 anchor id 후속 검증
#                 (korean-review/app/anchor_audit.py). 금지 목록 6종을 세션
#                 브랜치 픽스처로 재현한 PR 을 만들고, 마커 코멘트가 각 항목을
#                 제 섹션에 잡는지 · 대조군/권장 경로를 조용히 지나가는지 ·
#                 검수 리뷰가 먼저 게시되는지 · 지적이 해당 줄의 인라인 코멘트로
#                 달리는지(diff 밖이면 가장 가까운 변경 줄로) · 재실행에 요약·
#                 인라인 어느 쪽도 쌓이지 않는지를 21개 규칙으로 판정. 결정적
#                 점검이라 기대값은 하나 — exit 0 + 21/21. ~3분(검수 LLM 포함).
#   row-drop-repro — cloud-translate PR #283 회귀 최소 재현. version-guide.md 의
#                 en/ja 가 `1.202602.1` 행을 결여한 stale 상태를 base 브랜치에
#                 stale-ify 커밋으로 조성한 뒤, 이웃 문단만 짧게 수정해
#                 load/ko-diff 비율 cap 초과 → LLM-patch fallback 경로를 태운다.
#                 대조군으로 overview.md 에 정상 문단 추가. 결함 상태에서는
#                 en/ja 가 stale 행을 유지(FAIL), 수정 배포 후에는 backfill
#                 또는 todo-stub 으로 해소(exit 0). exit 3 도 정상 허용.
#   row-drop-repro-noreconcile
#               — 위와 같은 ko 픽스처를 **표 행 reconcile OFF** 로 돌리는 변형
#                 (--no-table-reconcile). reconcile 이 켜져 있으면 stale 행이
#                 splice 이전에 backfill 되어 부하가 cap 아래로 떨어지고
#                 **LLM-patch fallback 경로에 아예 도달하지 못한다** (2026-08-23
#                 실측: 8 plan 전체 LLM-patch 0건). 끄면 행 splice 의 1:1 가드가
#                 깨져 full 로 떨어지고 skip-full-table 가드가 그 문서를
#                 제외하려다 LLM-patch fallback 을 태운다 — 그 경로가 검증 대상.
#                 dashboard /api/translate 에 table_reconcile 필드가 없어
#                 **--translate local 전용** (api 모드와 함께 주면 하드 실패).
#                 판정: exit 0/3 허용, 단 로그에 LLM-patch fallback 이 0건이면
#                 suite 실패 — 경로를 안 태운 실행은 검증한 게 없으므로.
#
#                 **2026-08-24 실측: 이 가설은 틀렸다 — reconcile 을 꺼도
#                 LLM-patch 에 도달하지 못한다.** 그래서 아직 `all` 에서 제외한다.
#                 실제로 관찰된 것 (PR #650):
#                   - `load signal: … 17.0x > 2.0x, 43% of the document;
#                     translating anyway` — 부하 가드는 **정보성**이라 파일을
#                     제외하지 않는다 (worker.py 의 skipped-load 는 legacy).
#                     LLM-patch 의 과거 트리거 하나가 이미 사라져 있었다.
#                   - `Pre-aligned anchor splice: translated 1 of 4 sections` —
#                     ko 변형(edit_body)이 표가 **아닌** 옆 문단을 건드리므로
#                     표가 속한 섹션은 anchor splice 가 그대로 재사용한다. 표
#                     전체를 재번역할 일이 없어 skip-full-table 가드가 안 걸리고,
#                     LLM-patch 는 그 가드의 skip 뒤에만 호출된다.
#                   - 결과는 #283 결함의 정직한 재현: en/ja version-guide 표#1 이
#                     ko 5행 대비 4행, 식별자 `1.202602.1` 유실 → 구조 검사 FAIL.
#                     즉 이 변형이 실제로 증명한 것은 "**reconcile 이 그 유실을
#                     막고 있다**" 는 것이고, 그것만으로도 회귀 가치가 있다.
#                   - `--no-table-reconcile` 은 완전성 backstop(`_guard_rows` →
#                     `_stub_incomplete_tables`)까지 함께 끄는 통합 kill switch 다
#                     (translator.py 의 docstring 이 그렇게 규정). 그래서
#                     todo-stub 도 0건이고, 유실은 e2e 자체 checker 가 잡았다.
#                 LLM-patch 를 태우려면 ko 변형이 **표 자신의 섹션 안**을 고쳐서
#                 그 표 단위가 전량 재번역 대상이 되어야 한다 (그때 target 행 수가
#                 달라 skip-full-table 이 걸리고 LLM-patch 가 호출된다) —
#                 create-translate-test-pr.sh 에 그 변형을 추가하는 별도 작업.
#   llm-patch   — **skip-full-table 가드 -> LLM-patch fallback** 경로 검증.
#                 지금 LLM-patch 를 호출하는 트리거는 이 가드 **하나뿐**이다 —
#                 부하 가드는 더 이상 파일을 제외하지 않고 (worker.py 의
#                 skipped-load 는 legacy) 정보성 `load signal:` 로만 알린다.
#                 픽스처: en/ja `version-guide.md` 의 표를 **통째로** 제거하고
#                 ko 는 그 표의 첫 데이터 행을 수정 (change_table_row) — 그러면
#                 "ko unit 에 표가 있는데 짝 unit 엔 없고, base ko 엔 있던 표"
#                 조건이 성립해 `full_table_sections=1` 이 되고 그 파일이 skip
#                 되면서 LLM-patch 가 호출된다. measure 모드 무료 dry-run 으로
#                 확인: en/ja 양쪽 1, reconcile on/off 무관(표 개수가 달라
#                 reconcile 이 bail), 대조군(stale 없음)은 0.
#                 그래서 --translate api/local 양쪽에서 동작한다.
#                 판정: exit 0/3 허용 (LLM-patch 가 declined 하면 파일이 제외되어
#                 구조 검사가 FAIL 할 수 있고, 그 자체가 #585 류 결함의 신호다),
#                 단 로그에 LLM-patch 호출이 0건이면 **suite 실패** — 경로를 안
#                 태운 실행은 검증한 게 없다. verdict 에 llm-patch=/ok=/declined=
#                 /skip-full-table= 를 붙여 fallback 이 무엇을 판단했는지 남긴다.
#                 llm-patch=0 의 원인은 두 가지고 두 카운터가 그걸 가른다:
#                   skip-full-table=0 → 트리거가 사라짐 (코드 회귀 의심)
#                   skip-full-table>0 → 그 환경에서 폴백이 꺼져 있음 (설정)
#                 api 모드도 유효하다 — 오히려 local 모드는 --llm-patch-fallback 을
#                 강제로 켜므로 "프로덕션에서 폴백이 꺼졌다" 를 감지할 수 없고,
#                 api 모드만 그걸 잡을 수 있다 (dashboard 가 이 플래그를 보내지
#                 않아 배포 잡 .env 값이 그대로 드러나기 때문).
#   fill-stubs  — 빈 번역 채우기(translate_fill_stubs.py) 검증
#                 (e2e-fill-stubs.sh). pre-align 이 남긴
#                 `<!-- TODO: translate* -->` stub 을 ko 의 같은 <a id> 섹션으로
#                 채우는 경로 — PR 의 ko diff 가 아니라 브랜치 전수 스캔에서
#                 출발하고 diff 스플라이스를 전혀 타지 않아 다른 plan 이
#                 커버하지 못한다. 픽스처로 body stub · heading stub · **id 없는
#                 stub(음성 대조군)** 을 심고, 채운 섹션 밖이 바이트 동일한지와
#                 id 없는 stub 이 건너뛰어졌는지를 바이트 비교로 판정 (LLM 판정
#                 없음). 기본 --translate local (모델 호출 2회, ~2분);
#                 --translate api 는 dashboard /api/fill-empty → Jenkins 경로를
#                 태운다 (그 모드에선 dry-run 규칙 1건이 SKIP). 기대: exit 0.
#   concurrent  — 같은 ko 파일을 만지는 동시 PR 시나리오 (e2e-concurrent-prs.sh).
#                 A 생성 → B 생성 → B 머지·번역·번역 머지 → A 머지 → A 번역
#                 순서에서, A 번역이 B 의 신규 섹션·표 행을 지우지 않는지
#                 검증 (merge-commit ref 결함). 다른 plan 과 달리 dashboard/
#                 Jenkins 를 쓰지 않고 **항상 로컬 translate_pr.py** 로 번역
#                 하므로 --translate api 를 줘도 로컬 실행이다 (CLOUD_TRANSLATE_DIR,
#                 기본 ~/works/cloud-translate). 기대: exit 0 (RESULT: PASS).
#                 exit 1 = B 콘텐츠 유실(버그 재현), 2 = 하네스 오류.
#   round1      — 일반 종합 (heading/anchor/섹션/문단/표 기본 변형 15항목).
#                 기대: exit 0 (전 파일 PASS).
#   table-suite — 표 변형 종합 + stale 결함 재현 (stale-ify 커밋 포함).
#                 기대: 번역 로직에 table-row reconcile(PR #290)이 있으면 exit 0,
#                 없으면 exit 3 (version-guide/release-notes FAIL).
#   markup-churn— 코스메틱 마크업 churn(펜스 info string, <br/>, 헤딩 뒤 빈 줄,
#                 Jinja 태그 whitespace 제어) + 소수 내용 변경. load guard 가
#                 정상 리뷰 PR 을 runaway 로 오판해 파일을 제외하던 것을 재현
#                 (Storage-Object-Storage#181/#185, Storage-Online-NAS#92).
#                 기대: exit 0 **이고** 로그에 load guard skip 이 0건.
#                 exit code 만으로는 판별되지 않는다 — 미러링이 없어도 일부
#                 파일은 floor 아래라 통과해 PR 이 만들어지기 때문. 그래서 이
#                 러너가 로그에서 mirrored=/guard-skips= 를 세어 verdict 에 붙이고,
#                 guard-skips 가 0 이 아니면 suite 실패로 잡는다. 단 그 두
#                 카운터는 --translate local 에서만 의미가 있다 (api 모드는
#                 번역 로그가 Jenkins 쪽) — api 모드의 실제 증거는 번역 PR
#                 본문의 "제외된 파일" 섹션이라 pr-excl= 로 따로 센다.
#                 구조적으로는 checker 규칙 (7) 이 "ko 에 맨몸 <br> 이 0 인데
#                 en/ja 에 남아있으면 FAIL" 로 미러링 미동작을 직접 잡는다.
#                 기본 plan 집합에 포함된다.
#   retranslate — public-api.md 전체 재번역 변형 (e2e-retranslate-align-and-
#                 translate.sh). /api/translate/file (DIFF_MODE=full) 경로 검증 —
#                 다른 plan 이 커버하지 않는 유일한 API. --translate local 이면
#                 그 단계도 로컬 translate_file.py (--commit-to-branch,
#                 TRANSLATE_DIFF_MODE=full) 로 실행된다. 기대: exit 0.
#   split-docs  — 릴리스 노트 연도별 분리 (e2e-split-docs.sh). alpha 의
#                 release-notes.md (91개 날짜 섹션 × 11개 연도) 를 그대로 잘라
#                 include-markdown 부모 + 연도 파일로 만들고, **왕복 검증**
#                 (include 펼침 == 원본) 과 anchor 순서 보존을 바이트로 판정.
#                 모델을 전혀 쓰지 않는 리팩터라 --engine/--model 은 무의미.
#                 기대: exit 0 / SPLIT_DOCS: OK.
#   fix-tables  — 깨진 표 정비 (e2e-fix-tables.sh). alpha 상주 픽스처
#                 {ko,en,ja}/fix-tables-sample.md 에서 **ko 와 표가 어긋난
#                 section** 세 모양(표가 사라짐 · 첫 열이 덮임 · 행 누락)을 ko 로
#                 다시 만들고, 대조군 셋(정상 표 · 식별자 없는 표 · 앵커 없는
#                 하위 heading)은 손대지 않는지 바이트/구조 비교로 판정.
#                 fill-stubs 의 형제 plan 이지만 판정이 반대다 — 그쪽은 비어 있는
#                 section 을 채우고 이쪽은 있는데 깨진 section 을 다시 만든다.
#                 기본 --translate local; --translate api 는 dashboard
#                 /api/fix-tables → Jenkins 경로를 태운다 (그 모드에선 dry-run
#                 규칙 1건이 SKIP). 기대: exit 0 / FIX_TABLES: OK.
#   fix-links   — 링크 정정 (e2e-fix-links.sh). alpha 상주 픽스처
#                 {ko,en,ja}/fix-links.md 의 규칙 6종을 정정하고 대조군·펜스·
#                 확인 불가 링크는 보존/보고하는지 바이트로 판정.
#                 /link-check 의 ⭐ 권장 옵션(문서 전체 · DRY-RUN 해제 ·
#                 engine=env · lang-parity+cross-context)으로 돌린다 — 이 잡의
#                 유일한 위험 지점이 DRY-RUN 해제라, e2e 가 반드시 그 경로를
#                 지나가야 한다. 기대: exit 0 / FIX_LINKS: OK.
#   preserve    — preserve-existing 반영 검증 (e2e-preserve-existing.sh).
#                 full 재번역 + --preserve-existing 이 실제로 걸렸는지를 로그가
#                 아니라 **산출물**로 본다: 한 섹션의 ko 산문만 바꾼 뒤 나머지
#                 섹션의 en/ja 가 바이트 동일하게 남는지. 픽스처는 실행 시점에
#                 생성되며 CLI 의 @file 한도(25,000 토큰)를 반드시 넘는다 —
#                 넘지 않으면 수정 전 코드도 통과해 회귀를 못 잡는다. 대조군
#                 (--no-preserve-existing) 런과 churn 을 비교해 바이트 동일이
#                 preserve 때문임을 확정한다. 기대: exit 0 / PRESERVE: OK.
#                 **all 에서 제외 (2026-09-04)** — 이 plan 은 CLI 엔진의 preserve
#                 섹션 슬라이스(cloud-translate #811/#817) 를 전제로 판정 (4)(5)
#                 를 두었는데, 재번역을 api 엔진으로 처리하기로 하고 그 PR 들을
#                 닫아서 main 에 대해 항상 실패한다. 스크립트는 그대로 두고
#                 명시 지정(`scripts/e2e-suite.sh preserve`)으로만 실행.
#   table-malformed — 표 reconcile 의 **선정** 가드 (e2e-table-malformed.sh).
#                 세션 base 에 표 3개를 시드한다: (A) ko 셀에 실제 줄바꿈이
#                 들어가 표가 끊긴 것, (B) 세 언어가 같은 스키마인데 대상 행
#                 하나만 파이프가 빠진 것, (C) 대조군 — 진짜로 행이 결여된
#                 정상 keyed 표. ko 는 **표를 건드리지 않는 산문 1줄** 만
#                 바꾼다 (reconcile 이 splice 상류에서 문서 전체 표를 훑는다는
#                 게 결함 성립 조건이므로). 기대: A 는 skip 되고 세 행이 전부
#                 남고, B 는 바이트 그대로, C 는 여전히 backfill.
#                 재현하는 사고: DDoS-Guard l7-ddos-settings-guide (A — en 19행
#                 · ja 16행이 결정적으로 삭제될 상태) / OCR#177 빌드 #370
#                 (B — 최소값 비교가 열 동기화를 오선정, 호출 4회 낭비).
#                 기대: exit 0 / RESULT: OK.
#   round2      — 전제 조건(직전 round1 의 ko/번역 PR 이 base 에 머지되어 있음)이
#                 필요해 suite 기본/all 에서 제외. 명시 지정 시에만 실행.
#
# 별칭:
#   all         — round2 / row-drop-repro-noreconcile / preserve 를 제외한 plan 전체
#                 = webhook korean-review anchor-audit round1 table-suite
#                   row-drop-repro llm-patch markup-churn retranslate concurrent
#                   fill-stubs split-docs fix-links fix-tables table-malformed
#                 round2 는 round1 후처리(수동 머지)가 필요해 제외 —
#                 필요하면 명시적으로 `scripts/e2e-suite.sh all round2` 로 이어붙임.
#                 preserve 는 전제(CLI 섹션 슬라이스)가 폐기되어 제외 — 위 plan 설명 참고.
#
# 각 plan 은 자체 e2e 세션 브랜치(e2e/<ts>)에서 돌므로 서로 간섭하지 않지만,
# 같은 작업 트리를 쓰므로 반드시 순차 실행 (이 러너가 보장). 개별 실행 로그는
# /tmp/e2e-suite-<ts>/<plan>.log 에 남는다.
#
# --translate local 이면 **모든 단계**를 CLOUD_TRANSLATE_DIR (기본
# ~/works/cloud-translate) 의 스크립트로 실행한다 — 미머지 브랜치 검증용.
# 단계별 로컬 대응물:
#   fix-heading-syntax → pre-align/fix_fence.py + pre-align/fix_heading_syntax.py
#   align              → pre-align/fix_headings.py
#   ko-review          → korean-review/review_pr.py
#   translate          → translate/translate_pr.py
#   translate/file     → translate/translate_file.py (retranslate plan)
# **webhook plan 만 예외** — GitHub webhook → 배포된 webhook pod → Jenkins 라는
# 배포 경로 자체가 검증 대상이라 로컬 대응물이 없다. concurrent plan 은 원래부터
# 항상 로컬 translate_pr.py 다.
# 그리고 local 모드도 dashboard 를 **한 곳** 쓴다 — 각 plan 0단계의 webhook 킬
# 스위치 (POST /api/webhooks/repos). 파이프라인 단계가 아니라 배포된 파이프라인이
# 같은 ko 변형 PR 을 동시에 처리하지 않게 막는 스위치라서 local 에서 더 중요하다.
# 그래서 local 모드도 DASHBOARD_BASE_URL / DASHBOARD_API_TOKEN 이 필수다.
# 사전 준비(.env, 워크트리)는 e2e-align-and-translate.sh 헤더 및
# /verify-translate-e2e 참고.
#
# **ko-review 는 table-suite / row-drop-repro / markup-churn 에서 생략된다**
# (e2e-align-and-translate.sh 의 plan 별 기본값). 그 세 plan 의 판정 대상은 번역
# 로직이고, 검수 suggestion 이 표·마크업 픽스처를 흔들면 17단계의 결정론적 판정이
# 흐려진다. round1 은 종합 plan 이라 유지하고, korean-review plan 은 검수 자체가
# 검증 대상이다. 개별 실행 시 --ko-review 로 되돌릴 수 있다.
#
# ── 실행 시간 ────────────────────────────────────────────────────────
# align 프롤로그(2~9단계: restore → fix-heading-syntax → align → 검증 → merge)
# 는 픽스처가 고정이라 plan 마다 같은 결과가 나온다. 그래서 이 러너는 **첫
# align 기반 plan 에서만** 그 단계를 돌리고, 그 결과 스냅샷 브랜치
# (`E2E_ALIGNED_BRANCH=<session>-aligned`) 를 이후 plan 에 --from-aligned 로
# 넘겨 6~8분/plan 을 줄인다. plan 별 세션 브랜치는 여전히 따로 생성되므로
# 서로 간섭하지 않는다. --no-reuse-align 이면 plan 마다 프롤로그를 다시 돈다
# (align/fix-heading-syntax 잡 자체를 여러 번 태우고 싶을 때).
#
# --translate-pipeline-branch <name> 이면 translate 잡을 cloud-translate 의
# Jenkins multibranch child <name> (예: PR-532) 에서 돌린다 — 미머지 PR 의 번역
# 로직을 배포 없이 Jenkins 경로로 검증할 때. align/fix-heading-syntax/ko-review
# 잡과 webhook plan 은 그대로 main 에서 돈다. concurrent plan 은 로컬
# translate_pr.py 를 쓰므로 대신 CLOUD_TRANSLATE_DIR 을 그 브랜치의 워크트리로
# export 해야 같은 코드를 태운다.
#
# 구조 검증(8·17단계)은 scripts/check_docs_align.py 가 결정적으로 수행한다
# (예전 `claude -p --model fable` agentic 검사 대비 plan 당 30~40분 절감).
# --verify fable 로 예전 방식으로 되돌릴 수 있다.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS_ARGS=()
EM_ARGS=()   # retranslate 로 넘길 인자 (--engine/--model/--verify/--translate)
KR_ARGS=()   # korean-review 로 넘길 인자 (--translate 만 의미 있음)
FS_ARGS=()   # fill-stubs 로 넘길 인자 (--translate/--engine/--model)
SD_ARGS=()   # split-docs 로 넘길 인자 (--translate 만 의미 있음 — 모델을 안 쓴다)
FL_ARGS=()   # fix-links 로 넘길 인자 (--translate 만; 옵션은 ⭐ 권장 옵션 고정)
FT_ARGS=()   # fix-tables 로 넘길 인자 (--translate/--engine/--model)
PLANS=()
SLEEP_BETWEEN=0
REUSE_ALIGN=1     # align 프롤로그(2~9단계) 를 첫 plan 에서만 돌리고 재사용
ALIGNED_BRANCH="" # 그 스냅샷 브랜치 (첫 align 기반 plan 의 로그에서 파싱)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sleep-between)
      SLEEP_BETWEEN="$2"; shift 2 ;;
    --engine|--model|--verify)
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2")
      # --verify 는 fable/py 판정 스위치라 fill-stubs 에 없다 (그 plan 은
      # 전부 바이트 비교라 의미 자체가 없음) — engine/model 만 전달.
      [[ "$1" != "--verify" ]] && FS_ARGS+=("$1" "$2")
      [[ "$1" != "--verify" ]] && FT_ARGS+=("$1" "$2")
      shift 2 ;;
    --no-reuse-align)
      REUSE_ALIGN=0; shift ;;
    --translate-pipeline-branch)
      # translate 잡만 특정 cloud-translate 브랜치에서 — align/retranslate 양쪽에 전달
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); shift 2 ;;
    --translate)
      # local = 모든 단계를 로컬 실행 (webhook plan 만 예외 — 배포 경로 자체를
      # 검증하는 plan 이라 로컬 대응물이 없다). 세 스크립트에 모두 전달.
      PASS_ARGS+=("$1" "$2"); EM_ARGS+=("$1" "$2"); KR_ARGS+=("$1" "$2")
      FS_ARGS+=("$1" "$2"); SD_ARGS+=("$1" "$2"); FL_ARGS+=("$1" "$2")
      FT_ARGS+=("$1" "$2"); shift 2 ;;
    --tm-top-k|--chunk-workers)
      PASS_ARGS+=("$1" "$2"); shift 2 ;;
    webhook|korean-review|anchor-audit|round1|round2|row-drop-repro|row-drop-repro-noreconcile|llm-patch|table-suite|markup-churn|retranslate|concurrent|fill-stubs|split-docs|fix-links|fix-tables|table-malformed|preserve)
      PLANS+=("$1"); shift ;;
    all)
      # round2 는 round1 후 수동 머지가 전제라 all 에서 제외 — 필요하면
      # `scripts/e2e-suite.sh all round2` 처럼 뒤에 명시적으로 이어붙인다.
      # row-drop-repro-noreconcile 은 아직 all 에서 제외 — 아래 plan 설명의
      # "2026-08-24 실측" 참고. 현재 픽스처로는 LLM-patch 경로에 도달하지 못해
      # 이 plan 의 필수 조건(llm-patch>0)이 항상 실패한다. 픽스처가 갖춰지면
      # 여기에 다시 넣는다. 그때까지는 명시 지정으로만 실행.
      # preserve 도 all 에서 제외 (2026-09-04) — 판정 (4)(5) 가 CLI preserve
      # 섹션 슬라이스(cloud-translate #811/#817, 닫힘) 를 전제로 해 main 에서
      # 항상 실패한다. 스크립트는 남겨 두고 명시 지정으로만 실행.
      PLANS+=(webhook korean-review anchor-audit round1 table-suite row-drop-repro
              llm-patch markup-churn retranslate concurrent fill-stubs
              split-docs fix-links fix-tables table-malformed); shift ;;
    -h|--help) sed -n '3,189p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (plan 이름/all 또는 --translate/--engine/--model...)" >&2; exit 1 ;;
  esac
done
# 사용자가 all + 특정 plan 을 같이 준 경우 중복 제거 (첫 등장 순서 유지).
if (( ${#PLANS[@]} )); then
  _dedup=(); declare -A _seen=()
  for p in "${PLANS[@]}"; do
    [[ -n "${_seen[$p]:-}" ]] && continue
    _seen[$p]=1; _dedup+=("$p")
  done
  PLANS=("${_dedup[@]}")
fi
(( ${#PLANS[@]} )) || PLANS=(webhook round1 table-suite markup-churn)

ts="$(date +%Y%m%d-%H%M%S)"
outdir="/tmp/e2e-suite-$ts"
mkdir -p "$outdir"

declare -a RESULTS=()
overall=0
first_plan=1
for plan in "${PLANS[@]}"; do
  if (( first_plan )); then
    first_plan=0
  elif (( SLEEP_BETWEEN > 0 )); then
    echo "=== ${SLEEP_BETWEEN}s 대기 (--sleep-between; claude CLI usage limit 회복) — $(date '+%H:%M:%S') 부터"
    sleep "$SLEEP_BETWEEN"
  fi
  log="$outdir/$plan.log"
  echo "=== [$plan] 시작 → $log"
  if [[ "$plan" == "retranslate" ]]; then
    # 전체 재번역 변형 — 자체 스크립트.
    # align 프롤로그 재사용: 이 plan 도 --from-aligned 를 받는다. 예전에는 못
    # 받아서 `all` 한 번에 align 프롤로그가 **두 번** 돌았다 (round1 + retranslate,
    # Opus heading 분류 10+12회). 스냅샷 위에서 public-api.md 를 공통 앵커에서
    # 자르는 것은 구조를 보존하므로 align 을 다시 돌 필요가 없다.
    rt_reuse=()
    if (( REUSE_ALIGN )) && [[ -n "$ALIGNED_BRANCH" ]]; then
      rt_reuse+=(--from-aligned "$ALIGNED_BRANCH")
      echo "    (align 프롤로그 재사용: --from-aligned $ALIGNED_BRANCH)"
    fi
    bash "$REPO_ROOT/scripts/e2e-retranslate-align-and-translate.sh" \
      "${EM_ARGS[@]}" "${rt_reuse[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "webhook" ]]; then
    # webhook plan 은 별도 스크립트 — --plan 이 아니라 자체 args. PASS_ARGS 는
    # translate/engine/model 계열이라 webhook 에는 의미 없어 전달하지 않음.
    bash "$REPO_ROOT/scripts/e2e-webhook.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '(opened → ko-review triggered.*|merged → translate triggered.*)$' "$log" | tr '\n' ';' | sed 's/;$//' || true)"
    trans_pr="$(grep -oE '^\s*PR\s+:\s+https://[^ ]+' "$log" | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "concurrent" ]]; then
    # 동시 PR 시나리오 — dashboard 를 쓰지 않고 로컬 translate_pr.py 로만
    # 번역하므로 translate/engine/model 계열 인자는 의미가 없다.
    bash "$REPO_ROOT/scripts/e2e-concurrent-prs.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^RESULT: (PASS|FAIL).*' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE '^  A 번역 PR:\s+https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  elif [[ "$plan" == "fill-stubs" ]]; then
    # 빈 번역 채우기 — 자체 스크립트. align 프롤로그가 필요 없다 (픽스처를
    # 직접 심으므로) 라서 --from-aligned 계열 인자는 전달하지 않는다.
    bash "$REPO_ROOT/scripts/e2e-fill-stubs.sh" "${FS_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^FILL_STUBS: (OK|FAIL)' "$log" | tail -n1 || true)"
    fill_pr="$(grep -oE 'Fill PR 생성 — https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${fill_pr:-<no-pr>}")
  elif [[ "$plan" == "fix-tables" ]]; then
    # 깨진 표 정비 — 자체 스크립트. 픽스처가 alpha 상주라 align 프롤로그가
    # 필요 없다 (fill-stubs 와 같은 모양).
    bash "$REPO_ROOT/scripts/e2e-fix-tables.sh" "${FT_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^FIX_TABLES: (OK|FAIL)' "$log" | tail -n1 || true)"
    fix_pr="$(grep -oE 'Fix-tables PR 생성 — https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${fix_pr:-<no-pr>}")
  elif [[ "$plan" == "split-docs" ]]; then
    # 릴리스 노트 연도별 분리 — 자체 스크립트. 모델을 전혀 쓰지 않는 리팩터라
    # --engine/--model 은 의미가 없고, align 프롤로그도 필요 없다 (alpha 의
    # release-notes.md 를 그대로 자르는 것이 이 plan 의 요점이다).
    bash "$REPO_ROOT/scripts/e2e-split-docs.sh" "${SD_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^SPLIT_DOCS: (OK|FAIL)' "$log" | tail -n1 || true)"
    split_pr="$(grep -oE 'Split PR 생성 — https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${split_pr:-<no-pr>}")
  elif [[ "$plan" == "fix-links" ]]; then
    # 링크 정정 — 자체 스크립트. ⭐ 권장 옵션(문서 전체 · 실제 PR · engine=env ·
    # 검증 두 축)이 스크립트 기본값이라 여기서 옵션을 넘기지 않는다. --engine 을
    # 전달하지 않는 것은 의도된 것: 이 plan 의 engine 은 번역 엔진이 아니라
    # 링크 잔여 처리 LLM 이고, 권장 옵션은 그 선택을 잡의 .env 에 맡긴다.
    bash "$REPO_ROOT/scripts/e2e-fix-links.sh" "${FL_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^FIX_LINKS: (OK|FAIL)' "$log" | tail -n1 || true)"
    fix_pr="$(grep -oE 'Fix PR 생성 — https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${fix_pr:-<no-pr>}")
  elif [[ "$plan" == "preserve" ]]; then
    # preserve-existing 반영 — 자체 스크립트. --engine/--model 은 넘기지 않는다:
    # 이 plan 이 검증하는 결함은 CLI 엔진의 @file 한도라서 엔진이 고정이어야
    # 의미가 있다 (api 엔진은 시스템 프롬프트 인라인이라 애초에 이 결함이 없다).
    bash "$REPO_ROOT/scripts/e2e-preserve-existing.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^PRESERVE: (OK|FAIL)' "$log" | tail -n1 || true)"
    kept="$(grep -oE '안 바뀐 섹션 바이트 동일 [0-9]+/[0-9]+ \([0-9]+%\)' "$log" | tail -n1 || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${kept:-<no-ratio>}")
  elif [[ "$plan" == "table-malformed" ]]; then
    # 표 선정 가드 — 자체 스크립트. 픽스처가 **의도적으로 malformed 한 원문**
    # 이라 table-suite 에 얹을 수 없다: check_docs_align.py 는 세 언어가 모두
    # well-formed 라는 전제로 만들어져서, 끊긴 표는 규칙(3) 고아 행으로,
    # 이상치 행은 규칙(6) 컬럼 혼재로 걸린다 — 수정 전·후가 구별되지 않고
    # 규칙(6)은 판정이 아예 거꾸로다 (올바른 동작 = 원문 보존 = FAIL).
    bash "$REPO_ROOT/scripts/e2e-table-malformed.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^RESULT: (OK|FAIL)' "$log" | tail -n1 || true)"
    rules="$(grep -oE '^TABLE-MALFORMED: [0-9]+/[0-9]+ rules passed' "$log" | tail -n1 || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${rules:-<no-rules>}")
  elif [[ "$plan" == "anchor-audit" ]]; then
    # anchor id 후속 검증 — 금지 목록을 실제 PR 로 재현하고 마커 코멘트를 판정.
    # 기대값이 하나뿐이다(15 rules 전부 PASS): 결정적 점검이라 "코드에 따라 exit 3
    # 도 정상" 같은 여지가 없다.
    bash "$REPO_ROOT/scripts/e2e-anchor-audit.sh" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^ANCHOR_AUDIT: (OK|FAIL)' "$log" | tail -n1 || true)"
    aa_pr="$(grep -oE '  PR:   https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${aa_pr:-<no-pr>}")
  elif [[ "$plan" == "korean-review" ]]; then
    # korean-review plan 은 별도 스크립트 — /api/ko-review 잡을 태우고
    # 결과 리뷰 규격 + fable 의미 검증. --engine/--model 은 korean-review
    # 잡의 파라미터가 아니라 전달하지 않는다.
    bash "$REPO_ROOT/scripts/e2e-korean-review.sh" "${KR_ARGS[@]}" > "$log" 2>&1
    ec=$?
    verdict="$(grep -oE '^KO_REVIEW: (OK|FAIL)' "$log" | tail -n1 || true)"
    ko_pr="$(grep -oE '  ko PR         : https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${ko_pr:-<no-pr>}")
  else
    # align 프롤로그 재사용: 앞선 plan 이 남긴 스냅샷이 있으면 2~9단계를 건너뛴다.
    reuse_args=()
    if (( REUSE_ALIGN )) && [[ -n "$ALIGNED_BRANCH" ]]; then
      reuse_args+=(--from-aligned "$ALIGNED_BRANCH")
      echo "    (align 프롤로그 재사용: --from-aligned $ALIGNED_BRANCH)"
    fi
    # row-drop-repro-noreconcile 은 같은 ko 픽스처를 reconcile OFF 로 돌리는
    # 변형이다 — 별도 plan 이름이지만 create-translate-test-pr.sh 에는
    # row-drop-repro 로 넘어간다.
    plan_arg="$plan"
    variant_args=()
    if [[ "$plan" == "row-drop-repro-noreconcile" ]]; then
      plan_arg="row-drop-repro"
      variant_args+=(--no-table-reconcile)
    fi
    bash "$REPO_ROOT/scripts/e2e-align-and-translate.sh" \
      --plan "$plan_arg" "${PASS_ARGS[@]}" "${reuse_args[@]}" \
      "${variant_args[@]}" > "$log" 2>&1
    ec=$?
    if (( REUSE_ALIGN )) && [[ -z "$ALIGNED_BRANCH" ]]; then
      ALIGNED_BRANCH="$(grep -oE 'E2E_ALIGNED_BRANCH=[^ ]+' "$log" | tail -n1 | cut -d= -f2 || true)"
      [[ -n "$ALIGNED_BRANCH" ]] && echo "    (align 스냅샷 확보: $ALIGNED_BRANCH — 이후 plan 이 재사용)"
    fi
    verdict="$(grep -oE '^ALIGNMENT: (OK|FAIL)' "$log" | tail -n1 || true)"
    trans_pr="$(grep -oE 'detected translation PR: https://[^ ]+' "$log" | tail -n1 | awk '{print $NF}' || true)"
    if [[ "$plan" == "llm-patch" ]]; then
      # 이 plan 의 존재 이유는 LLM-patch fallback 을 실제로 태우는 것이다 —
      # exit code 만으로는 알 수 없으므로 로그에서 직접 센다. ok/declined 는
      # fallback 이 무엇을 판단했는지 (#585 류 결함의 실질 신호).
      lp_call="$(grep -c 'LLM-patch fallback: ' "$log" 2>/dev/null || true)"
      lp_ok="$(grep -c 'LLM-patch fallback succeeded' "$log" 2>/dev/null || true)"
      lp_dec="$(grep -c 'LLM-patch fallback declined' "$log" 2>/dev/null || true)"
      lp_skip="$(grep -c 'skip-full-table: .*skipped —' "$log" 2>/dev/null || true)"
      verdict="${verdict:-<no-verdict>} llm-patch=${lp_call:-0} ok=${lp_ok:-0} declined=${lp_dec:-0} skip-full-table=${lp_skip:-0}"
    fi
    if [[ "$plan" == "row-drop-repro-noreconcile" ]]; then
      # 이 변형의 존재 이유는 **LLM-patch fallback 경로를 실제로 태우는 것**이다.
      # exit code 만으로는 그걸 알 수 없다 — reconcile 이 어쩌다 켜져 있거나
      # 픽스처가 부하 임계에 못 미치면 경로를 안 타고도 통과한다 (markup-churn 의
      # guard-skips 가 정확히 그 함정에 빠졌던 전례).  그래서 로그에서 직접 센다.
      rd_patch="$(grep -c 'LLM-patch fallback' "$log" 2>/dev/null || true)"
      rd_skipfull="$(grep -c 'skip-full-table: .*skipped —' "$log" 2>/dev/null || true)"
      rd_stub="$(grep -cE 'table todo-stub|<todo: translate>' "$log" 2>/dev/null || true)"
      verdict="${verdict:-<no-verdict>} llm-patch=${rd_patch:-0} skip-full-table=${rd_skipfull:-0} todo-stub=${rd_stub:-0}"
    fi
    if [[ "$plan" == "markup-churn" ]]; then
      # ALIGNMENT 만으로는 이 plan 의 핵심(가드 미발동)을 알 수 없다 — 미러링이
      # 없어도 정렬은 OK 로 나온다. 로그에서 직접 센다.
      mc_mirrored="$(grep -c 'Cosmetic markup mirrored' "$log" 2>/dev/null || true)"
      # 'load guard: … skipped —' 는 **더 이상 존재하지 않는 문구**다 — 부하
      # 가드는 파일을 제외하지 않고 'load signal:' / 'load routing:' 으로만
      # 알린다 (worker.py: skipped-load 는 legacy). 그래서 이 grep 은 항상 0 을
      # 돌려주며 guard-skips=0 이 공허하게 통과했다 (2026-08-23 발견). 지금 실제로
      # 파일을 제외하는 가드는 skip-full-table 뿐이므로 그것을 센다.
      mc_guard="$(grep -c 'skip-full-table: .*skipped —' "$log" 2>/dev/null || true)"
      # --translate api (jenkins) 모드에서는 번역 로그가 Jenkins 쪽에만 있어서
      # 위 두 카운터가 항상 0 이 된다 — 즉 "guard-skips=0" 이 공허하게 통과한다
      # (2026-08-19 실측). 그 모드의 실제 증거는 번역 PR 본문의 제외 섹션이다.
      mc_excl=0
      if [[ -n "$trans_pr" && "$trans_pr" != "<no-pr>" ]]; then
        mc_excl="$(gh pr view "$trans_pr" --json body --jq .body 2>/dev/null \
          | grep -cE '^### (번역 부하 가드로|구조 불일치로) 제외된' || true)"
      fi
      verdict="${verdict:-<no-verdict>} mirrored=${mc_mirrored:-0} guard-skips=${mc_guard:-0} pr-excl=${mc_excl:-0}"
    fi
    RESULTS+=("$plan|exit=$ec|${verdict:-<no-verdict>}|${trans_pr:-<no-pr>}")
  fi
  echo "=== [$plan] 종료: exit=$ec ${verdict:-}"
  # webhook / korean-review / round1 은 전부 통과(exit 0)가 기대값 — 실패면 suite 실패
  # table-suite 는 번역 로직에 따라 기대값이 다르므로 exit 3 도 정상 허용
  if [[ "$plan" == "webhook" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "korean-review" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "anchor-audit" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "round1" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" == "concurrent" && $ec -ne 0 ]]; then overall=1; fi
  # fill-stubs 는 기대값이 하나뿐이다 — 채우기는 번역 품질이 아니라 구조를
  # 보는 plan 이라 "코드에 따라 exit 3 도 정상" 같은 여지가 없다.
  if [[ "$plan" == "fill-stubs" && $ec -ne 0 ]]; then overall=1; fi
  # fix-tables 도 기대값이 하나다 — 구조를 보는 plan 이라 exit 3 여지가 없다.
  if [[ "$plan" == "fix-tables" && $ec -ne 0 ]]; then overall=1; fi
  # preserve 도 기대값이 하나다 — 반영됐거나 안 됐거나이고, exit 3 여지가 없다.
  if [[ "$plan" == "preserve" && $ec -ne 0 ]]; then overall=1; fi
  if [[ "$plan" != "round1" && "$plan" != "webhook" && "$plan" != "korean-review" \
        && "$plan" != "anchor-audit" \
        && "$plan" != "concurrent" && "$plan" != "fill-stubs" \
        && "$plan" != "fix-tables" \
        && "$plan" != "preserve" \
        && $ec -ne 0 && $ec -ne 3 ]]; then overall=1; fi
  # markup-churn 은 exit 0 만으로는 부족하다 — 가드가 한 번이라도 걸렸다면
  # 마크업 미러링이 동작하지 않은 것이므로 suite 실패로 잡는다.
  # row-drop-repro-noreconcile: exit 0/3 은 둘 다 허용 (todo-stub 으로 해소되면
  # 구조 검사가 표 개수 불일치로 FAIL 을 낼 수 있고, 그건 회귀가 아니라 완전성
  # 검사가 유실을 가시화한 것). 대신 **LLM-patch fallback 이 0건이면 실패** —
  # 그 경로를 태우지 못한 실행은 이 변형이 검증하려던 것을 검증하지 않았다.
  # llm-patch: 경로를 태우지 못한 실행은 검증한 게 없으므로 실패로 잡는다.
  # 원인은 두 가지고, verdict 의 두 카운터가 그걸 가른다 — 같은 실패로 묶어
  # 버리면 설정 문제를 코드 회귀로 오귀속하게 된다 (그 반대도 마찬가지):
  #   skip-full-table=0 → 트리거 자체가 사라졌다. 2026-08-20 (#585) 에 두 트리거
  #                       중 load-guard 가 제거되고 skip-full-table 하나만 남았다.
  #                       그 하나까지 사라지면 이 폴백은 도달 불가 코드가 된다.
  #   skip-full-table>0 → 가드는 발동했는데 폴백이 호출되지 않았다. 즉 그 환경에서
  #                       폴백이 꺼져 있다 — `_try_llm_patch_fallback` 은 플래그가
  #                       꺼져 있으면 "LLM-patch fallback:" 로그를 찍기 전에 반환
  #                       한다. api 모드는 dashboard 가 이 플래그를 보내지 않아
  #                       배포 잡 .env 의 TRANSLATE_DIFF_LLM_PATCH_FALLBACK 에
  #                       좌우되고, local 모드는 --llm-patch-fallback 을 직접
  #                       넘기므로 이 분기가 나오면 하네스 쪽 회귀다.
  if [[ "$plan" == "llm-patch" ]] && [[ "$verdict" == *"llm-patch=0"* ]]; then
    if [[ "$verdict" == *"skip-full-table=0"* ]]; then
      echo "    ! 트리거(skip-full-table) 미발동 — 경로가 사라졌는지 확인 (코드 회귀 의심)." >&2
      echo "      LLM-patch 는 현재 이 가드 하나로만 호출된다 (#585 에서 load-guard 트리거 제거)." >&2
    else
      echo "    ! 가드는 발동했으나 LLM-patch 폴백 미호출 — 해당 환경의" >&2
      echo "      TRANSLATE_DIFF_LLM_PATCH_FALLBACK(=--llm-patch-fallback) 이 꺼져 있는지 확인." >&2
    fi
    overall=1
  fi
  if [[ "$plan" == "row-drop-repro-noreconcile" ]] && [[ "$verdict" == *"llm-patch=0"* ]]; then
    echo "    ! LLM-patch fallback 미발동 — 이 변형은 그 경로 검증이 목적이므로 실패로 집계" >&2
    overall=1
  fi
  if [[ "$plan" == "markup-churn" ]]; then
    if (( ec != 0 )) || [[ "$verdict" != *"guard-skips=0"* ]] \
       || [[ "$verdict" != *"pr-excl=0"* ]]; then overall=1; fi
  fi
done

echo
echo "===== e2e suite 요약 ($outdir) ====="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  (table-suite: reconcile 포함 로직이면 exit 0 이 기대값, 미포함이면 exit 3 이 정상)"
echo "  (markup-churn: exit 0 + guard-skips=0 + pr-excl=0 이 PASS. api 모드에서는 pr-excl 이 실질 지표)"
echo "  (concurrent: exit 0 = B 콘텐츠 보존. exit 1 = 유실(버그 재현), 2 = 하네스 오류)"
echo "  (fill-stubs: exit 0 = FILL_STUBS: OK. stub 섹션만 채우고 그 밖은 바이트 보존 · id 없는 stub 은 건너뜀)"
echo "  (fix-tables: exit 0 = FIX_TABLES: OK. 표가 어긋난 section 만 ko 로 다시 만들고 대조군은 바이트 보존)"
echo "  (row-drop-repro-noreconcile: exit 0/3 허용, 단 llm-patch=0 이면 실패 — 그 경로를 안 태운 실행)"
echo "  (llm-patch: exit 0/3 허용, 단 llm-patch=0 이면 실패. ok/declined 로 fallback 판단을 확인)"
[[ -n "$ALIGNED_BRANCH" ]] && echo "  (align 스냅샷: $ALIGNED_BRANCH — 재현/디버그용, 정리는 수동)"
exit $overall
