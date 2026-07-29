# Dashboard API 명세

`dashboard/` 아래 두 개의 HTTP 서버가 있고, 서로 참조·프록시하며 함께
동작한다.

| 서버 | 파일 | 포트 | 프레임워크 | 역할 |
|---|---|---|---|---|
| **PR viewer** | `server.py` | `:8787` | Python stdlib `BaseHTTPRequestHandler` | TOAST-DOCS org 의 PR 목록 · Jobs · Jenkins 트리거 · Log & Crash 히스토리 |
| **Docs viewer / compare-preview** | `viewer/main.py` | `:7700` (docs) / `:7701` (compare-preview) | FastAPI | 마크다운 렌더 · Compare (heading/suffix/link/id) · Preview 비교 |

모든 응답은 `application/json; charset=utf-8` (별도 표기가 없으면). 이
문서는 JSON 을 돌려주는 엔드포인트만 담는다 — HTML 페이지 (`/`, `/view`,
`/compare`, `/link-check` GET, `/preview` 등) 는 생략.

## 공통

### Base URL

* PR viewer: `http://<host>:8787` (예: k8s 내부 도메인 → dashboard SVC)
* Docs viewer: `http://<host>:7700`
* Compare-preview viewer: `http://<host>:7701` (같은 이미지지만 별도 Deployment)

두 viewer 는 base.html 이 base 도메인의 `:7701` 로 rewrite 해서 compare-
preview 를 라우팅한다.

### 인증

세 가지 방식 중 하나로 통과 (`_require_login` / `_current_user`).

| 방식 | 어디에 | 어떻게 |
|---|---|---|
| **Session cookie** | 브라우저 SPA | `POST /api/auth/login` → `Set-Cookie: session=...` |
| **Bearer token** | 외부 스크립트 · Jenkins · cron | `Authorization: Bearer $DASHBOARD_API_TOKEN` — server.py 의 `DASHBOARD_API_TOKEN` 이 세팅되어 있을 때만. |
| **없음** | GET 대부분 (read-only) | 로그인 미필요 |

Write 계열 (`/api/translate`, `/api/align`, `/compare/…` 계열 등) 은 로그인 필수.
로그인 없이 접근하면 `401 {"error":"로그인이 필요합니다"}`.

### 표준 응답 필드

* Jenkins 트리거 응답 (translate/align/…): `{queued: bool, queue_url,
  job_url, build_url?, job_id?, error?}`. `build_url` 은 큐 폴링을 켠
  트리거만 (`resolve_build_url()` 참고); `job_id` 는 `_record_task` 가
  Task 를 기록했을 때만 (DB 미설정이면 없음). 요청이 즉시 400/403/502 로
  튈 수 있음 (target/PR URL 검증 실패, 인증, Jenkins 도달 실패). ※ 예전
  버전엔 generic `task_id?` 도 나열됐지만 실제로 응답에 실리는 곳은
  `/api/suffix-compare-run` 하나뿐이라 표준 필드에서 제외.
* Log & Crash 히스토리 응답: `{configured, data, totalItems, page, size,
  days, repo, ...}`. `configured=false` 면 LnC 미설정 (dev 로컬).

### 공통 타입

**Task** — Jobs 탭의 한 실행 단위. `_record_task` 가 만든다.

```
{
  "task_id": "…",           # UUID
  "job_id": "…",            # 묶는 Job UUID (batch 실행시 여러 task 공유)
  "job_type": "translate|align|align-v2|align-v3|retranslate|ko-review|
                fill-empty|fix-heading-syntax|sync-suffix|suffix-compare",
                # align 계열은 요청 body 의 align_v2/align_v3 플래그로 파생
                # (Jobs 탭 유형 필터로 상호 구분). job id 도 type prefix 를
                # 따라감: align-v3-YYYYMMDD-N
  "label": "번역: <PR>", "task_label": "<PR|repo|path>",
  "status": "queued|running|success|failure|cancelled|partial",
  "build_url": "…jenkins…/N/",
  "params": { … job type 별 요약 dict … },
  "created_at": 1750000000
}
```

**Align preset / Translate preset** — UI 다이얼로그가 소비하는 프리셋
카탈로그. `dashboard/api/align_presets.py` / `translate_presets.py` 참고.
built-in `recommended` 프리셋만 기본 제공.

```
{
  "name": "recommended", "label": "권장 옵션",
  "title": "…설명…",
  "patch": { "align-marker": true, "tx-granularity": "block", … }
              # UI element id → 체크박스 boolean / 입력 문자열
}
```

Align preset 의 built-in `recommended` args:
`--aligned-marker --demote-extras --translate-headings --reconcile-unmatched`.

Translate preset 의 built-in `recommended` args:
`--diff-granularity block --glossary-mode service --max-load-ratio 2 --workers 1 --table-rows --skip-full-table --skip-anchor-only --assign-anchors --align-headings`.

---

## Part 1 · PR viewer (`server.py`, :8787)

### Auth

Source: `server.py:1892-1939` (current_user, _require_login), `2062-2078` (do_GET auth), `2990-3023` (do_POST auth)

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| GET | `/api/auth` | Legacy — 정적 GitHub 토큰 owner 확인 | ✕ |
| GET | `/api/auth/me` | 세션 로그인 상태 확인 | ✕ |
| POST | `/api/auth/login` | 이메일+비밀번호 로그인, 세션 쿠키 발급 | ✕ |
| POST | `/api/auth/logout` | 세션 무효화 + 쿠키 만료 | 쿠키 |

