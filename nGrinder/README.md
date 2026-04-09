# nGrinder Workspace

이 폴더는 `nGrinder` 기반 자산을 관리한다.

## 역할

- 한시적 운영 자산
- 즉시 가동 가능한 웹 UI 기반 부하테스트 플랫폼
- 단기 프로젝트 대응
- 보유 자산을 템플릿화해 빠르게 재사용하는 도구
- Controller/Agent를 컨테이너로 올리기 쉬운 도구

## 주의사항

- 장기 표준 도구로 채택하지 않는다.
- 신규 표준화 대상이 아니라 현재 보유 자산 활용 대상이다.
- 다만 단기 재사용을 위해 Compose와 스크립트는 범용 템플릿 형태로 관리한다.

## 폴더 용도

- `scripts/`: nGrinder 스크립트
- `compose/`: Docker Compose, 배포 파일
- `data/`: 테스트 데이터
- `reports/`: 결과 리포트

## 표준 템플릿

- `compose/docker-compose.yml`
- `compose/up.ps1`
- `scripts/web_standard_template.groovy`

## 먼저 읽을 문서

1. [SETUP-GUIDE.md](./SETUP-GUIDE.md)
2. [TEST-GUIDE.md](./TEST-GUIDE.md)

## 기초 용어

- `Controller`: 사용자, 프로젝트, 스크립트, 실행 제어를 담당하는 중앙 서버
- `Agent`: 실제 부하를 발생시키는 실행 노드
- `Vuser`: nGrinder에서 말하는 가상 사용자. 실질적으로는 총 thread 개념에 가깝다.
- `Script`: 테스트 로직을 담은 Groovy/Jython 코드
- `Monitor`: 대상 시스템 자원 상태를 수집하는 구성요소
- `Region`: 다중 지역 또는 클러스터 구분 단위

## 동작 원리

- 사용자는 Controller에 접속해 스크립트를 관리하고 테스트를 시작한다.
- Controller는 선택된 Agent에 스크립트와 실행 정보를 전달한다.
- Agent는 실제 HTTP 요청을 생성하고 결과를 Controller로 보낸다.
- 따라서 nGrinder는 `중앙 관리 플랫폼 + 분산 부하 발생기` 구조로 이해하면 된다.

## 알아야 하는 기본 지식

- Agent 수를 늘리면 부하를 쉽게 올릴 수 있지만, Controller도 같이 버텨야 한다.
- `vuser`는 thread와 가까운 개념이라, 메모리 크기에 따라 현실적인 상한이 달라진다.
- nGrinder는 즉시성은 좋지만 장기 유지보수 리스크가 있다는 점을 항상 구분해서 봐야 한다.
- nGrinder는 공식 설치 가이드에서 Docker 실행을 직접 언급할 만큼 Controller/Agent 컨테이너화가 자연스러운 도구다.
