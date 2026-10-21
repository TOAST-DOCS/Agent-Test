# 목록 흡수 픽스처 — 빈 줄 너머 다른 종류의 목록

python-markdown 은 목록 뒤 빈 줄 너머에 **목록 항목**이 오면 종류(글머리·번호)가 달라도 앞 목록에
이어 붙인다. 그래서 저자가 쓴 `2.` 가 글머리 `•` 로, 메모로 쓴 `- …` 가 `8.` 로 보인다. GitHub
미리보기(CommonMark)는 종류가 다르면 새 목록을 시작하므로 소스 리뷰에서는 보이지 않는다.

각 절은 **실제 alpha 문서의 발췌**다 (원본은 절마다 주석). 판정은 `scripts/check_list_absorb.py`
가 사이트와 같은 렌더러로 한다 — 저자가 쓴 표지·번호 ≠ 독자가 보는 표지·번호인 항목을 센다.

<a id="c1-numbered-after-bullets"></a>
## C1 글머리 목록 뒤 새 번호 목록 { #c1-numbered-after-bullets }

<!-- 원본: TOAST-DOCS/Log-Crash-Search ko/console-guide.md L345-L359 @ e6bc510c -->

로그 외부 보관 정보를 설정합니다.

![lcs_25_202108](https://static.toastoven.net/prod_logncrash/lcs_25_202312.png)

- 외부 OBS에 로그를 보관할 수 있습니다.

1. [AWS S3 API](/Storage/Object%20Storage/ko/s3-api-guide/#s3-api-credential)를 이용해 자격 증명 등록 및 조회로 액세스 키(accessKey)와 비밀 키(secretKey)를 가져옵니다.
2. **로그 외부 보관 설정**에서 **보관 설정**을 클릭합니다.
3. 액세스 키와 비밀 키를 비롯한 데이터들 입력합니다.
4. 외부 로그 변조 알림에 대한 정보들은 설정 추가/수정/삭제 시 전부 필요합니다.
5. 모든 OBS 정보를 입력한 뒤 **저장**을 클릭합니다.
    - 연동 검증을 위해 설정한 버킷에 임시 파일이 생성됩니다.

- 설정한 OBS로 로그가 저장됩니다.
- [NHN Cloud OBS API 안내 가이드](/Storage/Object%20Storage/ko/s3-api-guide/)

<a id="c2-fence-between-steps"></a>
## C2 단계 사이 0칸 코드 블록 + 확인 글머리 { #c2-fence-between-steps }

<!-- 원본: TOAST-DOCS/PrivateCA ko/cert-manager-guide.md L656-L688 @ a658294d -->

1. **Issuer 상태 확인**

```bash
kubectl describe issuer my-acme-issuer-example-com -n default
```

- `Ready` 상태가 `True`인지 확인합니다.
- ACME 계정 등록이 성공했는지 확인합니다.

2. **Certificate 상태 확인**

```bash
kubectl describe certificate test-server-cert-example-com -n default
```

- Events 섹션에서 오류 메시지를 확인합니다.

3. **CertificateRequest 확인**

```bash
kubectl get certificaterequest -n default
kubectl describe certificaterequest <request-name> -n default
```

4. **Challenge 확인**

```bash
kubectl get challenge -n default
kubectl describe challenge <challenge-name> -n default
```

- HTTP-01 Challenge의 경우 Ingress가 올바르게 설정되었는지 확인합니다.
- Challenge URL에 접근 가능한지 확인합니다.

<a id="c3-note-bullets-after-steps"></a>
## C3 단계 뒤 메모 글머리 { #c3-note-bullets-after-steps }

<!-- 원본: TOAST-DOCS/E-mail ko/console-guide.md L12-L28 @ 4a31def4 -->

받는 사람, 제목, 내용, 첨부 파일 등을 입력하여 메일을 발송할 수 있습니다.
일반 메일 발송의 경우 수신자를 직접 입력해야 합니다.

![email_01_20231023](https://static.toastoven.net/prod_email/email_01_20231023.png)

1. **메일 발송** 탭의 **템플릿 사용 여부**에서 **미사용**을 선택합니다.
2. **메일 구분**에서 **일반 메일**을 선택합니다.
3. **발송 메일** 주소를 입력합니다. 이름 형식으로 작성하면 발송자 이름과 메일 주소를 입력할 수 있습니다.
    - "발신자 이름<발신 메일>" 형태로 발송하면, 이메일을 받는 사람에게 발신자 이름과 이메일 주소 형식으로 표시됩니다.
4. 발송하고 싶은 시간이 있다면 **예약 발송**란에 입력합니다.
5. **첨부 파일 업로드** 버튼을 클릭하여 첨부 파일을 업로드합니다.
6. **제목 및 메시지 내용**을 입력합니다.
7. **받는 사람**과 **참조**에 원하는 메일 주소를 입력합니다.

- 첨부 파일은 최대 10개까지 업로드 가능하며, 30MB 이하의 파일만 가능합니다.
- 첨부 파일의 총합은 30MB를 넘어갈 수 없습니다.
- 최대 30MB까지 첨부 가능하지만 수신하는 이메일 시스템(gmail.com, naver.com 등)의 첨부 파일 제한 정책에 따라 `제한 초과`로 거부되거나 스팸 판정률이 높아질 수 있으므로 10MB 이내로 첨부할 것을 권장합니다.

<a id="c4-image-bullets-between-steps"></a>
## C4 단계 사이 이미지 + 글머리 { #c4-image-bullets-between-steps }

<!-- 원본: TOAST-DOCS/Deploy ko/reference.md L151-L172 @ ea5b4fec -->

1. 개별 추가

![deploy_ref_08_202402.png](https://static.toastoven.net/prod_tcdeploy/deploy_ref_08_202402.png)

* 호스트 이름(필수), IP 주소(필수), OS(선택) 입력 후 **추가** 버튼을 클릭합니다.
* 아래 서버 목록에 추가된 내용을 확인합니다. 목록에 남아 있는 서버만 등록됩니다.
* **생성** 버튼을 클릭합니다. 수정할 때는 **수정** 버튼을 클릭합니다.

2. 대량 추가

![deploy_ref_09_202402.png](https://static.toastoven.net/prod_tcdeploy/deploy_ref_09_202402.png)

* **대량 입력** 체크 박스를 선택합니다.
* 아래와 같은 형식으로 서버 정보를 입력합니다.
    ```
    test.host.name1;1.1.1.1;CentOS7.9;
    test.host.name2;2.2.2.2;
    ```

* **추가** 버튼을 클릭합니다.
* 서버 정보가 2개 추가된 것을 확인합니다.
* **생성** 버튼을 클릭합니다. 수정할 때는 **수정** 버튼을 클릭합니다.

<a id="c5-sub-bullets-3-spaces"></a>
## C5 번호 항목 아래 3칸 들여 붙인 글머리 { #c5-sub-bullets-3-spaces }

<!-- 원본: TOAST-DOCS/Private-DNS ko/console-guide.md L55-L60 @ 576922ad -->

1. 수정할 Private DNS Zone을 선택한 후, **Private DNS Zone 수정** 버튼을 클릭합니다.
   
2. VPC를 추가하거나 삭제할 수 있습니다. 화면 우측 **+** 버튼을 클릭해 VPC를 추가할 수 있으며, 추가된 VPC의 **-** 버튼을 클릭해 VPC를 제거할 수 있습니다.
   - Private DNS Zone은 최소 1개의 VPC에 연결되어야 하므로, 마지막 VPC는 삭제할 수 없습니다.

3. **설명**을 수정하고, **확인** 버튼을 클릭합니다.

<a id="c6-bullets-under-step"></a>
## C6 번호 항목 바로 아래 0칸 글머리 { #c6-bullets-under-step }

<!-- 원본: TOAST-DOCS/API-Gateway ko/console-guide.md L50-L64 @ 230a077f -->

1. 좌측 리소스 트리에서 리소스를 추가할 경로에 마우스를 올리면 **+** 버튼이 표시됩니다. 버튼을 클릭한 뒤 **리소스 생성**을 선택합니다.
2. **리소스 경로**를 작성합니다. 작성된 리소스 경로를 포함하여 전체 경로는 255자 이내로 작성해야 합니다. 
    - 예: /products/, /products/{productsId}, /{proxy+}
3. **경로 변수**: 리소스 경로에는 중괄호를 사용하여 **경로 변수**를 생성할 수 있습니다.
    - **경로 변수**는 **{variable}** 또는 하위 경로를 포함한 경로 변수는 **{variable+}**와 같이 선언할 수 있습니다. 
        - **경로 변수**는 플러그인과 백엔드 엔드포인트 설정에서 활용할 수 있습니다.
        - **{variable}**는 경로 변수가 위치한 경로의 값을 변수로 선언합니다.
            - 예: /members/{memberId} 
                - /members/id1 요청의 **{memberId}** 경로 변숫값은 **id1**이 됩니다.
        - **{variable+}** 는 경로 변수가 위치한 하위 경로를 포함하여 변수로 선언합니다. 하위 경로를 포함한 변수에는 하위 리소스 경로를 생성할 수 없습니다.
            - 예: /{proxy+} 
                - **/members/id1** 요청의 **{proxy+}** 경로 변숫값은 **members/id1**이 됩니다.
- **플러그인**: 선택된 경로에 추가된 플러그인을 생성된 메서드에도 추가하려면 체크합니다.
- 리소스를 생성하면서 메서드도 같이 등록하려면 HTTP 메서드를 선택합니다.
- 등록하지 않은 리소스 경로로 API Gateway에 요청하면 404 Not Found 응답을 반환합니다.

<a id="k1-bullets-after-bullets"></a>
## 대조군 K1 글머리 뒤 글머리 { #k1-bullets-after-bullets }

<!-- 합성 대조군 -->

- 첫 번째 글머리 목록의 항목입니다.
- 같은 목록의 두 번째 항목입니다.

- 빈 줄 뒤의 글머리 항목입니다. 앞 목록과 합쳐져도 표지는 그대로입니다.

<a id="k2-loose-numbered-steps"></a>
## 대조군 K2 빈 줄을 둔 번호 단계 { #k2-loose-numbered-steps }

<!-- 합성 대조군 -->

1. 첫 번째 단계입니다.

2. 두 번째 단계입니다.

3. 세 번째 단계입니다.

<a id="k3-sub-bullets-4-spaces"></a>
## 대조군 K3 4칸 들인 하위 글머리 { #k3-sub-bullets-4-spaces }

<!-- 합성 대조군 -->

1. 설정 방식을 선택합니다.
    * **전체**: 모든 대상에 같은 값을 씁니다.
    * **개별**: 대상마다 값을 입력합니다.
2. **확인**을 클릭합니다.
