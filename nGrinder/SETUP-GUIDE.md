# nGrinder 구축 가이드

## 적용 대상

- 즉시 구축이 우선인 단기 프로젝트
- 웹 UI 기반 테스트 운영이 필요한 경우
- 이미 보유한 `Controller 1 + Agent 10` Compose 자산을 활용할 수 있는 경우
- 범용 Compose 템플릿으로 빠르게 동일 구조를 재현해야 하는 경우

## 공식 기준

- 저장소: <https://github.com/naver/ngrinder>
- 릴리스: <https://github.com/naver/ngrinder/releases>
- 설치 가이드: <https://github.com/naver/ngrinder/wiki/Installation-Guide>
- 아키텍처: <https://github.com/naver/ngrinder/wiki/Architecture>
- 설치 가이드는 Docker 실행을 직접 언급한다.

## 중요한 전제

- nGrinder 저장소는 archive 상태이므로 장기 표준 도구로 보지 않는다.
- 이 가이드는 현재 보유 자산을 단기적으로 활용하기 위한 운영 문서다.

## Docker 기반 운영

- 가능: `예`
- nGrinder는 Controller와 Agent 역할이 분리돼 있어 컨테이너 운영과 궁합이 좋다.
- 실무에서는 `Controller 1 + Agent N` 구성을 Docker Compose로 올리는 방식이 흔하다.
- 즉, `nGrinder를 Docker container로 할 수 있나`의 답은 `공식적으로도 예`다.

## 표준 토폴로지

아래 사양은 `Controller 1개`, `Agent 1개` 기준이다. 전체 환경의 합산 사양이 아니다.

### 최소 시작 구성

- Controller 1대: `2 vCPU / 4 GB / 50 GB SSD`
- Agent 2대 이상: 각 `4 vCPU / 8 GB / 50 GB SSD`

### 권장 구성

- Controller 1대: `4 vCPU / 8 GB / 100 GB SSD`
- Agent 3~5대: 각 `8 vCPU / 16 GB / 100 GB SSD`

### 대규모 또는 이벤트성 시험

- Controller 1대: `4~8 vCPU / 8~16 GB / 100 GB SSD`
- Agent 4~6대 이상: 각 `8 vCPU / 16 GB / 100 GB SSD`
- 또는 `16~32 vCore / 32 GB 이상` 단일 고사양 인스턴스 + 필요 시 보조 Agent

## 단일 고사양 인스턴스 통합 운영 해석

실무에서는 `Controller`와 `Agent`를 별도 인스턴스로 분리하지 않고, 고사양 인스턴스 1대에 함께 올려서 사용하는 경우가 있다. 이 방식 자체는 가능하다.

예를 들어 아래처럼 해석한다.

- 표 기준 최소 합산
  - Controller 1개: `2 vCPU / 4 GB`
  - Agent 1개: `4 vCPU / 8 GB`
  - 합산 최소치: `6 vCPU / 12 GB`
- 안정적 시작 권장
  - Controller + Agent 동거 시 `8 vCPU / 16 GB` 이상
- Agent heap을 크게 주고 장시간 테스트를 돌린다면
  - `16 vCPU / 32 GB` 이상 단일 인스턴스도 충분히 현실적인 구성이다.

즉, `16 vCore / 32 GB RAM` 인스턴스 1대에서 `Controller + Agent`를 같이 올려 문제 없이 사용했다면, 그것은 표와 충돌하는 것이 아니라 오히려 `최소 시작 사양보다 훨씬 큰 단일 통합 구성`으로 이해하면 된다.

## 현재 구성 해석 시 주의사항

다음 조건은 별도로 점검해야 한다.

- `container_name: ngrinder-agent`
  - 이 설정이 있으면 동일 서비스 다중 스케일에 제약이 생긴다. 여러 agent를 띄우려면 보통 고정 `container_name`은 제거하는 편이 맞다.
- `image: latest`
  - 표준 운영 기준에서는 비권고다. 반드시 태그를 고정한다.
