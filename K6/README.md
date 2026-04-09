# k6 Workspace

이 폴더는 `k6` 기반 자산을 관리한다.

## 역할

- 전략 특화 도구
- 클라우드 네이티브/API 중심 프로젝트
- 이벤트성 트래픽, arrival-rate, spike 테스트
- CI/CD 연동형 성능회귀 검증
- 범용 API/브라우저 시나리오 템플릿을 재사용하는 전략 도구

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
