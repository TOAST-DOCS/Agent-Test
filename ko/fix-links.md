<!-- pre-align:aligned sig=7e09fc5b0570 -->

<a id="fix-links-overview"></a>
## 링크 정정 테스트 { #fix-links-overview }

이 문서는 **링크 정정**(`dashboard/viewer/link_fix.py`, Jenkins `fix-links`) e2e 픽스처입니다.
아래 섹션들은 결정적 규칙 하나씩을 겨냥해 **일부러 잘못 쓴 링크**를 담고 있고,
`scripts/e2e-fix-links.sh` 가 정정 결과를 규칙별로 판정합니다.

이 문서는 사용자 가이드 메뉴(`ko/nav.yml`) 에 등록하지 않습니다. 배포되는 문서가 아니라 파이프라인 픽스처입니다.

<a id="fix-links-self"></a>
## self-link { #fix-links-self }

같은 파일을 배포 URL 모양의 경로로 가리키는 링크입니다. 순수 in-file `#slug` 만 남아야 합니다.

* [정상 링크 모음](./fix-links/#fix-links-controls)

<a id="fix-links-relativize"></a>
## relativize { #fix-links-relativize }

같은 repo 안 파일을 절대 URL · repo-rooted 경로로 가리키는 링크입니다. 둘 다 `./overview.md#pricing` 이 되어야 합니다.

* [과금 (github blob URL)](https://github.com/TOAST-DOCS/Agent-Test/blob/alpha/ko/overview.md#pricing)
* [과금 (repo-rooted 경로)](/ko/overview.md#pricing)

<a id="fix-links-langdir"></a>
## lang-dir { #fix-links-langdir }

다른 언어 폴더를 가리키는 in-repo 링크입니다. 이 문서의 언어 짝이 실재하므로 같은 언어로 바뀌어야 합니다.

* [과금 (다른 언어 폴더)](../en/overview.md#pricing)

<a id="fix-links-nested"></a>
## nested-frag { #fix-links-nested }

배포 URL 조각이 fragment 안으로 끌려 들어가 `#a/#b` 로 겹친 링크입니다. 마지막 `/#` 뒤만 남아야 합니다.

* [과금 (겹친 fragment)](./overview.md#overview/#pricing)

<a id="fix-links-heading"></a>
## heading-frag { #fix-links-heading }

fragment 은 죽었지만 링크 텍스트가 대상 문서의 heading 과 정확히 일치하는 링크입니다.
heading 의 canonical id 로 바뀌어야 합니다.

* [키페어(Key-pair)](./overview.md#keypair-legacy-slug)

<a id="fix-links-report"></a>
## 고치지 말고 보고만 해야 하는 링크 { #fix-links-report }

정정 결과가 실제로 resolve 되는지 확인할 수 없는 링크입니다. 조용히 고치거나 조용히 건너뛰면 안 되고,
PR 본문의 "사람이 직접 확인해야 하는 부분" 표에 사유와 함께 올라와야 합니다.

* [존재하지 않는 문서](./no-such-doc-e2e.md#nowhere)
* [어느 anchor 인지 알 수 없음](./overview.md#anchor-that-does-not-exist-e2e)

<a id="fix-links-controls"></a>
## 정상 링크 모음 { #fix-links-controls }

**부정 대조군입니다.** 아래 링크는 전부 정상이므로 정정 실행 뒤에도 **바이트 단위로 동일**해야 합니다.
하나라도 바뀌었다면 정정이 멀쩡한 링크를 건드린 것입니다.

* [이 문서 첫 섹션](#fix-links-overview)
* [개요 문서](./overview.md)
* [개요 문서의 과금](./overview.md#pricing)
* [NHN Cloud](https://www.nhncloud.com/)

코드 펜스 안의 링크는 링크로 취급하지 않으므로 역시 그대로 남아야 합니다.

```markdown
[펜스 안의 깨진 링크](./no-such-doc-e2e.md#nowhere)
[펜스 안의 self-path](./fix-links/#fix-links-controls)
```