`POST /api/auth/login` 본문 `{email, password}` → 200 `{user}` +
`Set-Cookie`. 실패시 401 `{error, code: invalid_credentials}` / 503
`{error, code: db_unavailable}` (user_store DB 미연결).

### Favorites · Tags · Admin

Source: `server.py:2071-2094` (do_GET), `3025-3081` (do_POST)

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| GET  | `/api/favorites?kind=pr\|link` | 로그인 사용자의 즐겨찾기 목록 | 로그인 |
| POST | `/api/favorites` | body: `{kind, url, title?}` → 즐겨찾기 추가 | 로그인 |
| POST | `/api/favorites/delete` | body: `{id?, kind?, url?}` → 삭제 | 로그인 |
| GET  | `/api/tags` | 리포 태그 전체 `{rows, by_repo, all_tags}` | ✕ |
| POST | `/api/admin/tags` | body: `{repo, tag}` → 태그 추가 | 로그인 |
| POST | `/api/admin/tags/delete` | body: `{id?, repo?, tag?}` → 삭제 | 로그인 |

### Jobs

Source: `server.py:2099-2295` (do_GET), `3084-3105` (do_POST /api/jobs/create)

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| GET | `/api/jobs?mine=0\|1` | 최근 Job 200개 목록 | ✕ (mine=1 은 로그인 시 email 필터) |
| GET | `/api/jobs/<id>` | 단건 Job 상세 (task/log enrichment) | ✕ |
| GET | `/api/jobs/<id>?format=text` 또는 `/api/jobs/<id>/report` | plain-text 리포트 (WebFetch/curl 친화) | ✕ |
| POST | `/api/jobs/create` | body: `{type?="align", label?}` → 빈 Job 생성 → `{job_id}` | 로그인 |

`/api/jobs` 응답:
```
{ "db_available": bool, "mine_only": bool, "mine_email": "",
  "jobs": [ { … Task-like fields + `repo` … } ] }
```

DB 미설정이면 `{db_available:false, jobs:[]}` 로 응답.

### Repos · PRs

Source: `server.py:2140-2425`

| Method | Path | 목적 | 파라미터 |
|---|---|---|---|
| GET | `/api/repos-dashboard?mine=0\|1` | 리포별 Job 통계 + content-agent PR 집계 | mine |
| GET | `/api/pulls?basic=0\|1&fresh=0\|1` | TOAST-DOCS 조직 open PR 목록 | basic → per-PR enrichment 없이 빠른 페이로드 |
| GET | `/api/capr-pulls?fresh=0\|1` | 🤖 PR 현황 — content-agent 라벨 PR (open/closed/merged) | |
| GET | `/api/merged?days=<n>\|limit=<n>&fresh=0\|1` | 최근 merged PR | days 우선, 없으면 limit |
| GET | `/api/repos?fresh=0\|1` | canonical repo 목록 (정적) | |
| GET | `/api/repos/meta?fresh=0\|1` | repo 별 동적 메타 (open_issues, pushed_at, description, archived, default_branch) | |
| GET | `/api/tree?repo=<>&lang=en&ref=<>` | 리포의 `<lang>/*.md` 목록 (파일 선택 다이얼로그) | repo 필수. ref 미지정시 default branch |

응답 공통: `{repo?, refs?, pulls?, repos?, ...}` — GitHub 실패시 502 +
`{error, status, authenticated, hint}`.

### Compare / Todo / Suffix 상태 (docs viewer 프록시)

Source: `server.py:2426-2484` (do_GET), `3551-3655` (do_POST)

PR viewer 는 자기 상태 대신 docs viewer(`_docs_viewer_get`) 에 프록시.

| Method | Path | 목적 | 프록시 대상 |
|---|---|---|---|
| GET | `/api/compare-latest` | 리포별 최신 Compare 요약 | `/api/compare/latest` |
| GET | `/api/align-status?fresh=` | 리포 × [alpha,beta,master] Align/Compare 매트릭스 | 자체 계산 (내부에서 docs viewer 조회) |
| GET | `/api/schedule/status` | Align cache 자동 실행 스케줄(매일 05:00 KST) 상태 · 다음 실행 · 최근 이력 | 자체 (`ALIGN_SCHEDULER.status()`) |
| GET | `/api/todo-status?fresh=` | 리포 × 브랜치 TODO-stub 매트릭스 | 자체 계산 |
| GET | `/api/suffix-compare-latest?mode=title\|id` | 리포별 최신 Suffix Compare 요약 | `/api/compare-suffix/latest` |
| GET | `/api/suffix-compare-all?mode=&repo=&only_drift=` | 전체 Suffix Compare pair export (LLM/CI 용) | `/api/compare-suffix/export` |
| POST | `/api/schedule/run-now` | Align cache 스케줄러를 즉시 1회 실행 (진행 중이면 no-op) → `ALIGN_SCHEDULER.status()` 반환 | 자체 |
| POST | `/api/compare-run` body `{repo, langs?, source?, branch?}` | 리포 전체 Compare 실행+캐시 | `/api/compare/summary` |
| POST | `/api/todo-run` body `{repo, langs?, branch?}` | 리포 전체 TODO-stub 스캔+캐시 | `/api/todo/summary` |
| POST | `/api/suffix-compare-run` body `{repo, source?, mode?, branch?, job_id?}` | 리포 Suffix Compare 실행 (job_id 지정시 Jobs 탭 task 로 기록, 이 경우만 응답에 `task_id` 포함) | `/api/compare-suffix/summary` |

POST 는 모두 로그인 필수.

### Translate / Retranslate

Source: `server.py:3107-3239`

