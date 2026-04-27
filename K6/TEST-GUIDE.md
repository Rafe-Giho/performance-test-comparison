# k6 테스트 수행 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 기본 원칙

- k6는 `전략 특화` 도구다.
- API 중심, 이벤트성 트래픽, 클라우드 네이티브, CI/CD 연계가 핵심일 때 우선 적용한다.
- 신규 프로젝트는 범용 스크립트 템플릿에서 시작한다.

## 실행 전제

- [SETUP-GUIDE.md](./SETUP-GUIDE.md)의 VM 또는 Kubernetes 구축 검증을 완료한다.
- 실제 `BASE_URL`, path, 계정, 이벤트 payload, threshold 기준이 준비되어 있다.
- 테스트 러너와 대상 애플리케이션의 리소스 지표를 분리해 수집한다.
- Kubernetes 실행 시 [infra/RUNTIME-CONTRACT.md](./infra/RUNTIME-CONTRACT.md)의 ConfigMap/Secret key를 그대로 사용한다.
- Browser 테스트는 API 부하 테스트와 별도 러너에서 수행한다.
- VM 실행은 `summary-api-*.json` 또는 `summary-browser-*.json`을 저장할 결과 경로를 준비한다.
- NKS 실행은 `k6-test` namespace, k6 Operator chart `4.3.2`, app version `1.3.2`, `testruns.k6.io` CRD, `workload=k6-runner`, `workload=k6-browser` node group을 확인한다.

## 실행 전에 알아야 하는 기초 지식

- `VU`는 실제 사람 수를 그대로 의미하지 않는다. Think time과 시나리오 길이에 따라 실제 요청량이 달라진다.
- `constant-vus`와 `constant-arrival-rate`는 완전히 다른 모델이다.
- `Check`는 응답 검증이고, `Threshold`는 최종 합격 기준이다.
- browser 테스트는 API 테스트보다 CPU와 메모리를 훨씬 많이 쓴다.

## 실무에서 중요한 원리

- 이벤트성 트래픽은 동시 사용자 수보다 `도착률`과 `급상승 구간`을 더 잘 모델링해야 한다.
- k6는 `시나리오 분리 + threshold 자동 판정`을 잘 쓰는 것이 핵심이다.
- 클라우드 네이티브 서비스는 k6 러너 자원과 애플리케이션 자원을 분리해야 결과 왜곡이 적다.

## 적합한 상황

- HTTP API 집중 호출
- 로그인/조회/주문/결제 등 이벤트성 폭주
- arrival-rate 기반 모델링
- 반복 회귀 테스트
- Kubernetes 기반 서비스
- 클라우드 네이티브 서비스의 오토스케일 반응과 병목을 같이 보고 싶은 경우

## 표준 시나리오 흐름

1. 헬스체크 또는 메인 진입
2. 인증
3. 목록 조회
4. 상세 조회
5. 핵심 이벤트 API 호출
6. 종료

## 표준 설계 원칙

- 시나리오는 실제 사용자 행동 비율을 반영한다.
- 각 시나리오에 threshold를 정의한다.
- smoke, load, stress, spike, soak를 분리한다.
- API 테스트와 browser 테스트를 분리한다.

## 권장 executor 예시

- 평균 부하: `constant-vus`, `ramping-vus`
- 요청 도착률 기반: `constant-arrival-rate`, `ramping-arrival-rate`
- 외부 제어 또는 특수 상황: `externally-controlled`

## 실행 순서

1. 범용 템플릿 복제
2. 실제 `BASE_URL`, path, 계정, 이벤트 payload 확정
3. 시나리오 정의
4. threshold 정의
5. smoke test
6. load/stress/spike/soak 실행
7. 애플리케이션 메트릭과 상관분석
8. threshold pass/fail 정리

## 실행 Runbook

### 1. 클라우드 네트워크 사전 확인

VM runner 또는 NKS runner Pod가 대상 시스템과 결과 저장소에 접근 가능한지 먼저 확인한다.

```powershell
Test-NetConnection <actual-target-dns> -Port 443
Test-NetConnection <actual-object-storage-endpoint> -Port 443
kubectl get nodes -l workload=k6-runner
kubectl get nodes -l workload=k6-browser
helm status k6-operator -n k6-operator-system
kubectl get crd testruns.k6.io
```

Linux VM runner에서는 아래처럼 확인한다.

```bash
curl -k -I "<actual-base-url><actual-health-path>"
curl -I "https://<actual-object-storage-endpoint>"
```

### 2. VM API smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\scripts\run-api.ps1 `
  -ProjectName "<project-name>" `
  -BaseUrl "<actual-base-url>" `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

성공 시 `K6/reports/<project-name>/<yyyymmdd>/summary-api-*.json`이 생성된다.

### 3. VM browser smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\scripts\run-browser.ps1 `
  -ProjectName "<project-name>" `
  -BaseUrl "<actual-base-url>"
```

성공 시 `K6/reports/<project-name>/<yyyymmdd>/summary-browser-*.json`이 생성된다.

### 4. Kubernetes API dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>" `
  -DryRun
```

### 5. Kubernetes API 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>"
kubectl get testrun -n k6-test
kubectl get pods -n k6-test
```

