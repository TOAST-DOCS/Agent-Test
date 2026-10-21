<a id="fix-tables-nested-sample"></a>
## 목록 안 표 정비 샘플 { #fix-tables-nested-sample }

이 문서는 **깨진 표 정비**가 목록 항목 안에 들여쓴 표를 고칠 때 들여쓰기를 지키는지 검증하는 테스트 픽스처입니다.
en/ja 사본에는 ko 와 첫 열 식별자가 어긋난 표가 있으며, 정비 실행 뒤에도 표가 목록 항목 안에 남아야 합니다.

이 문서는 사용자 가이드 메뉴에 등록하지 않습니다.

<a id="fix-tables-nested-list"></a>
## 목록 안 표 { #fix-tables-nested-list }

로그 유형별로 다음 필드가 추가됩니다.

- **학습 로그 필드**

    | 이름       | 설명                 |
    | ---------- | -------------------- |
    | trainingId | 학습 ID |

- **하이퍼파라미터 튜닝 로그 필드**

    | 이름                   | 설명                     |
    | ---------------------- | ------------------------ |
    | hyperparameterTuningId | 하이퍼파라미터 튜닝 ID |

- **엔드포인트 로그 필드**

    | 이름            | 설명                   |
    | --------------- | ---------------------- |
    | endpointId      | 엔드포인트 ID          |
    | endpointStageId | 엔드포인트 스테이지 ID |

<a id="fix-tables-nested-deep"></a>
## 두 단계 목록 안 표 { #fix-tables-nested-deep }

1. 요청 본문을 작성합니다.
    - **필수 필드**

        | 이름      | 형식    | 설명         |
        | --------- | ------- | ------------ |
        | clusterId | UUID    | 클러스터 UUID |
        | nodeCount | Integer | 노드 수      |

2. 요청을 보냅니다.

<a id="fix-tables-nested-top"></a>
## 들여쓰지 않은 표 { #fix-tables-nested-top }

이 섹션의 표는 목록 밖에 있습니다. 정비 뒤에도 0칸에 있어야 합니다.

| 이름     | 형식   | 설명      |
| -------- | ------ | --------- |
| regionId | String | 리전 ID   |
| zoneId   | String | 가용성 영역 ID |

<a id="fix-tables-nested-untouched"></a>
## 정상인 목록 안 표 { #fix-tables-nested-untouched }

- **응답 필드**

    | 이름    | 설명        |
    | ------- | ----------- |
    | jobId   | 작업 ID     |
    | jobName | 작업 이름   |
