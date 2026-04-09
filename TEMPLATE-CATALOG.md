# 템플릿 카탈로그

이 문서는 현재 저장소에서 재사용 가능한 범용 템플릿과 샘플 실행 자산을 정리한 목록이다.

## 운영 원칙

- 템플릿은 `프로젝트 전용 파일`이 아니라 `재사용 가능한 시작점`이어야 한다.
- 템플릿은 대상 URL, 계정, 포트, 부하 수치를 변수화해야 한다.
- 프로젝트에서 한번만 쓰고 끝나는 파일은 템플릿으로 승격하지 않는다.
- 두 개 이상 프로젝트에서 반복 사용 가능성이 확인되면 공통 템플릿으로 관리한다.

## 공통 템플릿

| 구분 | 파일 | 용도 |
| --- | --- | --- |
| 표준 선택 가이드 | `STANDARD-LOADTEST-GUIDE.md` | 도구 선택과 표준 수행 기준 |
| 표준 템플릿 목록 | `TEMPLATE-CATALOG.md` | 재사용 가능한 자산 목록 |

## JMeter 템플릿

| 파일 | 용도 | 프로젝트 적용 방식 |
| --- | --- | --- |
| `Jmeter/plans/web-standard-template.jmx` | 표준 웹 플로우 템플릿 | 호스트, 경로, 사용자 정보, 스레드 수만 바꿔 사용 |
| `Jmeter/scripts/run-local.ps1` | 단일 노드 실행 | 대상 URL과 스레드 수만 인자로 조정 |
| `Jmeter/scripts/run-distributed.ps1` | 다중 엔진 실행 | 원격 엔진 주소와 부하 수치만 조정 |
| `Jmeter/scripts/generate-report.ps1` | HTML Dashboard 생성 | JTL 경로만 변경 |
| `Jmeter/infra/docker-runner/docker-compose.yml` | 실행 러너 컨테이너 | `.env`로 대상 URL과 부하 수치만 변경 |

## nGrinder 템플릿

| 파일 | 용도 | 프로젝트 적용 방식 |
| --- | --- | --- |
| `nGrinder/compose/docker-compose.yml` | Controller + Agent 배포 | Agent 수와 볼륨만 조정 |
| `nGrinder/compose/up.ps1` | Compose 기동 | Agent scale만 변경 |
| `nGrinder/scripts/web_standard_template.groovy` | 표준 웹 플로우 스크립트 | baseUrl, path, 계정값만 변경 |

## k6 템플릿

| 파일 | 용도 | 프로젝트 적용 방식 |
| --- | --- | --- |
| `K6/scripts/event_api_load.js` | 이벤트성 API 부하 템플릿 | BASE_URL, path, threshold, VU만 조정 |
| `K6/scripts/browser_smoke.js` | browser smoke 템플릿 | BASE_URL만 조정 |
| `K6/infra/k6-api-testrun.yaml` | Kubernetes 분산 실행 | namespace, parallelism, resources 조정 |
| `K6/infra/k6-browser-pod.yaml` | browser pod 실행 | 이미지 태그와 리소스 조정 |

## 템플릿 승격 기준

아래 조건 중 2개 이상을 만족하면 템플릿으로 승격한다.

- 서로 다른 프로젝트에서 2회 이상 사용됨
- 환경 변수 또는 프로퍼티로 일반화 가능함
- 특정 고객 전용 정보 제거가 가능함
- 향후 표준 수행 가이드에 넣을 가치가 있음

## 템플릿 적용 절차

1. 카탈로그에서 가장 가까운 템플릿을 찾는다.
2. 프로젝트 폴더 또는 결과 경로에 복제한다.
3. 환경 변수, 경로, 계정, 부하 수치만 수정한다.
4. 새로 생긴 공통 패턴이 있으면 원본 템플릿에 반영한다.