### 6. Kubernetes browser smoke dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-browser.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -DryRun
```

### 7. Kubernetes 결과 수집

```powershell
New-Item -ItemType Directory -Path .\K6\reports\<project-name>\<yyyymmdd> -Force
kubectl get testrun -n k6-test | Out-File .\K6\reports\<project-name>\<yyyymmdd>\testrun.txt
kubectl get pods -n k6-test -o wide | Out-File .\K6\reports\<project-name>\<yyyymmdd>\pods.txt
kubectl logs -n k6-test <actual-runner-pod-name> | Out-File .\K6\reports\<project-name>\<yyyymmdd>\k6-runner.log
```

Pod 이름은 `kubectl get pods -n k6-test` 결과에서 실제 runner Pod를 확인해 입력한다.

## 성공/실패 판정

- smoke는 모든 `check`가 통과하고 k6 프로세스가 exit code `0`으로 종료되면 성공이다.
- 본시험은 `threshold`가 모두 통과해야 성공이다.
- `http_req_failed`가 기준을 초과하거나 P95/P99가 합의 기준을 넘으면 실패다.
- 러너 리소스 병목이 확인되면 대상 시스템 성능 판정에서 제외하고 러너를 증설한 뒤 재시험한다.
- NKS 실행은 `TestRun` 상태, runner Pod 종료 상태, runner logs, threshold 결과가 모두 정상이어야 성공이다.
- browser smoke는 Chromium 시작, 페이지 로딩, `checks: rate==1.0`을 모두 만족해야 성공이다.

## 결과 산출물

- VM 실행 summary JSON
- Kubernetes `TestRun` 상태
- runner Pod 목록과 로그
- threshold pass/fail 결과
- API runner 또는 browser runner node group 리소스 사용량
- 대상 시스템 CPU/메모리/네트워크/DB/API Gateway/Ingress/WAF 지표
- 결과 저장소 업로드 경로

## 필수 결과 항목

- 요청 수
- RPS
- 평균 응답시간
- P90/P95/P99
- 에러율
- threshold pass/fail
- 테스트 중 CPU/메모리/네트워크

## 이벤트성 트래픽 테스트 기준

- 이벤트 시작 직후 급상승 구간을 별도 시나리오로 만든다.
- 특정 API 쏠림 비율을 분리한다.
- 캐시 warm-up 구간과 본시험 구간을 나눈다.
- 오토스케일링 반응 시간과 병목 구간을 함께 본다.

## 결과 저장 규칙

- 스크립트: `scripts/<project>-<scenario>.js`
- 데이터: `data/<project>-<dataset>.csv`
- 결과: `reports/<project>/<yyyymmdd>/`
- 클라우드 장기 보관: 프로젝트 표준 object storage 또는 중앙 로그 저장소에 `reports/<project>/<yyyymmdd>/` 전체를 업로드

## 템플릿 환류 규칙

- 반복적으로 쓰는 executor 조합은 공통 템플릿으로 승격한다.
- 고객 전용 URL과 토큰은 템플릿에 남기지 않는다.
- threshold 기준이 조직 표준으로 굳어지면 공통 스크립트에 반영한다.

## 장애 조치

- 필수 환경변수 오류는 실행 명령의 `BASE_URL`, path, 계정, payload 인자를 확인한다.
- JSON parse 오류는 `EVENT_PAYLOAD`가 유효한 JSON 문자열인지 확인한다.
- threshold 실패는 실패 기준 그대로 남기고 서버 지표와 함께 원인을 분석한다.
- Kubernetes 리소스 생성 실패는 namespace 권한, k6 Operator 설치 상태, Runtime ConfigMap/Secret을 확인한다.
- Browser 테스트 실패는 Chromium 실행 권한, 공유 메모리, CPU/메모리 요청량을 확인한다.
- NKS Pod pending은 `workload=k6-runner`, `workload=k6-browser` 라벨 노드 존재 여부와 node group 가용 용량을 확인한다.
- 대상 호출 실패는 NetworkPolicy, security group, NAT Gateway, DNS, WAF 허용 목록을 확인한다.
- 결과 로그가 없으면 TestRun cleanup 여부, Pod 종료 시점, 로그 수집 명령의 Pod 이름을 확인한다.

## 정리/후속 조치

- 결과는 `reports/<project>/<yyyymmdd>/`에 저장한다.
- 실행 명령, k6 버전, 이미지 태그, threshold 결과를 함께 기록한다.
- API 테스트와 Browser 테스트 결과는 구분해서 보관한다.
- 결과 디렉터리는 클라우드 object storage 또는 중앙 파일 저장소에 업로드한다.
- NKS 리소스는 결과 수집 후 `K6/infra/cleanup.ps1` 또는 승인된 namespace 정리 절차로 삭제한다.
- 반복 사용 가능한 executor/threshold 조합은 표준 템플릿 환류 대상으로 등록한다.

## 비권고 상황

- 비개발자 중심 조직에서 공통 표준 하나로만 쓰려는 경우
- 레거시 혼합 프로토콜 중심 프로젝트
- 공공기관 고객이 익숙한 GUI 기반 도구를 강하게 요구하는 경우
