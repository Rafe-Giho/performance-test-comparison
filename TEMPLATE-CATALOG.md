# 템플릿 카탈로그

이 문서는 현재 저장소에서 재사용 가능한 범용 템플릿과 실행 자산을 정리한 목록이다.

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

템플릿 목록은 실제 저장소 경로와 일치해야 하며, 팀 배포 전 운영 하네스가 경로 정합성을 검증한다.

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
| `Jmeter/plans/web-standard-template.jmx` | 표준 웹 플로우 템플릿 | 호스트, 경로, 이벤트 API, 사용자 정보, 스레드 수만 바꿔 사용 |
| `Jmeter/scripts/run-local.ps1` | 단일 노드 실행 | 프로젝트명, 대상 URL, 경로, 부하 수치, 계정값을 필수 인자로 주입 |
| `Jmeter/scripts/run-distributed.ps1` | 다중 엔진 실행 | 원격 엔진 주소, 프로젝트명, 대상 URL, 경로, 부하 수치, 계정값을 필수 인자로 주입 |
| `Jmeter/scripts/generate-report.ps1` | HTML Dashboard 생성 | JTL 경로와 HTML 출력 경로를 필수 인자로 주입 |
| `Jmeter/infra/docker-runner/docker-compose.yml` | 실행 러너 컨테이너 | `.env`로 대상 URL과 부하 수치만 변경 |

## nGrinder 템플릿

| 파일 | 용도 | 프로젝트 적용 방식 |
| --- | --- | --- |
| `nGrinder/compose/docker-compose.yml` | Controller + Agent 배포 | Agent 수와 볼륨만 조정 |
| `nGrinder/compose/up.ps1` | Compose 기동 | `ProjectName`, `AgentScale`, `Pull`만 변경 |
| `nGrinder/compose/down.ps1` | Compose 정리 | `ProjectName` 기준으로 프로젝트 자원 정리 |
| `nGrinder/compose/.env.example` | Compose 기본 환경값 | `COMPOSE_PROJECT_NAME`, `AGENT_SCALE` 기준값 확인 |
| `nGrinder/scripts/web_standard_template.groovy` | 표준 웹 플로우 스크립트 | baseUrl, path, 이벤트 API, 계정값만 변경 |

## k6 템플릿

| 파일 | 용도 | 프로젝트 적용 방식 |
| --- | --- | --- |
| `K6/scripts/event_api_load.js` | 이벤트성 API 부하 템플릿 | BASE_URL, path, EVENT_PATH, threshold, VU만 조정 |
| `K6/scripts/browser_smoke.js` | browser smoke 템플릿 | BASE_URL만 조정 |
| `K6/infra/k6-api-testrun.yaml` | Kubernetes 분산 실행 | namespace, parallelism, resources 조정 |
| `K6/infra/k6-browser-pod.yaml` | browser pod 실행 | 이미지 태그와 리소스 조정 |
| `K6/infra/RUNTIME-CONTRACT.md` | Kubernetes 런타임 값 계약 | 실제 ConfigMap/Secret 작성 기준 |
| `K6/infra/apply-api.ps1` | API TestRun 적용 | RuntimeConfigPath, RuntimeSecretPath 필수 주입 |
| `K6/infra/apply-browser.ps1` | browser Pod 적용 | RuntimeConfigPath 필수 주입 |

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
