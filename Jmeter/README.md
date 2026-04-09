# JMeter Workspace

이 폴더는 `JMeter` 기반 부하테스트 자산을 관리한다.

## 역할

- 조직 공통 표준 도구
- 공공기관 대상 기본 웹서비스 테스트
- WEB-WAS-DB형 IaaS 프로젝트
- 혼합 프로토콜 테스트
- 범용 표준 가이드와 템플릿의 기준 도구
- `VM 또는 인스턴스 직접 설치`를 기본으로 쓰는 도구
- 컨테이너는 필요 시 `실행 러너`에 한해 부가적으로 쓰는 도구

## 폴더 용도

- `plans/`: `.jmx` 테스트 플랜
- `data/`: CSV 데이터셋, 파라미터 파일
- `reports/`: HTML Dashboard, 결과 보고서
- `scripts/`: 실행 배치, 보조 스크립트
- `infra/`: 인스턴스 구축 메모, 배포 파일, Terraform/Ansible 등

## 표준 템플릿

- `plans/web-standard-template.jmx`
- `scripts/run-local.ps1`
- `scripts/run-distributed.ps1`
- `scripts/generate-report.ps1`
- `infra/docker-runner/docker-compose.yml`
- `infra/docker-runner/Dockerfile`

## 먼저 읽을 문서

1. [SETUP-GUIDE.md](./SETUP-GUIDE.md)
2. [TEST-GUIDE.md](./TEST-GUIDE.md)

## 표준 포지션

- 기본 선택: `예`
- 전략 특화: `아님`
- 장기 유지보수: `적합`

## 기초 용어

- `Test Plan`: 전체 테스트 구조를 담는 최상위 문서
- `Thread Group`: 가상 사용자 수와 ramp-up, loop를 정의하는 구간
- `Sampler`: 실제 요청을 보내는 요소
- `Config Element`: 기본 URL, CSV, Header 같은 공통 설정
- `Listener`: 결과를 수집하거나 보여주는 요소
- `Assertion`: 응답이 기대값과 맞는지 검증하는 조건
- `JTL`: 실행 결과 원본 파일
- `HTML Dashboard`: JTL을 기반으로 생성하는 보고서

## 동작 원리

- JMeter는 `Thread Group` 안에서 여러 가상 사용자가 같은 시나리오를 반복 실행하는 구조다.
- 각 Thread는 독립된 사용자처럼 동작하고, Sampler 순서대로 요청을 보낸다.
- 분산 실행 시에는 같은 Test Plan이 여러 엔진에서 동시에 실행된다.
- 따라서 엔진 수를 늘리면 총 부하가 선형에 가깝게 증가한다고 보고 설계한다.

## 알아야 하는 기본 지식

- GUI는 작성과 디버깅에 쓰고, 본시험은 CLI로 실행하는 것이 원칙이다.
- Listener를 과하게 켜면 부하발생기 자체가 느려질 수 있다.
- CSV 데이터, 쿠키, 세션, 토큰 추출 같은 상태 관리가 실제 성능시험 품질을 좌우한다.
- `동시 사용자 수`만 보지 말고 `응답시간`, `에러율`, `서버 자원`, `DB 병목`을 같이 봐야 한다.
- JMeter는 Java 기반이라 Docker 컨테이너에서도 실행 가능하지만, 이 저장소 기준 기본 구축은 `VM 또는 인스턴스 직접 설치`다.
- 컨테이너는 `실행 러너`를 빠르게 표준화하거나 보조 실행할 때만 붙이는 부가 방식으로 본다.