| Method | Path | 목적 |
|---|---|---|
| POST | `/api/translate` | Jenkins 번역 job 트리거 (PR URL 기반) |
| POST | `/api/retranslate` | Compare-headings ↻ 재번역 (파일 하나 → head branch 로 커밋) |
| POST | `/api/translate/file` | 특정 파일 전체 재번역 — `/api/retranslate` 를 외부 호출 편의를 위해 감싼 API (repo+PR/branch+path 만 받고 file_url/commit_to_branch 는 서버가 조합) |

`/api/translate` body — `pr_url` 필수 (`https://github.com/owner/repo/pull/N`).
translate preset 필드 (모두 optional):

```
{
  "pr_url": "…",
  "engine": "api|claude-code|default",
  "model": "claude-haiku-4-5|claude-sonnet-4-6|claude-opus-4-8|default",
  "diff_mode": "incremental|full",
  "diff_granularity": "section|block",
  "diff_section_level": "2|3|4",
  "glossary_mode": "service|common|both|none",
  "table_rows": bool, "table_key_align": bool, "skip_full_table": bool,
  "align_headings": bool, "skip_unaligned": bool, "skip_anchor_only": bool,
  "only_unaligned": bool, "assign_anchors": bool, "verify": bool,
  "max_load_ratio": "2",

  // Concurrency (engine-split at Settings; Jenkinsfile fans into both slots).
  // Empty / missing → 엔진별 default (api=4, cli=2).
  "workers": "",           // 파일 병렬도 (한 job 안의 소스 파일 동시 번역 수)
  "chunk_workers": "",     // chunk 병렬도 (한 파일 안 chunk 동시 API 호출 수)

  // Input-token dials — empty / "default" 이면 잡 .env 가 결정.
  "guidelines_variant_en": "default|aws|unified|unified-v2",  // en 가이드라인 크기
  "guidelines_variant_ja": "default|aws|unified",              // ja 가이드라인 크기
  "tm_top_k": "",          // TM few-shot 개수 (default 10). 낮추면 uncached user prompt 축소

  "only": "ko/foo.md,ko/bar.md", "base_branch": "alpha",
  "pipeline_branch": "…"     // Jenkins multibranch child
}
```

* `guidelines_variant_en` — 캐시된 system prompt 에 주입되는 en 번역
  가이드라인 문서 선택. `unified-v2` (~22K tok, 운영 default) → `unified`
  (~13K tok, -9K) → `aws` (~7K tok, -15K). 모든 chunk 마다 cache_read
  로 재-소비되므로 누적 절감 큼. 실운영 문서엔 A/B 후에만 낮추기 권장
  (`compare_guidelines.py`).
* `guidelines_variant_ja` — ja 는 `unified` (default) / `aws` 두 종.
* `tm_top_k` — Translation Memory 검색 상위 k pair (default 10). User
  prompt 라 uncached, 매 chunk 마다 전액 지불되니 낮추면 즉시 절감
  (10→5 시 ~185 tok/chunk). 랭킹 1..5 가 signal 대부분.

`model` (선택) — Claude model id 를 지정하면 Jenkins `MODEL` 파라미터로
전달되어 API 엔진과 CLI 엔진 모두 같은 모델로 강제 (`TRANSLATE_ANTHROPIC_MODEL`
+ `TRANSLATE_CLAUDE_CODE_MODEL` 동시 설정). `default` 또는 omit 이면 잡의
`.env` / `config.yaml` 기본값 (`claude-sonnet-4-6`) 이 유효. Agent-Test /
translate-test 도 예외 없이 기본값을 씀 — 저렴하게 돌리려면
`claude-haiku-4-5` 명시 선택 (2026-07-16 이전엔 test 레포에 haiku 가 강제
override 되었지만 이제 dashboard 다이얼로그 / API 로만 결정된다).

응답: Jenkins trigger 페이로드 (`queued, queue_url, job_url, build_url,
job_id, task_id`). 트리거 자체는 성공, 실제 실행은 Jenkins 큐 로 넘어감.

`/api/retranslate` body: `{file_url, commit_to_branch, ko_path?, pr_url?,
pipeline_branch?, preserve_existing?, engine?, model?, workers?,
chunk_workers?, guidelines_variant_en?, guidelines_variant_ja?,
tm_top_k?}`. `file_url` 은 GitHub blob URL 이어야 함. `engine` 은
`/api/translate/file` 과 동일 (`api` / `claude-code` / `default` / omit).
`model` 은 `/api/translate` 와 동일 (model id / `default` / omit — 후 두
값은 override 안 함). concurrency + input-token 옵션은 `/api/translate`
와 동일한 shape · 의미.

`/api/translate/file` — `/api/retranslate` 와 동일한 Jenkins 파이프라인
(`FILE_URL` + `COMMIT_TO_BRANCH` + `DIFF_MODE=full`) 을 태우지만, viewer 가
하던 GitHub PR head 조회·`file_url` 조합을 서버가 대신 해 준다. 외부
스크립트/CI 가 Bearer 토큰만으로 호출하기 쉬운 shape.

Body:

