# 기본 준비 체크리스트

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

이 문서는 현재 저장소가 `표준 준비 기준으로 어디까지 준비됐는지`와 `실제 프로젝트 시작 전에 무엇을 더 채워야 하는지`를 빠르게 확인하기 위한 체크리스트다.

## 지금 준비된 것

| 구분 | 상태 | 설명 |
| --- | --- | --- |
| 표준 선택 문서 | 준비됨 | `STANDARD-LOADTEST-GUIDE.md` |
| 범용 템플릿 목록 | 준비됨 | `TEMPLATE-CATALOG.md` |
| JMeter 기본 가이드 | 표준화 완료 | `README`, `SETUP-GUIDE`, `TEST-GUIDE`, 표준 `.jmx`, 실행 스크립트, 클라우드 분산 운영 기준 |
| JMeter 실행 러너 컨테이너 | 정적 검증 완료 | 부가 방식으로만 사용, 실제 본시험은 VM 직접 설치와 CLI 실행 우선 |
| nGrinder 기본 가이드 | 로컬 기동 검증 완료 | Compose, Controller HTTP `200`, Agent 연결 로그까지 확인 |
| k6 기본 가이드 | NKS Operator 검증 완료 | k6 Operator 설치, CRD 확인, no-op `TestRun`, server dry-run, 적용 스크립트 dry-run 확인 |
| 보고용 비교 자료 | 준비됨 | `docs/` 문서, Notion 보고 페이지 |
| 실제 대상 환경값 | 입력 필요 | URL, 계정, 토큰, 포트, 프로젝트명은 프로젝트별 실제 값만 사용 |
| 실제 대상 부하 실행 | 대상별 수행 | 승인된 대상 URL, 계정, payload, 모니터링 연결 후 smoke부터 수행 |
| 운영 모니터링 연동 | 환경별 수행 | WAS, DB, LB, Ingress, APM 연결은 대상별 실제 구성 사용 |

## 현재 검증 수준

| 도구 | 완료된 검증 | 남은 검증 |
| --- | --- | --- |
| JMeter | 문서, `.jmx`, 실행 스크립트, Docker runner 구성, 하네스 검증 | 실제 클라우드 VM 설치와 분산 smoke |
| k6 | NKS Operator `4.3.2` 설치, CRD, no-op `TestRun`, server dry-run, 적용 스크립트 dry-run | 실제 대상 API/browser smoke와 본시험 |
| nGrinder | Docker Desktop Compose 기동, Controller HTTP `200`, Agent 연결 로그 | 클라우드 VM 배포와 Controller UI 기반 smoke |

## 공통 사전 점검

아래 항목이 비어 있으면 기본 준비가 끝난 것이 아니다.

1. 테스트 대상과 범위가 정리되어 있다.
2. 대상 URL, API 경로, 로그인 방식이 정리되어 있다.
3. 테스트 계정, 데이터셋, 권한 범위가 분리되어 있다.
4. 목표 동시 사용자, 목표 RPS/TPS, 시험 시간, 성공 기준이 정리되어 있다.
5. 테스트 인프라 사양과 네트워크 경로가 정리되어 있다.
6. 모니터링 대상이 정리되어 있다.
7. 결과 저장 경로와 산출물 형식이 정해져 있다.
8. 도구 버전, Java 버전, Docker 이미지 태그가 고정되어 있다.

## 도구별 기본 시작 전제

### JMeter

- 기본 구축 방식은 `VM 또는 인스턴스 직접 설치`
- 작성은 GUI, 본시험은 CLI
- 실행 러너 컨테이너는 선택적 부가 방식
- 최소 준비:
  - Java 17
  - JMeter 설치 경로
  - `.jmx` 복제본
  - `HOST`, `PORT`, `THREADS`, `EVENT_PATH` 같은 실행 파라미터

### nGrinder

- 단기 대응 또는 기존 자산 활용용
- Compose 기반 운영 가능
- 최소 준비:
  - Controller/Agent 이미지 태그 고정
  - Controller 접속 주소
  - Agent 수
  - 포트 정책과 Docker 호스트 자원

### k6

- API 및 클라우드 네이티브 중심
- VM 또는 NKS 실행
- 최소 준비:
  - `BASE_URL`
  - 사용자 계정 또는 토큰
  - 핵심 이벤트 API 경로
  - scenario 및 threshold
  - 러너 사양 또는 Kubernetes 리소스

## 실제 실행 전에 꼭 채워야 하는 값

실행 자산은 임시 기본값을 사용하지 않는다. 아래 값이 비어 있으면 실행이 실패해야 한다.

- 실제 대상 `BASE_URL` 또는 `HOST`
- 실제 `HEALTH_PATH`, `LOGIN_PATH`, `LIST_PATH`, `DETAIL_PATH`, `EVENT_PATH`
- 실제 테스트 계정 또는 토큰
- 실제 `EVENT_PAYLOAD`
- 실제 프로젝트명과 결과 저장 경로
- 실제 thread/VU/ramp-up 수치
- 고정된 이미지 태그와 도구 버전

## 기본 완료 기준

아래를 만족하면 `기본 준비 완료`로 본다.

1. 도구를 하나 선택했고 선택 근거가 있다.
2. 템플릿 복제본을 만들었다.
3. 환경값을 실제 대상 기준으로 바꿨다.
4. smoke test를 1회 실행했다.
5. 결과 파일 또는 대시보드가 생성됐다.
6. 서버 측 모니터링 지표를 함께 확보했다.
7. 다음 단계인 load/stress/spike 계획이 정리됐다.

## 권장 시작 순서

1. `STANDARD-LOADTEST-GUIDE.md`로 도구 선택
2. 이 문서로 준비 상태 점검
3. 해당 도구 `SETUP-GUIDE.md`로 환경 준비
4. 해당 도구 `TEST-GUIDE.md`로 smoke test
5. 결과 저장과 보고 형식 정리

## 현재 판단

현재 저장소는 `기본 준비의 뼈대와 표준 자산`을 갖췄고, k6와 nGrinder는 설치 체인 일부를 실제로 검증했다.

다만 아래는 자동으로 해결하지 않는다.

- 실제 고객 환경값 주입
- 실제 대상 인프라 접근성과 네트워크 확인
- 실제 대상 시스템 부하 실행
- 서버 측 관측 지표 연결

즉, `문서/템플릿/실행 자산은 기준에 맞게 구성됨`, `프로젝트별 환경값 주입과 대상 시스템 smoke 검증은 실제 환경에서 수행`으로 보는 것이 정확하다.
