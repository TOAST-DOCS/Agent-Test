## H2 시작 문서 샘플 { #h2-start-sample }

이 문서는 최상위 제목이 `##`(h2)로 시작하는 문서 샘플입니다. NHN Cloud 문서의 기본 형식으로, 문서 제목을 h2로 두고 본문 섹션은 h3부터 시작합니다.

### h3 문서 구조 { #h3-document-structure }

`##`로 시작하는 문서는 문서 제목이 h2이고, 본문 섹션은 h3부터 시작합니다.

| 레벨 | 마크다운 | 용도 |
| --- | --- | --- |
| h2 | `##` | 문서 제목 |
| h3 | `###` | 본문 섹션 |
| h4 | `####` | 하위 섹션 |

### h3 앵커 id 규칙 { #h3-anchor-id-rule }

제목 뒤에 `{ #id }` 형식으로 앵커 id를 지정합니다. id는 소문자와 하이픈만 사용합니다.

```markdown
### 섹션 제목 { #section-title }
```

#### h4 문서 내 링크 { #h4-internal-link }

같은 문서 안의 섹션은 `#id`로 링크합니다. 예: [앵커 id 규칙](#h3-anchor-id-rule)

#### h4 다른 문서 링크 { #h4-external-link }

다른 문서의 섹션은 파일 경로와 앵커를 함께 사용합니다. 예: [H1 시작 문서 샘플](h1-start-sample.md#h1-start-sample)

### h3 코드 블록 { #h3-code-block }

코드 블록은 언어를 지정한 fence 로 작성합니다.

```bash
curl -s "https://api.nhncloud.com/v2/instances" \
  -H "X-Auth-Token: $TOKEN"
```

#### h4 인라인 코드 { #h4-inline-code }

문장 안에서는 `` `백틱` `` 으로 감쌉니다. 예: `flavorId`, `availabilityZone`

#### h4 code fence 안의 템플릿 문법 { #h4-template-in-fence }

code fence 안에 있는 템플릿 문법은 렌더링되지 않고 그대로 노출되어야 합니다.

```markdown
{% raw %}{% if 'ngsc' in build_flags %}{% endraw %}
```

### h3 목록 { #h3-list }

#### h4 순서 없는 목록 { #h4-unordered-list }

- 첫 번째 항목
- 두 번째 항목
    - 중첩된 항목
    - 중첩된 항목
- 세 번째 항목

#### h4 순서 있는 목록 { #h4-ordered-list }

1. 인스턴스를 생성합니다.
2. 보안 그룹을 연결합니다.
3. 플로팅 IP를 할당합니다.

##### h5 깊은 하위 섹션 { #h5-deep-section }

h5 레벨까지 앵커 id가 정상적으로 부여되는지 확인하는 섹션입니다.

### h3 인용과 강조 { #h3-blockquote-and-emphasis }

> 인용문은 이렇게 표시됩니다.
> 여러 줄로 이어질 수 있습니다.

**굵게**, *기울임*, ~~취소선~~ 을 사용할 수 있습니다.

### h3 참고 사항 { #h3-notes }

- 앵커 id는 문서 내에서 유일해야 합니다.
- 제목 텍스트가 바뀌어도 앵커 id는 그대로 유지하는 것을 권장합니다.
- 번역 문서(en, ja)에서도 동일한 앵커 id를 사용합니다.


#### h4 hello { #h4-hello }

## h2 두 번째 최상위 섹션 { #h2-second-top-level }

한 문서 안에 h2 가 두 개 이상 있을 때 목차와 앵커가 어떻게 처리되는지 확인하는 섹션입니다.

### h3 두 번째 h2 의 하위 섹션 { #h3-second-top-level-child }

두 번째 h2 아래에도 h3 이하 섹션을 동일한 규칙으로 둘 수 있습니다.

#### h4 두 번째 h2 의 손자 섹션 { #h4-second-top-level-grandchild }

앵커 id는 h2 가 바뀌어도 문서 전체에서 유일해야 합니다. 예: [첫 번째 h2](#h2-start-sample)