```
{
  "repo": "TOAST-DOCS/EasyCache",   // owner/repo, required
  "pr_number": 146,                  // pr_number 또는 branch 중 하나 필수
  "branch": "master",                //   ↳ pr_number 없이 특정 브랜치에 직접 커밋할 때
  "path": "console-guide.md",        // {source}/ 기준 상대경로, required
  "source": "ko",                    // default "ko"
  "path_prefix": "",                 // optional (docs subrepo prefix)
  "preserve_existing": false,        // optional — 기존 en/ja 를 컨텍스트로 넣어 minimal-diff rewrite 유도
  "engine": "api|claude-code|default", // optional — 번역 엔진; 기본은 .env 의
                                       //   TRANSLATE_TRANSLATE_ENGINE. "api" 는
                                       //   prompt cache · 병렬로 CLI 대비 빠름
                                       //   (유료), "claude-code" 는 CLI 구독
                                       //   quota, "default" 또는 omit 은 ENGINE
                                       //   파라미터를 Jenkins 로 안 넘김 (env 기본값)
  "model": "claude-haiku-4-5|claude-sonnet-4-6|claude-opus-4-8|default",
                                       // optional — Claude model id. 값이 있으면
                                       //   Jenkins MODEL 파라미터로 전달, 잡이
                                       //   TRANSLATE_ANTHROPIC_MODEL +
                                       //   TRANSLATE_CLAUDE_CODE_MODEL 동시 설정
                                       //   (API 엔진과 CLI 엔진 모두 같은 모델).
                                       //   "default" 또는 omit 이면 .env 기본값
                                       //   (config.yaml: claude-sonnet-4-6) 유지.

  // Concurrency + input-token dials — /api/translate 와 동일한 shape,
  // 각각 omit / 빈 문자열이면 잡 .env 기본값이 유효 (그 파일에서만
  // override). 자세한 의미는 /api/translate 섹션 참고.
  "workers": "",
  "chunk_workers": "",
  "guidelines_variant_en": "default|aws|unified|unified-v2",
  "guidelines_variant_ja": "default|aws|unified",
  "tm_top_k": "",

  "pipeline_branch": ""              // optional — Jenkins multibranch child branch
}
```

서버가 하는 일:
1. `pr_number` 주면 GitHub `/repos/{repo}/pulls/{n}` 조회 → `head.ref` 로
   `commit_to_branch` 세팅. `branch` 주면 그대로 사용.
2. `file_url = https://github.com/{repo}/blob/{commit_to_branch}/{path_prefix}{source}/{path}` 조합.
3. `trigger_jenkins_retranslate(file_url, commit_to_branch, DIFF_MODE=full,
   engine=…, ...)` → Jenkins 큐 등록.
4. `_record_task(job_type="retranslate", ...)` — Jobs 탭에 노출.

응답: `/api/retranslate` 와 동일 (`queued, queue_url, job_url, build_url,
job_id`). 오류: 400 (repo/path 형식, pr_number/branch 둘 다 없음, path
traversal, engine 이 api/claude-code/default 아님), 401 (미인증), 502
(PR 조회 실패, Jenkins 도달 실패).

### Align

Source: `server.py:3241-3382`

| Method | Path | 목적 |
|---|---|---|
| POST | `/api/align` | Pre-align (fix_headings) Jenkins job 트리거 |
| POST | `/api/align-batch` | 여러 파일에 대한 batch align — 한 Job 안 여러 Task |

`/api/align` body — `target` 필수 (`https://github.com/OWNER/REPO` or
`owner/repo`). align preset 필드:

```
{
  "target": "https://github.com/TOAST-DOCS/Compute",
  "source": "ko", "langs": "en,ja", "doc_path": "", "base_ref": "alpha",
  "branch": "", "engine": "api|claude-code|default", "workers": "",
  "cli_doc_sleep": "0.5",  // MIN, claude-code engine 에만 적용
  "aligned_marker": bool, "strict": bool, "reconcile_unmatched": bool,
  "fix_anchor_links": bool, "demote_extras": bool, "translate_body": bool,
  "translate_headings": bool, "renew_anchor_ids": bool,
  "dry_run": bool, "debug": bool,
  "align_v2": bool, "align_v3": bool,   // 상호 배타 — 둘 다 주면 Jenkins 빌드가
                                        // argparse 에러(exit 2)로 실패
  "pipeline_branch": ""
}
```

**align 모드 3종** — 플래그 조합으로 결정되고, `job_type` 도 같은 이름으로
파생된다 (`align-v3` / `align-v2` / `align`):

| 모드 | 켜는 법 | 동작 |
|---|---|---|
| **align** (기본) | 둘 다 false | Sonnet 구조 매칭 + apply_plan. 잔차는 ⚠ remaining 경고와 함께 그대로 commit |
| **align-v2** | `align_v2: true` | Opus outline 분류가 유일한 매칭 패스 + (옵션) reconcile-unmatched 2-pass + zero-residual sweep (누락은 `<!-- TODO -->` stub 삽입, extra 는 bold 강등) — 항상 잔차 0 으로 마감 |
| **align-v3** | `align_v3: true` | **semantic-first 재정렬** — 모델 `claude-fable-5` · effort `high` 고정 (env override 없음). 의미 기준으로 ko↔target 을 매핑 (anchor 는 출력이지 입력 아님 — 이전 정렬이 anchor 를 잘못 찍은 파일도 탐지·복구), 매치 섹션을 ko 순서로 byte-preserving 재배치 (기존 번역 그대로 재사용), anchor 를 ko-canonical 로 재작성, **진짜 누락 섹션만** per-heading 번역. sweep 없음 — 잔차가 남으면 **그 파일 commit 을 취소**하고 에러로 보고 (honesty gate) |

v3 특이사항:
* `translator` 는 자동 활성 (별도 `translate_headings` 플래그 불필요 — 서버가
  `--align-v3` 만 넘겨도 fix_headings 가 자동 init).
* `dry_run: true` 조합 시 commit/PR 없이 Jenkins 아티팩트(`fixout/`)로만 결과
  확인 가능 — 첫 검증에 권장.
* 구조적으로 "✅ aligned" 로 보이는 파일도 fable 의미 검수를 거침 (위치
  스탬프 오염 false-✅ 탐지용) — 파일당 최소 1 fable 콜 비용.

