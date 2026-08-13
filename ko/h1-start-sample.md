# H1 시작 문서 샘플 { #h1-start-sample }

이 문서는 최상위 제목이 `#`(h1)로 시작하는 문서 샘플입니다. 문서의 모든 섹션 제목에는 앵커 id가 부여되어 있습니다.

## h2 문서 구조 { #h2-document-structure }

`#`로 시작하는 문서는 문서 제목이 h1이고, 본문 섹션은 h2부터 시작합니다.

| 레벨 | 마크다운 | 용도 |
| --- | --- | --- |
| h1 | `#` | 문서 제목 |
| h2 | `##` | 본문 섹션 |
| h3 | `###` | 하위 섹션 |

## h2 앵커 id 규칙 { #h2-anchor-id-rule }

제목 뒤에 `{ #id }` 형식으로 앵커 id를 지정합니다. id는 소문자와 하이픈만 사용합니다.

```markdown
## 섹션 제목 { #section-title }
```

### h3 문서 내 링크 { #h3-internal-link }

같은 문서 안의 섹션은 `#id`로 링크합니다. 예: [앵커 id 규칙](#h2-anchor-id-rule)

### 다른 문서 링크 { #h3-external-link }

다른 문서의 섹션은 파일 경로와 앵커를 함께 사용합니다. 예: [H2 시작 문서 샘플](h2-start-sample.md#h2-start-sample)

## h2 코드 블록 { #h2-code-block }

코드 블록은 언어를 지정한 fence 로 작성합니다.

```bash
curl -s "https://api.nhncloud.com/v2/instances" \
  -H "X-Auth-Token: $TOKEN"
```

### h3 인라인 코드 { #h3-inline-code }

문장 안에서는 `` `백틱` `` 으로 감쌉니다. 예: `flavorId`, `availabilityZone`

### h3 code fence 안의 템플릿 문법 { #h3-template-in-fence }

code fence 안에 있는 템플릿 문법은 렌더링되지 않고 그대로 노출되어야 합니다.

```markdown
{% raw %}{% if 'ngsc' in build_flags %}{% endraw %}
```

## h2 목록 { #h2-list }

### h3 순서 없는 목록 { #h3-unordered-list }

- 첫 번째 항목
- 두 번째 항목
    - 중첩된 항목
    - 중첩된 항목
- 세 번째 항목

### h3 순서 있는 목록 { #h3-ordered-list }

1. 인스턴스를 생성합니다.
2. 보안 그룹을 연결합니다.
3. 플로팅 IP를 할당합니다.

#### h4 깊은 하위 섹션 { #h4-deep-section }

h4 레벨까지 앵커 id가 정상적으로 부여되는지 확인하는 섹션입니다.

## h2 인용과 강조 { #h2-blockquote-and-emphasis }

> 인용문은 이렇게 표시됩니다.
> 여러 줄로 이어질 수 있습니다.

**굵게**, *기울임*, ~~취소선~~ 을 사용할 수 있습니다.

## h2 참고 사항 { #h2-notes }

- 앵커 id는 문서 내에서 유일해야 합니다.
- 제목 텍스트가 바뀌어도 앵커 id는 그대로 유지하는 것을 권장합니다.
- 번역 문서(en, ja)에서도 동일한 앵커 id를 사용합니다.
