---
name: split-docs-by-year
description: 릴리스 노트처럼 날짜 heading 이 계속 쌓여 길어진 마크다운 문서를 연도별 파일(`<lang>/<stem>/<year>.md`)로 쪼개고, 원본 자리에는 mkdocs `include-markdown` 지시자만 남겨 조립합니다. ko/en/ja 등 언어 디렉터리를 한 번에 처리하고 nav 갱신·배포 확인까지 이어집니다. 사용자가 "release-notes 를 연도별로 나눠줘", "릴리스 노트가 너무 길다", "문서를 연도별 파일로 분리", "include 로 조립해줘", "split release notes by year" 처럼 말하거나, NHN Cloud 문서 저장소(ko/en/ja 병렬 구조)에서 긴 문서를 쪼개는 이야기가 나오면 파일을 열어보기 전에 이 스킬을 먼저 사용하세요. 다른 문서 저장소에 같은 작업을 적용할 때는 이 스킬 디렉터리(`.claude/skills/split-docs-by-year/`)를 그 저장소에 복사해 그대로 씁니다.
---

# 문서를 연도별로 분리하기

릴리스 노트는 날짜 heading 이 최신순으로 쌓이기만 해서 몇천 줄이 된다. 연도별 파일로 쪼개고 원본 자리에 include 지시자만 남기면, 배포 결과는 한 글자도 달라지지 않으면서 편집·리뷰·번역 단위가 연도로 줄어든다.

**핵심은 "렌더 결과가 이전과 완전히 같아야 한다"** 는 것이다. 이 문서는 이미 배포돼 있고 사람들이 앵커 링크로 특정 날짜를 북마크해 둔다. 그래서 이 스킬의 작업은 리팩터링이지 편집이 아니다 — 내용을 다듬거나 heading 을 정리하고 싶은 유혹이 들어도 하지 마라. 그건 별도 작업이고, 섞으면 "분리 때문에 깨진 것"과 "고치다 깨진 것"을 구분할 수 없게 된다.

## 준비 확인

이 스킬 디렉터리의 `scripts/split_by_year.py` 가 실제 분리를 담당한다 (아래 명령은 저장소 루트에서 실행한다고 본다 — 이 스킬은 저장소에 함께 들어 있는 project skill 이라 `.claude/skills/` 아래에 있다). 직접 파이썬을 짜지 마라 — 앵커 끌어오기·연도 연속성·왕복 검증이 이미 들어 있고, 매번 다시 짜면 그 안전장치를 잃는다.

작업 전에 세 가지를 확인한다:

1. **작업 트리가 깨끗한지** (`git status`). 분리는 파일을 대량으로 갈아치우므로, 실패했을 때 `git checkout .` 한 번으로 되돌아갈 수 있어야 한다.
2. **저장소가 `include-markdown` 을 쓰는지.** 다른 문서에서 `grep -rn 'include-markdown' --include=*.md .` 로 선례를 찾아 지시자 표기(따옴표 종류, `./` 접두사)를 그대로 따른다. 선례가 없으면 그 저장소의 빌드가 이 플러그인을 쓰는지부터 확인해야 한다 — 안 쓰면 지시자가 그냥 raw 텍스트로 배포된다.
3. **하위 폴더 파일이 배포에 수집되는지.** 이미 하위 폴더를 include 하는 문서가 있으면 검증된 것이다. 없다면 이번이 첫 사례이므로 배포 확인(아래 5단계)을 반드시 거쳐야 한다.

## 1. 문서 구조 먼저 훑기

분리 기준은 "지정 레벨(보통 `##`)의 heading 중 연도를 담은 것"이다. 이 가정이 깨지면 조용히 이상하게 잘리므로, **자르기 전에 최상위 heading 을 전부 눈으로 본다**:

```bash
grep -nE '^#{1,3} ' ko/release-notes.md | head -100
```

여기서 확인할 것:

- `## <날짜>` 가 아닌 최상위 heading 이 섞여 있나? (문서 제목 하나는 정상 — 첫 날짜 heading 앞의 모든 줄은 헤더로 부모 파일에 남는다.) 중간에 `## 참고사항` 같은 게 있으면 그 섹션이 앞 연도 파일에 딸려간다 — 그래도 되는지 판단해야 한다.
- 날짜 heading 의 레벨이 섞여 있나? 번역 드리프트가 있는 저장소에서는 ko 는 `##` 인데 특정 항목만 `###` 인 경우가 흔하다. 레벨이 낮은 것은 앞 섹션 안에 그대로 남으므로 대개 문제없지만, 연도 경계에 걸쳐 있으면 확인이 필요하다.
- 언어마다 heading 형식이 다른가? (`2026. 05. 27.` / `May 27, 2026` / `2022.12.27.`) 스크립트는 형식이 아니라 **4자리 연도**만 보므로 섞여 있어도 된다.

## 2. Dry-run 으로 계획 확인

```bash
python3 .claude/skills/split-docs-by-year/scripts/split_by_year.py \
  --root . --langs ko,en,ja --doc release-notes.md
```

기본이 dry-run 이라 아무것도 쓰지 않는다. 언어별 섹션 수·연도 파일 수·각 파일 줄 수와 왕복 검증 결과가 나온다.

