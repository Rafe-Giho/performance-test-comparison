# JMeter 테스트 수행 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 기본 원칙

- 공통 표준 시험은 JMeter를 기본으로 수행한다.
- 작성은 GUI로 하되, 제출용 또는 반복 시험은 반드시 CLI로 실행한다.
- 결과 제출은 HTML Dashboard를 기본 증빙으로 사용한다.
- 모든 신규 시나리오는 표준 템플릿에서 시작한다.

## 실행 전제

- [SETUP-GUIDE.md](./SETUP-GUIDE.md)의 구축 완료 기준을 만족한다.
- 표준 플랜 복제본과 실제 대상 환경값이 준비되어 있다.
- 테스트 계정, CSV 데이터, 대상 URL, 이벤트 payload가 승인된 값이다.
- 대상 시스템의 CPU, 메모리, 네트워크, DB 지표를 함께 수집할 수 있다.
- 클라우드 보안그룹, NACL, 라우팅 테이블, DNS가 제어 노드, 엔진 노드, 대상 시스템 기준으로 검증되어 있다.
- 분산 실행은 엔진 노드 private IP 또는 private DNS만 사용한다.
- 본시험 전 단일 엔진 smoke test를 완료한다.

## 실행 전에 알아야 하는 기초 지식

- `Thread`는 실제 사람 수와 1:1로 같지 않을 수 있다. Think time과 응답시간에 따라 체감 부하는 달라진다.
- `Ramp-up`은 한 번에 사용자를 때리는 것이 아니라 일정 시간에 걸쳐 올리는 값이다.
- `Loop`는 사용자 한 명이 시나리오를 몇 번 반복하는지 의미한다.
- `Assertion`은 너무 많이 걸면 부하발생기 자원을 더 쓴다.
- `Listener`는 디버깅용과 본시험용을 분리해야 한다.

## 실무에서 중요한 원리

- 공공기관 홈페이지 테스트는 보통 `조회 -> 로그인 -> 검색/목록 -> 상세 -> 핵심 액션` 흐름으로 나눈다.
- 시나리오별 비율을 정하지 않으면 현실과 다른 테스트가 된다.
- JMeter는 기능 검증 도구가 아니라 부하발생기이므로, 응답 본문을 과도하게 파싱하면 오히려 부하발생기가 병목이 된다.

## 표준 시나리오 흐름

1. 접속
2. 로그인
3. 목록 조회
4. 상세 조회
5. 핵심 기능 호출
6. 종료

## 표준 준비 절차

1. 표준 템플릿 복제
2. 대상 URL, API 목록, 인증 방식 수집
3. 테스트 구간 확정
4. 사용자 시나리오 정의
5. CSV 데이터 준비
6. Think time과 assertion 규칙 정의
7. 성공 기준 확정

## 표준 부하 패턴

### Smoke

- 목적: 연결과 기능 확인
- 시간: 1~5분
- 사용자 수: 소수

### Load

- 목적: 목표 정상 운영 부하 검증

### Stress

- 목적: 한계점 탐색

### Spike

- 목적: 급격한 트래픽 증가 대응 확인

### Soak

- 목적: 장시간 안정성 확인

## 실행 순서

1. GUI에서 플랜 작성 또는 수정
2. 단일 엔진 smoke test
3. CSV 결과 확인
4. 분산 엔진 대상 load/stress/spike/soak 실행
5. Dashboard 생성
6. 리포트 해석 및 병목 분석

## 실행 Runbook

### 1. 클라우드 네트워크 사전 확인

제어 노드에서 각 엔진 노드와 대상 시스템 접근성을 확인한다.

```powershell
Test-NetConnection <engine-private-ip-1> -Port 1099
Test-NetConnection <engine-private-ip-1> -Port 50000
Test-NetConnection <target-private-or-public-dns> -Port 443
```

Linux 제어 노드에서는 아래처럼 확인한다.

```bash
nc -vz <engine-private-ip-1> 1099
nc -vz <engine-private-ip-1> 50000
nc -vz <target-private-or-public-dns> 443
```

