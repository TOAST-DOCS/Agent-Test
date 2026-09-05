<!-- pre-align:aligned sig=bd7c613fa6f9 -->

<a id="fix-links-overview"></a>
## 링크 정정 테스트 { #fix-links-overview }

이 문서는 **링크 정정**(`dashboard/links/fix.py`, Jenkins `fix-links`) e2e 픽스처입니다.
아래 섹션들은 결정적 규칙 하나씩을 겨냥해 **일부러 잘못 쓴 링크**를 담고 있고,
`scripts/e2e-fix-links.sh` 가 정정 결과를 규칙별로 판정합니다.

이 문서는 사용자 가이드 메뉴(`ko/nav.yml`) 에 등록하지 않습니다. 배포되는 문서가 아니라 파이프라인 픽스처입니다.

<a id="fix-links-self"></a>
## self-link { #fix-links-self }

같은 파일을 배포 URL 모양의 경로로 가리키는 링크입니다. 순수 in-file `#slug` 만 남아야 합니다.

* [정상 링크 모음](#fix-links-controls)

<a id="fix-links-relativize"></a>
## relativize { #fix-links-relativize }

같은 repo 안 파일을 절대 URL · repo-rooted 경로로 가리키는 링크입니다. 둘 다 `./overview.md#pricing` 이 되어야 합니다.

* [과금 (github blob URL)](./overview/#pricing)
* [과금 (repo-rooted 경로)](./overview/#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

다른 언어 폴더를 가리키는 in-repo 링크입니다. 이 문서의 언어 짝이 실재하므로 같은 언어로 바뀌어야 합니다.

* [과금 (다른 언어 폴더)](./overview/#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

배포 URL 조각이 fragment 안으로 끌려 들어가 `#a/#b` 로 겹친 링크입니다. 마지막 `/#` 뒤만 남아야 합니다.

* [과금 (겹친 fragment)](./overview.md#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

fragment 은 죽었지만 링크 텍스트가 대상 문서의 heading 과 정확히 일치하는 링크입니다.
heading 의 canonical id 로 바뀌어야 합니다.

* [키페어(Key-pair)](./overview.md#key-pair)

<a id="fix-links-langsite"></a>
## lang-site { #fix-links-langsite }

site-root 축약형이 **다른 언어**를 가리키는 링크입니다. 로케일 자리가 하나만 쓰여 있어 보이지만
배포 시 앞자리가 이 문서의 언어로 채워져 `/ko/…/en/…` 가 되므로 죽은 링크입니다.
같은 언어 짝으로 바뀌어야 합니다.

* [과금 (site-root 타언어)](./overview/#pricing)

<a id="fix-links-absdocs"></a>
## abs-docs · abs-docs-env { #fix-links-absdocs }

자기 repo 문서를 **배포 절대 URL** 로 가리키는 링크입니다. 같은 소스 파일이 alpha/beta/master
셋 다에 배포되므로 어떤 host 를 박아도 최소 두 환경에서 틀립니다. 둘 다 상대 경로가 되어야
하고, 비운영 host 는 별도 표기 코드(`abs-docs-env`)로 판정됩니다.

* [과금 (운영 host)](./overview/#pricing)
* [과금 (alpha host)](./overview/#pricing)

<a id="fix-links-legacyjp"></a>
## legacy-jp { #fix-links-legacyjp }

2026-08 이전 일본어 세그먼트 `jp` 가 남은 링크입니다. `jp` 는 두 자리 모두 죽은 로케일이므로
이 문서의 언어로 바뀌어야 합니다.

* [과금 (레거시 jp)](./overview/#pricing)

<a id="fix-links-report"></a>
## 고치지 말고 보고만 해야 하는 링크 { #fix-links-report }

정정 결과가 실제로 resolve 되는지 확인할 수 없는 링크입니다. 조용히 고치거나 조용히 건너뛰면 안 되고,
PR 본문의 "사람이 직접 확인해야 하는 부분" 표에 사유와 함께 올라와야 합니다.

* [존재하지 않는 문서](./no-such-doc-e2e.md#nowhere)
* [어느 anchor 인지 알 수 없음](./overview.md#anchor-that-does-not-exist-e2e)
* [다른 언어에만 있는 문서](../en/heading-lint-demo.md)
* [![그림](/ko/overview.md#key-pair)](/ko/overview.md#key-pair)

위 네 건은 사유가 서로 다릅니다. 뒤의 두 건은 각각 **같은 언어 짝이 repo 에 없어** 언어만
바꾸면 살아있는 링크가 404 가 되는 경우, 그리고 한 스니펫에 target 슬롯이 **두 번** 있어
(이미지가 자기 자신을 가리키는 모양) 어느 쪽을 고쳐야 하는지 특정할 수 없는 경우입니다.
앞의 것은 한 언어에만 존재하는 문서를 가리켜야 성립하므로(그래야 언어 교체가 404 를 만든다는
판단이 실제로 돌아간다) 언어마다 대상이 다릅니다 — 즉 이 픽스처에는 **의도된** ko/en/ja 링크
불일치가 있고, `lang-parity` 검증 리포트에 항상 2건으로 올라옵니다. 판정 (8c) 가 그 2건을
기대값으로 못박습니다: 안 올라오면 비교가 돌지 않은 것입니다.


<a id="fix-links-controls"></a>
## 정상 링크 모음 { #fix-links-controls }

**부정 대조군입니다.** 아래 링크는 전부 정상이므로 정정 실행 뒤에도 **바이트 단위로 동일**해야 합니다.
하나라도 바뀌었다면 정정이 멀쩡한 링크를 건드린 것입니다.

* [이 문서 첫 섹션](#fix-links-overview)
* [개요 문서](./overview.md)
* [개요 문서의 과금](./overview.md#pricing)
* [개요 문서의 과금 (배포 URL 모양 — 코퍼스의 지배적 관행)](./overview/#pricing)
* [다른 repo 가이드 (site-root — cross-repo 의 올바른 표기)](/Compute/Instance/ko/overview/)
* [NHN Cloud](https://www.nhncloud.com/)

코드 펜스 안의 링크는 링크로 취급하지 않으므로 역시 그대로 남아야 합니다.

```markdown
[펜스 안의 깨진 링크](./no-such-doc-e2e.md#nowhere)
[펜스 안의 self-path](./fix-links/#fix-links-controls)
```
