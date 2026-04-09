# JMeter 구축 가이드

## 적용 대상

- 공공기관 대상 웹서비스
- WEB-WAS-DB형 IaaS 환경
- 테스트 인프라를 프로젝트별로 새로 만드는 경우
- 혼합 프로토콜 또는 레거시 연계가 포함된 경우
- 범용 표준 템플릿을 기준으로 프로젝트를 빠르게 시작해야 하는 경우

## 공식 기준

- JMeter 최신 변경 이력: <https://jmeter.apache.org/changes.html>
- 시작 가이드: <https://jmeter.apache.org/usermanual/get-started.html>
- 원격 테스트: <https://jmeter.apache.org/usermanual/remote-test.html>
- 참고 사항: 공식 문서는 ZIP/TAR 설치와 CLI 실행을 중심으로 설명하며, JMeter는 Java 애플리케이션이라 컨테이너 러너로도 운영 가능하다.

## 권장 버전 정책

- JMeter: 실제 구축 시점의 최신 안정 버전으로 고정
- Java: `Java 17` 권장

## 표준 토폴로지

### 소규모 PoC

- 제어/작성 노드 1대: `2 vCPU / 4 GB / 30~50 GB SSD`
- 엔진 2대: 각 `4 vCPU / 8 GB / 50 GB SSD`

### 중규모 시험

- 제어/작성 노드 1대: `4 vCPU / 8 GB / 50 GB SSD`
- 엔진 3~4대: 각 `8 vCPU / 16 GB / 100 GB SSD`

### 대규모 또는 이벤트성 시험

- 제어/작성 노드 1대: `4~8 vCPU / 8~16 GB / 100 GB SSD`
- 엔진 4~8대: 각 `8 vCPU / 16 GB / 100 GB SSD`

## 규모별 준비 항목

### 소규모

- 단일 엔진 smoke test
- 표준 템플릿 기반 시나리오 1개
- 결과 Dashboard 생성 확인

### 중규모

- 엔진 2대 이상 준비
- 시나리오 비율 정의
- DB/WAS/LB 모니터링 준비

### 대규모

- 엔진 4대 이상 계획
- 테스트 데이터 분리
- 결과 저장 공간과 네트워크 용량 확인
- 긴 시간 테스트 시 로그 롤링과 리포트 용량 확인

## 구축 방식

### 권장 방식

- 작성은 GUI
- 실행은 CLI
- 대규모 시험은 다중 엔진 분산
- 새 프로젝트는 `web-standard-template.jmx`를 복제해 시작

### 컨테이너 방식

- 가능: `예`
- 적합한 용도:
  - headless CLI runner
  - 분산 엔진 컨테이너
  - CI/CD 내 단기 실행
- 비적합한 용도:
  - GUI 작성 환경을 컨테이너로 고정하는 방식
- 실무 권장:
  - `GUI 작성/디버깅은 로컬 또는 VM`
  - `본시험은 Docker 또는 VM의 CLI runner`

### 용어 정리

- `제어/작성 노드`: GUI로 `.jmx`를 만들고 실행을 관리하는 노드
- `실행 러너`: headless CLI로 실제 부하를 발생시키는 노드
- `엔진 노드`: 문맥상 실행 러너와 거의 같은 뜻으로 써도 되지만, 이 가이드에서는 `부하를 실제로 발생시키는 실행 노드`라는 의미로 사용한다.
- 따라서 이번 부가 구축 방식은 `제어/작성 노드`는 컨테이너화하지 않고, `실행 러너(엔진 노드)`만 컨테이너로 올리는 방식이다.

### 비권고 방식

- 운영 서버와 같은 인스턴스에서 실행
- GUI 상태로 장시간 본시험 실행
- `latest` 버전 무고정 배포

## Linux 인스턴스 구축 절차

1. Linux VM 생성
2. Java 17 설치
3. JMeter 바이너리 다운로드 및 압축 해제
4. `JMETER_HOME` 설정
5. `bin/jmeter` 실행 확인
6. 엔진 노드에도 동일 버전 배포
7. 결과 저장 경로와 데이터 경로 생성

