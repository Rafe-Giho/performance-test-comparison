# nGrinder 테스트 수행 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 기본 원칙

- nGrinder는 단기 즉시 대응 프로젝트에서만 사용한다.
- 장기 표준 증빙은 JMeter 또는 k6 결과를 기준으로 남기고, nGrinder 결과는 보조 증빙으로 분류한다.
- Controller UI는 VPN 또는 bastion 경유로만 접근한다.
- Agent는 private subnet에서 실행하고, 대상 시스템으로 승인된 포트만 호출한다.
- 모든 테스트는 smoke 성공 후 Load, Stress, Spike, Soak 순서로 단계 확장한다.

## 실행 전제

- [SETUP-GUIDE.md](./SETUP-GUIDE.md)의 구축 완료 기준을 만족한다.
- Controller/Agent 이미지는 `3.5.9-p1` 고정 태그를 사용한다.
- `docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml ps`에서 Controller와 Agent가 실행 중이다.
- Controller UI Agent Management에서 Agent 연결이 확인되어 있다.
- `test.baseUrl`, `test.healthPath`, `test.loginPath`, `test.listPath`, `test.detailPath`, `test.eventPath`, `test.eventPayload`, `test.username`, `test.password`가 승인된 실제 값으로 준비되어 있다.
- 대상 시스템, Agent VM, Controller VM의 CPU, 메모리, 네트워크 지표를 볼 수 있다.
- 결과 저장 경로 `nGrinder/reports/<project>/<yyyymmdd>/`와 object storage 보관 위치가 정해져 있다.

## 표준 시나리오 흐름

1. `health`: 대상 서비스 기본 응답 확인
2. `login`: 승인된 테스트 계정 인증
3. `list`: 목록 또는 검색 API 호출
4. `detail`: 상세 API 호출
5. `event`: 핵심 쓰기 또는 이벤트 API 호출

표준 Groovy 템플릿은 `nGrinder/scripts/web_standard_template.groovy`다. 원본에는 고객별 URL, 계정, payload를 저장하지 않는다.

## 실행 Runbook

### 1. 환경 상태 확인

```powershell
docker compose -p ngrinder -f .\nGrinder\compose\docker-compose.yml ps
docker compose -p ngrinder -f .\nGrinder\compose\docker-compose.yml logs --tail=100 controller
docker compose -p ngrinder -f .\nGrinder\compose\docker-compose.yml logs --tail=100 agent
```

Linux VM에서는 아래처럼 실행한다.

```bash
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml ps
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml logs --tail=100 controller
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml logs --tail=100 agent
```

### 2. Controller UI 준비

1. VPN 또는 bastion 경유로 `http://<controller-vm-private-ip>:8080`에 접속한다.
2. 초기 `admin/admin` 계정을 사용하는 경우 즉시 비밀번호를 변경한다.
3. 프로젝트를 생성한다.
4. Agent Management에서 Agent 연결 상태와 수량을 확인한다.

### 3. 표준 스크립트 등록

1. `nGrinder/scripts/web_standard_template.groovy`를 프로젝트 전용 스크립트로 복제한다.
2. Controller UI에 스크립트를 업로드한다.
3. 아래 system property를 실제 값으로 설정한다.

| Key | 값 기준 |
| --- | --- |
| `test.baseUrl` | 승인된 대상 서비스 URL |
| `test.healthPath` | health endpoint path |
| `test.loginPath` | login endpoint path |
| `test.listPath` | list/search endpoint path |
| `test.detailPath` | detail endpoint path |
| `test.eventPath` | event/action endpoint path |
| `test.eventPayload` | 유효한 JSON 문자열 |
| `test.username` | 승인된 테스트 계정 |
| `test.password` | 승인된 테스트 계정 비밀번호 |

### 4. Smoke 실행

- Agent: `1`
- vuser: 낮은 값으로 시작
- duration: 짧게 설정
- 목표: 표준 시나리오의 HTTP status와 스크립트 컴파일 확인