`/api/align-batch` — `/api/align` 파라미터 (`align_v2`/`align_v3` 포함)에
다음 추가:

```
{
  "paths": "ko/a.md,ko/b.md",     // 필수, comma-sep
  "mode": "new-pr|overwrite",     // default "new-pr"
  "commit_to_branch": "…",        // mode=overwrite 일 때 필수
  "align_v2_threshold": "0",
  "path_prefix": "align/",        // fix_headings 이 넣을 prefix
  "ids_only": bool
}
```

batch 도 `job_type` 을 모드로 파생하고 Job 라벨에 ` (align-v2)` /
` (align-v3)` 접미사를 붙인다.

Bearer 토큰으로 align-v3 dry-run 을 거는 예:

```bash
curl -X POST "$DASHBOARD_BASE_URL/api/align-batch" \
  -H "Authorization: Bearer $DASHBOARD_API_TOKEN" -H "Content-Type: application/json" \
  -d '{"target":"https://github.com/TOAST-DOCS/Alimtalk","base_ref":"alpha",
       "paths":"friendtalkupgrade-api-guide.md,release-notes.md",
       "align_v3":true,"demote_extras":true,"aligned_marker":true,"dry_run":true}'
```

### 기타 Jenkins 트리거

Source: `server.py:3383-3549`

| Method | Path | 목적 |
|---|---|---|
| POST | `/api/sync-suffix` | Public ko anchor id → region variant 로 복제 (`sync-suffix-anchors` job) |
| POST | `/api/fill-empty` | 빈 pre-align stub 채우기 (translate job in FILL mode) |
| POST | `/api/fix-heading-syntax` | Heading 문법(T1/T2/T4/L1) 정정 (LLM 없음) |
| POST | `/api/similarity` | test_similarity.sh 실행 (선택한 en 파일 대상) |
| POST | `/api/ko-review` | 한글 검수 job 트리거 (`ko-review`) |

각 body 는 공통 필드 (`target`, `base_ref`, `branch`, `dry_run`,
`pipeline_branch`) + job 별 세부. 상세는 소스 주석 참고.

### Presets

Source: `server.py:2786-2799`

| Method | Path | 응답 |
|---|---|---|
| GET | `/api/align/presets` | `{presets: [Align preset, …]}` |
| GET | `/api/translate/presets` | `{presets: [Translate preset, …]}` |

Built-in + env (`TRANSLATE_PREALIGN_PRESETS` / `TRANSLATE_TRANSLATE_PRESETS`)
을 merge — env 가 name 으로 override.

### History · Log & Crash

Source: `server.py:2524-2971`

파라미터는 대부분 공통: `?days=1|7|30, ?page=<n>, ?size=<n>, ?repo=<sub>,
?status=completed|failed, ?excludeTest=0|1, ?hideNoPr=0|1`. LnC 미설정
(`_lnc_configured()==false`) 이면 응답에 `configured:false` 로 fallback.

| Method | Path | 목적 |
|---|---|---|
| GET | `/api/similarity/history` | Jenkins similarity job 최근 빌드 |
| GET | `/api/translate/history?pr=<url>` | Jenkins translate job 빌드 (pr 필터 지원) |
| GET | `/api/translate/lnc-history?days=…&page=…&size=…&repo=…&hideNoPr=…&status=…&excludeTest=…` | 번역 실행 LnC 목록 |
| GET | `/api/translate/lnc-detail?jobId=<uuid>` | 번역 실행 상세 (log body + per-file breakdown + PR meta) |
| GET | `/api/align/history?days=…&size=…&repo=…` | Align 실행 목록 (LnC → 없으면 Jenkins fallback) |
| GET | `/api/align/lnc-detail?runId=<uuid>` | Align 실행 상세 (per-doc + totals) |
| GET | `/api/review/lnc-history?days=…&page=…&size=…&repo=…&status=…&excludeTest=…` | 한글 검수 실행 목록 |
| GET | `/api/review/lnc-detail?repo=<>&pr=<>&time=<opt>` | 한글 검수 상세 (per-file violations + per-dimension counts) |
| GET | `/api/webhook/lnc-history?days=…&page=…&size=…&repo=…&status=…&event=…&skip=…&excludeTest=…` | GitHub webhook 딜리버리 목록 (🪝 Webhook 로그 탭) — `webhook/logncrash.py` 가 남기는 `webhook-delivery` LnC 로그를 조회 |
| GET | `/api/webhook/lnc-detail?deliveryId=<X-GitHub-Delivery uuid>` | webhook 딜리버리 상세 (log body + parsed dimensions) |

### Webhook 대상 repo / 필터 관리

Source: `server.py:4114-4179` (GET), `5031-5170` (POST) · `dashboard/webhook_config_store.py`

GitHub webhook 수신부(`webhook/`)가 어떤 repo 를 트리거 대상으로 볼지,
job (translate / ko-review) 별 필터, per-repo × per-job override 를 관리
하는 어드민 API. `webhook_config_store` 를 통해 MySQL 의 세 테이블
(`webhook_target_repo` · `webhook_job_filter` · `webhook_repo_filter_override`)
을 read/write. dashboard 는 admin UI 의 유일한 writer 이며, webhook 파드는
매 delivery 마다 이 테이블을 읽으므로 변경이 즉시 반영된다.

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| GET  | `/api/webhooks/repos` | 등록 상태 전체 스냅샷 (repos + filters + overrides + webhook_url/secret + 카탈로그) | 로그인 |
| POST | `/api/webhooks/repos` | repo 등록/갱신 (upsert) | 로그인 |
| POST | `/api/webhooks/repos/delete` | repo 등록 해제 — **필터 override 는 보존**, 재등록 시 자동 복원 | 로그인 |
| POST | `/api/webhooks/filters` | 글로벌 job 필터 저장 (translate / ko-review 각각) | 로그인 |
| POST | `/api/webhooks/repos/override` | per-repo × per-job 필터 override 저장 (partial update) | 로그인 |
| POST | `/api/webhooks/repos/override/delete` | override 삭제 → 글로벌 필터 상속 | 로그인 |

