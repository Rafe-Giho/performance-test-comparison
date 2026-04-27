# k6 Workspace

이 폴더는 `k6` 기반 자산을 관리한다.

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 역할

- 전략 특화 도구
- 클라우드 네이티브/API 중심 프로젝트
- 이벤트성 트래픽, arrival-rate, spike 테스트
- CI/CD 연동형 성능회귀 검증
- 범용 API/브라우저 시나리오 템플릿을 재사용하는 전략 도구
- 클라우드 VM runner와 Kubernetes/NKS runner를 분리해 운영하는 도구
- 전용 node group, ConfigMap/Secret, TestRun CRD 기반 분산 실행을 표준화하는 도구

## 폴더 용도

- `scripts/`: k6 스크립트
- `scenarios/`: 시나리오 메모, 분리된 부하 모델
- `data/`: 입력 데이터
- `reports/`: 결과 및 분석 자료
- `infra/`: VM/NKS 배포 파일, YAML, Helm 값 파일

## 표준 템플릿

- `scripts/event_api_load.js`
- `scripts/browser_smoke.js`
- `infra/k6-api-testrun.yaml`
- `infra/k6-browser-pod.yaml`

## 먼저 읽을 문서

1. [SETUP-GUIDE.md](./SETUP-GUIDE.md)
2. [TEST-GUIDE.md](./TEST-GUIDE.md)

## 운영 포지션

- 기본 선택: `API/클라우드 네이티브 프로젝트에서 예`
- 전략 특화: `예`
- 장기 유지보수: `적합`

## 배포 전 확인

- [SETUP-GUIDE.md](./SETUP-GUIDE.md)의 VM 또는 Kubernetes 구축 검증을 완료한다.
- [TEST-GUIDE.md](./TEST-GUIDE.md)의 threshold pass/fail 기준을 명시한다.
- Kubernetes/NKS 실행 시 `k6-test` namespace, `testruns.k6.io` CRD, `workload=k6-runner`, `workload=k6-browser` node group을 확인한다.
- k6 Operator는 `grafana/k6-operator` chart `4.3.2`, app version `1.3.2`로 설치되어 있어야 한다.
- Runtime ConfigMap/Secret은 [infra/RUNTIME-CONTRACT.md](./infra/RUNTIME-CONTRACT.md)와 일치한다.
- 결과는 `reports/<project>/<yyyymmdd>/`와 클라우드 object storage 또는 중앙 로그 저장소에 남긴다.
- `powershell -ExecutionPolicy Bypass -File ..\tools\validate-workspace.ps1 -Strict`가 통과한다.

## 기초 용어

- `VU`: Virtual User. 가상 사용자
- `Iteration`: 한 VU가 default 함수나 시나리오를 한 번 수행하는 단위
- `Scenario`: 테스트 시나리오의 실행 단위
- `Executor`: 부하를 어떤 방식으로 올릴지 정의하는 실행 모델
- `Threshold`: 통과/실패 기준
- `Check`: 개별 응답 검증
- `Arrival Rate`: 초당 몇 개 요청 또는 iteration이 도착하는지 표현하는 모델
- `Browser`: Chromium 기반 브라우저 테스트 모듈

## 동작 원리

- k6는 스크립트 안에서 시나리오와 부하 모델을 코드로 정의한다.
- 각 VU는 독립적으로 스크립트를 반복 실행한다.
- Executor에 따라 `동시 사용자 기반`, `도착률 기반`, `외부 제어형`으로 동작 방식이 달라진다.
- Threshold를 넘으면 자동으로 실패로 판단할 수 있어 CI/CD와 잘 맞는다.

## 알아야 하는 기본 지식

- k6는 HTTP/API 중심 테스트에 강하고, browser 테스트는 더 무겁다.
- 단순 API 테스트는 메모리 효율이 좋지만, 파일 업로드나 큰 모듈, browser는 자원을 많이 쓴다.
- 코드 기반이라 협업과 재사용은 좋지만, 수행자에게 기본적인 스크립트 이해가 필요하다.
