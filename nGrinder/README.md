# nGrinder Workspace

이 폴더는 클라우드 기반 테스트 환경에서 한시적으로 운영하는 `nGrinder` 자산을 관리한다.

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 역할

- 단기 즉시 대응용 웹 UI 기반 부하 테스트 플랫폼
- `Controller 1 + Agent N` Compose 운영 자산
- private subnet에서 대상 시스템에 부하를 발생시키는 보조 도구
- JMeter 또는 k6 표준 결과를 보완하는 단기 실행 증빙
- archive 상태 도구를 통제된 범위에서 재사용하기 위한 템플릿

## 폴더 용도

- `compose/`: Docker Compose, 기동/정리 스크립트
- `scripts/`: nGrinder Groovy 표준 스크립트
- `data/`: 테스트 데이터
- `reports/`: 결과 리포트와 object storage 업로드 전 산출물

## 표준 템플릿

- `compose/docker-compose.yml`: `ngrinder/controller:3.5.9-p1`, `ngrinder/agent:3.5.9-p1` 고정 Compose
- `compose/up.ps1`: PowerShell 기반 Controller/Agent 기동 wrapper
- `compose/down.ps1`: PowerShell 기반 Compose 정리 wrapper
- `scripts/web_standard_template.groovy`: `health -> login -> list -> detail -> event` 표준 흐름

## 먼저 읽을 문서

1. [SETUP-GUIDE.md](./SETUP-GUIDE.md)
2. [TEST-GUIDE.md](./TEST-GUIDE.md)

## 운영 포지션

- 기본 선택: `단기 즉시 대응 프로젝트에서만 예`
- 전략 특화: `아님`
- 장기 유지보수: `제한`
- 표준 증빙 기준: JMeter 또는 k6 결과와 함께 보조 증빙으로만 사용

## 배포 전 확인

- Controller VM은 private subnet에 있고 Controller UI `8080/tcp`는 VPN 또는 bastion에서만 접근된다.
- Agent security group에서 Controller `16001/tcp`, `12000-12009/tcp` 접근이 허용되어 있다.
- `docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml config`가 통과한다.
- Controller/Agent 이미지 태그가 `3.5.9-p1`로 고정되어 있다.
- Agent 서비스에 고정 `container_name` 또는 공유 Agent home volume이 없다.
- 결과 저장 경로 `reports/<project>/<yyyymmdd>/`와 object storage 보관 정책이 정해져 있다.
- 루트에서 `powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict`가 통과한다.

## 기초 용어

- `Controller`: 사용자, 프로젝트, 스크립트, 실행 제어를 담당하는 중앙 서버
- `Agent`: 실제 부하를 발생시키는 실행 노드
- `Vuser`: nGrinder의 가상 사용자이며 실질적으로 총 thread 수에 가깝다.
- `Script`: 테스트 로직을 담은 Groovy/Jython 코드
- `Monitor`: 대상 시스템 자원 상태를 수집하는 선택 구성요소
- `Security group`: Controller UI와 Agent 통신 포트를 제한하는 클라우드 방화벽 단위

## 동작 원리

- 운영자는 Controller UI에 접속해 스크립트와 테스트를 관리한다.
- Controller는 선택된 Agent에 스크립트와 실행 정보를 전달한다.
- Agent는 대상 시스템에 실제 HTTP 요청을 생성하고 결과를 Controller로 보낸다.
- Controller 볼륨에는 스크립트와 결과가 남으므로 프로젝트 종료 후 보관 또는 폐기한다.

## 알아야 하는 기본 지식

- Agent 수를 늘리면 부하를 쉽게 올릴 수 있지만 Controller도 같이 버텨야 한다.
- `vuser`는 thread와 가까운 개념이라 Agent 메모리와 JVM 설정에 따라 상한이 달라진다.
- 단일 고사양 VM 통합 운영은 빠르지만 Controller와 Agent의 자원 간섭이 생긴다.
- nGrinder는 `2025-09-24` 이후 archive 상태이므로 장기 표준 도구가 아니다.