엔진에서 제어 노드로 되돌아오는 RMI 포트도 확인한다.

```bash
nc -vz <control-private-ip> 51000
```

### 2. 단일 엔진 smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\Jmeter\scripts\run-local.ps1 `
  -ProjectName "<project-name>" `
  -JMeterHome "C:\tools\apache-jmeter-5.6.3" `
  -Protocol "https" `
  -Host "<actual-host>" `
  -Port 443 `
  -Threads 1 `
  -RampUp 0 `
  -Loops 1 `
  -ThinkTimeMs 0 `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

### 3. 클라우드 분산 smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\Jmeter\scripts\run-distributed.ps1 `
  -ProjectName "<project-name>" `
  -JMeterHome "C:\tools\apache-jmeter-5.6.3" `
  -RemoteHosts "<engine-private-ip-1>,<engine-private-ip-2>" `
  -ClientRmiLocalPort 51000 `
  -Protocol "https" `
  -Host "<actual-host>" `
  -Port 443 `
  -Threads 1 `
  -RampUp 0 `
  -Loops 1 `
  -ThinkTimeMs 0 `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

분산 본시험은 위 smoke 성공 후 같은 `RemoteHosts`와 실제 부하 수치로 실행한다.

## 성공/실패 판정

- smoke는 모든 sampler가 기대 HTTP status를 만족하고 JTL/HTML 결과가 생성되면 성공이다.
- 본시험은 합의한 P95/P99, 에러율, TPS, APDEX 기준을 만족해야 성공이다.
- 부하발생기 CPU가 병목이면 대상 시스템 결과로 판정하지 않는다.
- 인증 실패, 4xx/5xx 급증, Dashboard 생성 실패는 실패로 처리하고 재시험한다.

## 결과 산출물

## 필수 결과 항목

- 평균 응답시간
- P90/P95/P99
- 에러율
- TPS
- APDEX
- 테스트 중 CPU/메모리/네트워크
- 병목 구간

## 결과 저장 규칙

- 플랜: `plans/<project>-<scenario>.jmx`
- 데이터: `data/<project>-<dataset>.csv`
- 실행 결과: `reports/<project>/<yyyymmdd>/`
- 클라우드 장기 보관: 프로젝트 표준 object storage 또는 파일 저장소에 `reports/<project>/<yyyymmdd>/` 전체를 업로드

## 템플릿 환류 규칙

- 2개 이상 프로젝트에서 반복된 sampler 구조는 표준 템플릿으로 올린다.
- 특정 고객 전용 assertion은 템플릿에 남기지 않는다.

## 장애 조치

- 실행 전 실패하면 필수 인자 누락, JMeter 설치 경로, Java 실행 여부를 먼저 확인한다.
- 응답이 모두 실패하면 host/path, 프로토콜, 포트, 방화벽, 인증 방식을 확인한다.
- JTL은 생성됐지만 HTML이 없으면 `generate-report.ps1`로 리포트 생성을 다시 수행한다.
- 분산 실행이 연결 단계에서 실패하면 security group, NACL, route table, RMI reverse port `51000/tcp`, 엔진 private IP 사용 여부를 확인한다.
- 분산 실행 결과가 기대보다 낮으면 엔진별 CPU/메모리와 클라우드 NIC 대역폭, 대상 LB/WAF 제한을 확인한다.

## 정리/후속 조치

- 결과는 `reports/<project>/<yyyymmdd>/`에 보관한다.
- 실행에 사용한 `.jmx`, CSV, 명령어, 버전 정보를 결과와 함께 남긴다.
- 병목 분석과 개선 권고를 보고서에 기록한다.
- 재사용 가능한 sampler, assertion, property 구조는 표준 템플릿 환류 대상으로 등록한다.

## 적합한 시험

- 전통적 웹서비스 사용자 몰림
- 공공기관 제출용 기본 성능시험
- 레거시/혼합 프로토콜 환경
- GUI 기반 표준 절차가 필요한 조직

## 비권고 시험

- 클라우드 네이티브 API 회귀 테스트를 CI에 상시 넣는 경우
- browser/hybrid가 핵심인 경우