여기서 **언어별 섹션 수가 다른 것은 정상일 수 있다** — 번역이 밀려 en/ja 에 없는 날짜가 있으면 그렇다. 기존 드리프트이지 분리가 만든 문제가 아니니, 수를 맞추려고 내용을 손대지 마라.

**연도 비연속으로 중단되면** 원문 날짜 오타다. 예를 들어 `2020.01.21` 을 `2019.01.21` 로 적어두면 2019 구간이 두 번 생긴다. 스크립트가 찾을 위치를 알려주니 오타를 고치고 (또는 사용자에게 물어보고) 다시 돌린다. 고치지 않기로 했다면 그 섹션은 오타 연도 파일에 들어간다는 사실을 보고에 명시한다.

## 3. 적용

```bash
python3 .claude/skills/split-docs-by-year/scripts/split_by_year.py \
  --root . --langs ko,en,ja --doc release-notes.md --apply
```

`--apply` 도 언어마다 왕복 검증(헤더 + 연도 파일을 도로 이어붙인 결과 == 원본, 공백 줄 무시)을 먼저 통과해야 쓴다. 실패하면 그 언어는 한 글자도 쓰지 않고 중단한다.

주요 옵션:

| 옵션 | 쓸 때 |
| --- | --- |
| `--langs ko,en` | 언어 구성이 다른 저장소 |
| `--level 3` | 날짜 heading 이 `###` 인 문서 |
| `--include-format '{% include-markdown "{path}" %}'` | 그 저장소의 지시자 표기가 다를 때 |
| `--doc <name>.md` | 릴리스 노트가 아닌 다른 누적형 문서 |

## 4. 커밋 전 검증

분리 커밋을 만들기 **전에** include 를 전개해 이전 상태와 대조한다. 이게 "렌더 결과가 같다"를 증명하는 단계다:

```bash
python3 .claude/skills/split-docs-by-year/scripts/split_by_year.py \
  --root . --doc release-notes.md --check HEAD
```

`CHECK: OK` 가 나와야 한다. 세 언어 모두 include 전개본이 `HEAD` 시점 원본과 내용 기준 동일하다는 뜻이다. (커밋한 뒤 확인한다면 `--check HEAD~1`.)

이 저장소에 구조 정합 checker 가 있으면 (예: ko/en/ja 를 비교하는 스크립트) 함께 돌린다. 이때 **checker 가 최상위 파일만 훑는지 확인하라** — `os.listdir` 로 대상을 모으는 checker 는 하위 폴더로 내려간 본문을 통째로 놓치고, include 지시자만 남은 부모는 비교할 구조가 없어 무조건 통과한다. 커버리지가 사라진 것을 OK 로 보고하는 상태가 되므로, 재귀 순회로 고치거나 최소한 사용자에게 알려야 한다.

## 5. nav 와 배포 확인

nav 파일(`ko/nav.yml` 등)이 있으면 대상 문서가 등재돼 있는지 본다. 연도 파일은 **등재하지 않는다** — include 로 조립되는 본문이지 독립 페이지가 아니다. 부모 문서만 있으면 된다.

푸시 후 배포된 페이지에서 확인할 것:

```bash
curl -s -H 'Cache-Control: no-cache' "<배포 URL>?nocache=$(date +%s)" -o page.html
grep -c 'include-markdown' page.html     # 0 이어야 한다 (raw 지시자 노출 없음)
```

그리고 **원본 소스의 앵커가 전부 페이지에 살아 있는지** 확인한다. 앵커가 하나라도 빠지면 그 날짜로 걸린 외부 링크가 죽는다:

```bash
python3 - <<'PY'
import re
page = open('page.html', encoding='utf-8').read()
ids = set(re.findall(r'id="([^"]+)"', page))
parent = open('ko/release-notes.md', encoding='utf-8').read()
files = re.findall(r"include-markdown\s*['\"]\./?([^'\"]+)", parent)
src = [parent] + [open('ko/' + f, encoding='utf-8').read() for f in files]
anchors = [a for t in src for a in re.findall(r'<a\s+(?:id|name)="([^"]+)"', t)]
missing = [a for a in anchors if a not in ids]
print(f'앵커 {len(anchors)}개 중 누락 {len(missing)}: {missing[:10]}')
PY
```

heading 개수와 레벨 순서까지 대조하면 더 확실하다 — 페이지의 `<h2>`~`<h4>` 레벨 나열이 로컬 파일들의 heading 레벨 나열과 같아야 한다.

배포 파이프라인이 있는 저장소라면 배포 잡이 그 커밋을 집어갔는지도 확인한다(저장소마다 다르니 `CLAUDE.md` 나 기존 메모를 따른다).

## 보고할 것

작업을 마치면 사용자에게 이것들을 알린다:

- 언어별 섹션 수 → 연도 파일 수, 왕복 검증 / `--check` 결과
- 발견한 원문 이상(날짜 오타, 언어별 섹션 수 차이) 과 그것을 어떻게 처리했는지
- checker·nav 처럼 분리 때문에 의미가 달라진 주변 장치

특히 **"드리프트를 발견했지만 고치지 않고 그대로 옮겼다"** 는 반드시 말해야 한다. 조용히 두면 나중에 이번 분리 작업이 원인으로 오해받는다.
