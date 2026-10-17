<a id="mkdocs-followup-vars-use"></a>
## Sample > 변수 사용 { #mkdocs-followup-vars-use }

{% include-markdown './mkdocs-followup-vars.md' %}

콘솔 주소는 `$[ portal_url ]$` 입니다.

리전 코드는 `$[ region_code ]$` 입니다.

잘못된 구분자로 쓴 {{ portal_url }} 은 치환되지 않습니다.

아래 코드 예시의 중괄호는 남의 문법이라 정상입니다.

```bash
curl {{ portal_url }}/v2/tokens
```

워크플로 표기 ${{ portal_url }} 도 이 문법과 무관합니다.

{% raw %}
변수는 `$[ portal_url ]$` 로 씁니다.
{% endraw %}