**GET `/api/webhooks/repos` 응답:**
```
{
  "repos": [ { repo, translate_enabled, ko_review_enabled, pipeline_branch,
               created_at, updated_at, created_by }, ... ],
  "available_repos": ["TOAST-DOCS/Compute", ...],   // canonical 카탈로그 (.gitmodules + EXTRA)
  "repo_tags": { "toast-docs/compute": ["tag1", ...] },   // full-name lower-cased 키
  "db_available": bool,                              // false 면 로컬 dev — repos:[]
  "translate_presets": ["recommended", ...], "ko_review_presets": ["recommended"],
  "webhook_url": "...",                              // 배포 스크립트가 심어둔 LB IP:port (GitHub 웹훅 등록용)
  "webhook_secret": "...",                           // GITHUB_WEBHOOK_SECRET (X-Hub-Signature-256 서명키)
  "webhook_allow_unsigned": bool,                    // true 이면 서명 검증 OFF (dev/임시)
  "filters": { "translate": { actions, base_branches, author_skip,
                              label_require, label_skip, preset,
                              updated_at, updated_by },
               "ko-review": { ... } },
  "repo_overrides": { "owner/repo": { "translate": { dim: value, ...,
                                                     updated_at, updated_by }, ... } }
}
```
DB 미설정 시 `db_available:false, repos:[], repo_overrides:{}` 로 fallback.

**POST `/api/webhooks/repos` body — 등록/갱신:**
```
{
  "repo": "owner/name",         // required, "owner/repo" 형식
  "translate_enabled": true,    // default true — translate job 트리거 대상 포함 여부
  "ko_review_enabled": true,    // default true — ko-review job 트리거 대상 포함 여부
  "pipeline_branch": ""         // optional — Jenkins multibranch child (빈 값이면 기본)
}
```
응답: `{ "repo": <upserted row> }`. 이미 등록된 repo 는 값이 업데이트되고
없으면 신규 삽입. body 에 preset 관련 필드가 있어도 무시 — preset 은 repo
가 아니라 job 필터(글로벌) 또는 override(per-repo) 에서 결정.

**POST `/api/webhooks/repos/delete` body — 등록 해제:**
```
{ "repo": "owner/name" }
```
응답: `{ removed: bool, repo }`. **`webhook_repo_filter_override` 행은
일부러 남긴다** — 같은 repo 를 다시 `/api/webhooks/repos` 로 등록하면 이전
override 가 자동으로 되살아난다. override 까지 완전히 지우려면
`/api/webhooks/repos/override/delete` 를 따로 호출.

**POST `/api/webhooks/filters` body — 글로벌 job 필터:**
```
{
  "job": "translate" | "ko-review",           // required
  "actions": "opened,closed",                  // CSV — PR action allow-list
  "base_branches": "alpha,beta",               // CSV — 이 base 로 향하는 PR 만
  "author_skip": "dependabot[bot]",            // CSV, lowercase 정규화 — skip 저자
  "label_require": "content-agent,한글 검수",  // CSV — 하나라도 있으면 통과 (OR)
  "label_skip": "wip",                         // CSV — 하나라도 있으면 skip
  "preset": "recommended"                      // 이 job 이 트리거될 때 쓸 preset name
}
```
각 CSV 는 빈 문자열 = 그 dim 필터 없음. 응답: `{ job, filter: <저장된 row> }`.
`webhook_config_store._normalize_csv` 가 dedupe/trim/order-preserve 로 정규화
해서 저장하므로 (author_skip 은 lowercase), 응답 값이 요청과 다를 수 있다.

**POST `/api/webhooks/repos/override` body — per-repo × per-job 필터 override:**
```
{
  "repo": "owner/name", "job": "translate" | "ko-review",
  "overrides": {
    // 아래 6 dim 중 넘긴 것만 반영 (partial update). value semantics:
    //   * key 자체 생략     → 그 dim 은 기존 상태 유지
    //   * null              → override 해제, 글로벌 필터로 상속
    //   * string (빈문자 포함) → override 로 저장 (빈문자 = "필터 없음" 을 강제)
    "actions": "opened",
    "base_branches": "e2e/2026-07-30-webhook-1",
    "author_skip": null,
    "label_require": "",
    "label_skip": "wip",
    "preset": "recommended"
  }
}
```
응답: `{ repo, job, override: <저장된 row 또는 null> }`. 6 dim 이 모두 null
로 정리되면 override row 자체가 삭제되고 `override: null` 반환.

**POST `/api/webhooks/repos/override/delete` body:**
```
{
  "repo": "owner/name",
  "job": "translate" | "ko-review"    // 생략 시 그 repo 의 두 job override 모두 삭제
}
```
응답: `{ removed: <count>, repo, job }`. `job` 을 넘기지 않으면 응답
`job` 은 `""`.

**공통 에러:**

| status | 예 |
|---|---|
| 400 | `repo` 형식 오류(`owner/name` 아님), 알 수 없는 `job`, 알 수 없는 override dim, `overrides` 가 dict 아님 |
| 401 | 미인증 (`_require_login` 실패) |
| 503 | `webhook_config_store.db_available()==false` — `DB_*` env 미세팅 |
| 500 | DB 쓰기 실패 |