Smoke 실패 시 Load 테스트로 넘어가지 않는다.

### 5. 본시험 실행

Smoke 성공 후 아래 순서로 진행한다.

| 단계 | 목적 | 중단 기준 |
| --- | --- | --- |
| Load | 목표 TPS/동시 사용자 검증 | 에러율 또는 응답시간 기준 초과 |
| Stress | 한계 지점 탐색 | 대상 또는 Agent 자원 포화 |
| Spike | 급증 트래픽 내성 확인 | 오류 급증 또는 회복 실패 |
| Soak | 장시간 안정성 확인 | 메모리 증가, 연결 누수, 에러 누적 |

Agent 수를 늘릴 때는 `docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml up -d --scale agent=<count> --remove-orphans`로 확장하고 UI에서 연결 수를 다시 확인한다.

## 성공/실패 판정

- smoke는 `health -> login -> list -> detail -> event` 모든 단계가 기대 HTTP status를 만족하면 성공이다.
- 본시험은 사전에 합의한 TPS, 응답시간, 에러율, 자원 사용률 기준을 만족해야 성공이다.
- Controller 또는 Agent 자원 병목이 확인되면 대상 시스템 성능 판정에서 제외한다.
- Agent 연결 끊김, 스크립트 컴파일 실패, 테스트 중단, 결과 저장 실패는 실패로 처리한다.
- archive 상태 도구의 한계로 재현성 문제가 있으면 JMeter 또는 k6로 교차 검증한다.

## 결과 산출물

- nGrinder 결과 화면 캡처 또는 export 파일
- 실행한 Groovy 스크립트 사본
- Agent 수, vuser, duration, ramp-up 설정
- Controller/Agent VM 사양과 실행 중 자원 사용량
- 대상 시스템 CPU, 메모리, 네트워크, DB 지표
- 에러 로그와 병목 분석
- `nGrinder/reports/<project>/<yyyymmdd>/` 저장본
- object storage 장기 보관본

## 장애 조치

- 스크립트 컴파일 오류는 Groovy 문법, property 이름, JSON payload 형식을 확인한다.
- Agent가 보이지 않으면 Compose 상태, Controller 주소, `16001/tcp`, `12000-12009/tcp`, security group을 확인한다.
- TPS가 기대보다 낮으면 Agent CPU/메모리와 Controller 부하를 먼저 분리한다.
- 응답시간이 급등하면 대상 시스템 지표와 Agent 네트워크 지표를 동시에 확인한다.
- 결과 저장이 누락되면 Controller 볼륨과 디스크 사용량을 확인한다.
- 테스트 중 Controller UI가 느려지면 Agent 수를 줄이고 Controller VM 사양을 증설한다.

## 정리/후속 조치

```powershell
powershell -ExecutionPolicy Bypass -File .\nGrinder\compose\down.ps1 -ProjectName ngrinder
```

Linux VM에서는 아래 명령을 사용한다.

```bash
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml down
```

정리 기준은 아래와 같다.

- 결과 파일은 `nGrinder/reports/<project>/<yyyymmdd>/`에 저장한다.
- 장기 보관 대상은 object storage로 복제한다.
- Controller에 남은 고객 전용 스크립트와 계정값은 프로젝트 종료 기준에 따라 삭제한다.
- 재사용 가능한 Groovy 구조만 표준 템플릿에 환류한다.
- 최종 보고서에는 nGrinder archive 상태와 한시 운영 리스크를 명시한다.

## 사용 제한

- 신규 장기 표준 증빙 문서는 nGrinder 중심으로 작성하지 않는다.
- Controller UI를 공인 인터넷에 직접 노출하지 않는다.
- 고객별 계정, URL, payload를 표준 템플릿 파일에 커밋하지 않는다.
- 멀티테넌트 상시 부하 테스트 플랫폼으로 운영하지 않는다.