- `deploy.resources`
  - Compose 사양에서 `deploy`는 플랫폼 의존적인 항목이다. 로컬 `docker compose up` 환경에서는 기대한 방식으로 강제되지 않을 수 있으므로 실제 적용 여부를 확인해야 한다.
- CPU/메모리 수치 해석
  - 작성하신 예시는 주석상 `32 CPU / 32 GB`에 가깝다. 만약 실제 인스턴스가 `16 vCore / 32 GB`였다면 `cpus: '30.0'` 주석과는 맞지 않으므로 현재 운영값을 다시 확인하는 것이 좋다.

## 현재 운영 예시의 의미

질문에 제시된 예시는 다음처럼 해석하면 된다.

- `Controller + Agent`를 단일 인스턴스 1대에 함께 올리는 통합 운영 방식
- 최소 사양을 겨우 맞춘 구성이 아니라, 단일 호스트에 자원을 크게 몰아준 고사양 구성
- `GRINDER_JVM_OPTS=-Xms20G -Xmx20G`는 Agent heap을 크게 설정해 장시간 테스트나 많은 worker thread를 안정적으로 받기 위한 설정
- `limits.memory: 24G`는 컨테이너 상한을 둔 것이고, 나머지 메모리는 Controller와 OS, Docker가 사용

즉, 아래 조건이라면 현재 구성이 문제 없이 동작한 것은 충분히 자연스럽다.

- 실제 호스트가 `32 vCore / 32 GB RAM`급
- Agent 수가 많지 않거나, Agent 컨테이너를 1개만 크게 운영
- 테스트 대상이 주로 웹/API 중심

반대로 아래 경우에는 별도 재검토가 필요하다.

- 실제 호스트가 `16 vCore / 32 GB`인데 `cpus: '30.0'`처럼 작성돼 있는 경우
- Agent를 여러 개로 수평 확장하려는데 `container_name`이 고정된 경우
- `latest` 이미지 사용으로 버전 재현성이 깨지는 경우

## Compose 기반 구축 원칙

- 기본 자산은 `Controller 1 + Agent 10` 구조를 기준으로 관리한다.
- 프로젝트 규모에 따라 Agent 수를 줄이거나 늘린다.
- 운영과 분리된 테스트 전용 네트워크에서 실행한다.
- 프로젝트별로 새 Compose를 처음부터 만들지 말고 범용 Compose 템플릿을 조정해서 사용한다.

## 규모별 준비 항목

### 소규모

- Controller 1 + Agent 1~2
- 샘플 스크립트 smoke test
- Agent 승인과 연결 확인

### 중규모

- Agent 2~4
- 대상 시스템 모니터링 연동
- 포트 범위와 동시 테스트 수 확인

### 대규모

- Agent 4대 이상 또는 단일 고사양 호스트
- Controller 저장소, 로그, 결과 보관 용량 확인
- Agent heap, OS ulimit, sysctl 값 조정

## 구축 절차

1. 테스트용 인스턴스 또는 Docker 호스트 준비
2. `compose/`에 프로젝트별 Compose 파일 배치
3. Controller 기동
4. Agent 기동 및 Controller 연결 확인
5. 계정, 프로젝트, 스크립트 저장소 확인
6. 샘플 스크립트 smoke test 수행

## 네트워크/운영 주의

- Controller와 Agent 간 포트 정책을 사전에 확인한다.
- 프로젝트 종료 후 환경 철수 절차를 포함한다.
- 여러 프로젝트가 동시에 돌면 Controller 사양을 먼저 증설한다.

## 표준 디렉터리 매핑

- Compose 파일: `compose/`
- 테스트 스크립트: `scripts/`
- 데이터셋: `data/`
- 결과 리포트: `reports/<project>/<yyyymmdd>/`

## 템플릿 적용 원칙

- Compose 원본은 공통 구조를 유지한다.
- 프로젝트별 변경은 scale, 볼륨, 포트, 자원 수준에 한정한다.
- Groovy 스크립트는 baseUrl, path, 계정값만 바꿔서 재사용한다.

## 구축 완료 기준

- Controller UI 접속 가능
- Agent 연결 확인
- 샘플 테스트 정상 실행
- 결과 리포트 확인