### 기타

Source: `server.py:2095-2098` (jenkins/defaults), `2486-2523` (translate/ko-files), `2972-2985` (rate_limit · etag_stats), `3657-` (POST /api/queue)

| Method | Path | 목적 |
|---|---|---|
| GET | `/api/jenkins/defaults` | `{default_branch}` — 다이얼로그 placeholder 용 |
| GET | `/api/translate/ko-files?repo=&pr=` | PR 에 added/modified 된 `ko/*.md` 목록 (ONLY 체크박스 UI) |
| GET | `/api/rate_limit` | GitHub PAT rate limit 현황 |
| GET | `/api/etag_stats` | 내부 ETag 캐시 히트율 |
| POST | `/api/queue` body: `{queue_url}` | Jenkins queue item → build URL 해석 (한번만) |

---

## Part 2 · Docs viewer / compare-preview (`viewer/main.py`, :7700 / :7701)

### Auth

Source: `viewer/main.py:307-350`

세션 쿠키는 :8787 · :7700 · :7701 세 서버가 **공유** (같은 `user_store`).
:7700 은 :8787 과 동일한 login/logout endpoint 를 노출한다 — 사용자가
어느 도메인에서 로그인해도 나머지 두 곳에서 그대로 통과.

| Method | Path | 목적 |
|---|---|---|
| GET | `/api/auth/me` | `{authenticated, user}` |
| POST | `/api/auth/login` | body `{email, password}` → `{user}` + Set-Cookie |
| POST | `/api/auth/logout` | 세션 무효화 + 쿠키 만료 |

### Compare-headings — 액션

Source: `viewer/main.py:2357-2472`

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| POST | `/compare-headings/cache/delete` | body `{cache_key}` → 캐시 한 건 삭제 | 로그인 |
| POST | `/compare-headings/anchor-fix` | body `{repo, ref, path_prefix?, path, lang}` → 파일의 broken anchor 링크 자동 수정 후 커밋 | 로그인 |
| POST | `/compare-headings/cache/clear` | body `{repo?}` → 리포의 or 전체 캐시 클리어 | 로그인 |

`anchor-fix` 응답: `{fixed:N, path, ref, message}` 또는
`{fixed:0, message:"…"}`. 401(로그인) / 400(bad request) / 404(파일 없음)
/ 502(commit 실패) / 503(토큰 없음) 가능.

### Compare — 액션 (Jenkins 프록시)

Source: `viewer/main.py:3440-3990`

각 엔드포인트는 먼저 dashboard `/api/align(-batch)` / `/api/retranslate`
로 프록시 (Jobs 탭에 기록); 프록시 실패시 Jenkins 로 직접 트리거해서
동작 자체는 유지 (Job entry 없이).

| Method | Path | 목적 |
|---|---|---|
| POST | `/compare/revert` body `{repo, pr_number, source?, langs?, path_prefix?, paths}` | 선택 파일들을 PR base 로 리버트 (head branch 에 커밋) |
| POST | `/compare/align` body `{repo, ref, path, source?, langs?, base_ref?, branch?, engine?, ..., align_v2?}` | 파일 하나 align (dashboard 프록시) |
| POST | `/compare/align-v2-batch` body `{repo, ref?, source?, langs?, paths, mode?, commit_to_branch?, base_ref?, align_v2?, engine?, align_v2_threshold?, path_prefix?}` | 여러 파일 batch align |
| POST | `/compare/retranslate-file` body `{repo, pr_number, source?, path, path_prefix?, pipeline_branch?, mode?, preserve_existing?, model?}` | 파일 하나 재번역 (PR head 에 직접 커밋). `model` (`claude-haiku-4-5`/`claude-sonnet-4-6`/`claude-opus-4-8`/`default`) 은 dashboard `/api/retranslate` 로 forward → Jenkins MODEL 로 override; `default`/omit 이면 잡 `.env` 기본값 |
| POST | `/compare/add-ids` body `{repo, ref, source?, langs?, paths}` | Task 2 (ids-only, LLM 없음) → PR 생성 |
| POST | `/compare/queue` body `{queue_url}` | Jenkins queue → build URL 해석 |
| POST | `/compare/build-status` body `{build_url}` | 빌드 상태 폴링 (`compare-headings ↻ 재번역` 인디케이터) |
| GET  | `/compare/align/presets` | dashboard `/api/align/presets` 프록시 (실패시 `[]`) |
| GET  | `/compare/align-history?repo=&path=` | 그 파일이 포함된 align-v2 실행 이력 |

`/compare/align` body 는 위 dashboard `/api/align` 과 동일 필드 —
`_viewer_align_body_to_dashboard` 가 자동 매핑.

> **align_v3 미지원 (viewer 경유 한정)**: `/compare/align` ·
> `/compare/align-v2-batch` 는 아직 `align_v3` 를 dashboard 로 forward
> 하지 않는다 — v3 실행은 dashboard `/api/align(-batch)` 직접 호출 또는
> Jenkins `ALIGN_V3=true` 파라미터로만 가능.

### Compare / Todo / Suffix 요약 (JSON 캐시 API)

Source: `viewer/main.py:2474-2804`