## Docker/Container 운영 해석

- JMeter 공식 문서는 Docker를 주요 설치 경로로 전면에 두지 않지만, Java 기반 구조상 컨테이너 실행은 충분히 가능하다.
- 다만 JMeter의 핵심은 `GUI 설계`와 `CLI 실행`이 분리된다는 점이다.
- 따라서 실무에서는 보통 아래처럼 운용한다.
  - 설계자 PC 또는 관리 VM에서 `.jmx` 작성
  - Docker 컨테이너는 `-n` CLI 실행 전용
  - 결과 JTL/HTML은 볼륨 마운트로 외부 저장
- 즉, `JMeter를 Docker로 할 수 있느냐`의 답은 `예`이지만, `전체 운영을 Docker만으로 하는가`의 답은 `보통은 아니다`에 가깝다.

## 부가 구축 방식: 실행 러너만 컨테이너화

현재 저장소에는 실행 러너 전용 컨테이너 구조를 추가했다.

- 위치: `Jmeter/infra/docker-runner/`
- 파일:
  - `Dockerfile`
  - `entrypoint.sh`
  - `docker-compose.yml`
  - `.env.example`
  - `run.ps1`

### 이 구조의 의도

- `.jmx` 설계와 수정은 기존처럼 로컬/VM에서 진행
- 실제 부하 발생은 Docker 컨테이너 1개가 headless CLI로 수행
- 결과는 호스트의 `Jmeter/reports/`에 그대로 남김

### 이 방식이 적합한 경우

- 빠르게 단일 러너를 띄워 smoke/load 테스트를 하고 싶을 때
- CI/CD에서 재현 가능한 실행 환경이 필요할 때
- 개발/테스트용 러너 이미지를 표준화하고 싶을 때

### 사용 방법

1. `Jmeter/infra/docker-runner/.env.example`를 `.env`로 복사
2. `HOST`, `PORT`, `THREADS`, `LOOPS`, `PLAN_FILE` 등을 수정
3. `Jmeter/infra/docker-runner/run.ps1` 실행
4. 결과는 `Jmeter/reports/<REPORT_SUBDIR>/`에 생성

### 주의사항

- 이 구조는 `실행 러너 1개` 기준이다.
- 다중 분산 엔진 구조까지 컨테이너화하려면 별도 확장이 필요하다.
- `GUI 작성 환경`은 이 구조에 포함되지 않는다.

## 표준 디렉터리 매핑

- 테스트 플랜: `plans/`
- CSV 데이터: `data/`
- 결과 리포트: `reports/<project>/<yyyymmdd>/`
- 실행 스크립트: `scripts/`
- 인프라 메모: `infra/`

## 템플릿 적용 원칙

- 새 프로젝트는 템플릿을 직접 수정하지 말고 복제본으로 시작한다.
- 공통값은 JMeter 프로퍼티로 주입한다.
- 고객별 URL, 계정, path는 `.jmx`에 하드코딩하지 않고 변수화한다.
- 프로젝트에서 반복 검증된 구조는 템플릿 원본에 환류한다.

## 원격/분산 운영 원칙

- 모든 엔진은 같은 JMeter 버전을 사용한다.
- 테스트 플랜은 엔진 수만큼 동일하게 실행되므로 총 부하는 선형 증가한다고 가정한다.
- 본시험 전 반드시 단일 엔진 smoke test를 수행한다.
- 엔진 CPU 80% 이상이면 인스턴스를 키우기보다 엔진 수를 늘리는 것을 먼저 검토한다.

## 기본 검증 항목

1. GUI 실행 확인
2. CLI 실행 확인
3. CSV 결과 파일 생성 확인
4. HTML Dashboard 생성 확인
5. 다중 엔진 시 네트워크 통신 확인

## 구축 완료 기준

- JMeter GUI/CLI가 정상 실행된다.
- 샘플 플랜이 단일 엔진에서 정상 완료된다.
- HTML Dashboard가 생성된다.
- 결과 로그가 `reports/`에 정리된다.