| Method | Path | 목적 |
|---|---|---|
| GET  | `/api/compare/latest` | 리포별 최신 heading-compare 요약 (repo list 컬럼용) |
| POST | `/api/compare/by-shas` body `{repo_shas:{owner/repo:[sha,…]}}` | 임의 (repo, sha) 페어들의 heading-compare 캐시 조회 |
| GET  | `/api/compare/summary?url=&source=ko&langs=en,ja` | 리포 전체 Compare 실행/캐시 + `{repo, ref, total, mismatched, scope}` |
| GET  | `/api/todo/summary?url=&langs=en,ja` | 리포 전체 TODO-stub 스캔 + `{repo, ref, en, ja, en_files, ja_files, no_id, total}` |
| POST | `/api/todo/by-shas` body `{repo_shas, langs?}` | 임의 (repo, sha) TODO-stub 캐시 조회 |
| GET  | `/api/compare-suffix/latest?mode=title\|id` | 리포별 최신 Suffix Compare 요약 |
| GET  | `/api/compare-suffix/summary?url=&source=ko&mode=title\|id` | 리포 전체 Suffix Compare 실행/캐시 |
| GET  | `/api/compare-suffix/export?mode=&repo=&only_drift=` | 전체 Suffix Compare pair export (LLM/CI 용) |
| GET  | `/api/translation-pr-meta?repo=&pr=` | 번역 PR 의 previewUrl / diffCompareUrl / summary md&html (immutable → forever cached) |

`by-shas` 응답: `{repos:{owner/repo:{sha:{total, mismatched, accessed_at,
cached}}}}` — 캐시 미스 sha 는 응답에 아예 없음.

### Compare-preview (:7701)

Source: `viewer/main.py:6576-6795`

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| POST | `/compare-preview/start` (Form: `site_a`, `site_b`) | 두 사이트 비교 실행 → `303` `/compare-preview/{run_id}` | 로그인 |
| POST | `/compare-preview/runs` body `{result, build_url}` | Jenkins tool 이 결과 업로드 (RunResult JSON) | ✕ (build-side 호출) |
| POST | `/compare-preview/{run_id}/analyze` | 완료된 run 에 LLM 분석 시작 → `303` back | 로그인 |
| POST | `/compare-preview/{run_id}/delete` | run 삭제 | 로그인 |

Run 목록/상세 GET 은 HTML 페이지라 여기 생략 (`/compare-preview`,
`/compare-preview/{run_id}`).

### Show-id-link (anchor 스냅샷 배치)

Source: `viewer/main.py:4623-5010`

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| GET | `/show-id-link/all/summary?branch=master&full=0` | 리포별 anchor snapshot 상태 (`{items:[{repo, status:snapshot\|missing, doc_count, anchor_count, commit_sha, scanned_at}], ...}`) | ✕ |
| GET | `/show-id-link/cache?limit=100` | 최근 id-link 캐시 항목 (reload URL 포함) | ✕ |
| POST | `/show-id-link/build-one` (Form: `repo=owner/name, branch=master`) | 리포 하나 anchor snapshot 배치 시작 → `{job_id, branch, repo, backend}` | ✕ |
| POST | `/show-id-link/build-all` (Form: `branch=master`) | 전체 org anchor snapshot 배치 → `{job_id, branch, backend}` (backend: jenkins/local) | ✕ |
| GET | `/show-id-link/build-all/status?job_id=` | 배치 진행 상태 (`{state, done, total, current, ok_count, error_count, errors[], backend, build_url, result, error, started_at}`) | ✕ |
| GET | `/show-id-link/build-all/active?branch=` | 진행 중 배치 조회 (`{active, job_id, …_job_payload…}`) | ✕ |
| GET | `/show-id-link/partial?url=&repos=&branch=&full=0&nocache=0` | HTML fragment (form 페이지에서 async fetch) | ✕ |

`state`: `running | done | failed | cancelled | unknown`.

### Link-check (사용자 가이드 링크 인벤토리)

Source: `viewer/main.py:5136-5326`

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| POST | `/link-check/build-all` (Form: `branch=master, langs=ko,en,ja`) | 전체 org link-check 배치 → `{job_id, branch, langs, backend}` | ✕ |
| GET | `/link-check/build-all/status?job_id=` | 배치 상태 (+ `total_broken, top_broken`) | ✕ |
| GET | `/link-check/build-all/active?branch=` | 진행 중 배치 조회 | ✕ |
| GET | `/link-check/summary?url=&ref=&langs=&nocache=0` | 하나의 URL/ref 에 대한 링크 검증 JSON 요약 (`{repo, ref, scope, cache_source, summary, docs[]}`) | ✕ |
| GET | `/link-check/partial?url=&ref=&langs=&nocache=0` | HTML fragment (form 페이지 async fetch) | ✕ |

Form POST `/link-check` 는 redirect 만 하고 실제 스캔은 GET 페이지가
async 로. build-all 은 Jenkins → in-process fallback.

### Diff-compare (ko diff ↔ 번역 PR diff)

Source: `viewer/main.py:1786-1826`

| Method | Path | 목적 | 인증 |
|---|---|---|---|
| POST | `/diff-compare/load` (Form: `input_ko, input_tx, ko_base`) | 두 사이드 (ko + 번역 PR) 해석 → 첫 변경 문서로 redirect | ✕ |

나머지 diff-compare 는 HTML GET (`/diff-compare`, `/diff-compare/new`).

### Compare-headings — section 조회

Source: `viewer/main.py:3183-3239`

| Method | Path | 목적 |
|---|---|---|
| GET | `/compare-headings/section?repo=&ref=&path=&lang=&hindex=&path_prefix=` | Heading section 하나를 렌더한 HTML 반환 (`{ok, lang, hindex, level, anchor, heading, html}`) — doc-diff drawer 용 |

---

## Deprecated / Redirect

| Method | Path | 리다이렉트 대상 |
|---|---|---|
| GET/POST | `/id-link{tail}` | `/show-id-link{tail}` (307, 2026-07-04 rename) |
