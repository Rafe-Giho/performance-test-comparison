# Performance Test Comparison Workspace

이 폴더는 `JMeter`, `nGrinder`, `k6`의 구축, 테스트 스크립트, 배포 파일, 결과 보고서를 함께 관리하는 기준 저장소다.

## 표준 운영 원칙

- 공통 표준 도구: `JMeter`
- 전략 특화 도구: `k6`
- 한시적 운영 자산: `nGrinder`
- 범용적인 가이드와 템플릿을 먼저 만들고, 프로젝트별로 최소 수정해서 재사용한다.
- 프로젝트 산출물보다 `표준 템플릿`, `표준 실행 절차`, `표준 보고 형식`을 먼저 관리한다.

위 원칙은 다음 상황을 전제로 한다.

- 공공기관 고객 비중이 높다.
- 프로젝트마다 고객, 서비스, 수행자가 바뀐다.
- 테스트 인프라는 상시 고정이 아니라 프로젝트별로 만든다.
- 레거시 `WEB-WAS-DB`형 IaaS와 `Kubernetes/MSA`형 클라우드 네이티브 사업이 공존한다.

## 폴더 구조

```text
.
├─ README.md
├─ STANDARD-LOADTEST-GUIDE.md
├─ TEMPLATE-CATALOG.md
├─ docs/
├─ Jmeter/
│  ├─ README.md
│  ├─ SETUP-GUIDE.md
│  ├─ TEST-GUIDE.md
│  ├─ plans/
│  ├─ data/
│  ├─ reports/
│  ├─ scripts/
│  └─ infra/
├─ nGrinder/
│  ├─ README.md
│  ├─ SETUP-GUIDE.md
│  ├─ TEST-GUIDE.md
│  ├─ scripts/
│  ├─ compose/
│  ├─ data/
│  └─ reports/
└─ K6/
   ├─ README.md
   ├─ SETUP-GUIDE.md
   ├─ TEST-GUIDE.md
   ├─ scripts/
   ├─ scenarios/
   ├─ data/
   ├─ reports/
   └─ infra/
```

## 사용 원칙

1. 프로젝트 시작 시 먼저 [STANDARD-LOADTEST-GUIDE.md](./STANDARD-LOADTEST-GUIDE.md)를 읽고 도구를 고른다.
2. 기본 준비 상태와 남은 작업은 [PREP-CHECKLIST.md](./PREP-CHECKLIST.md)에서 먼저 확인한다.
3. 범용 템플릿 목록은 [TEMPLATE-CATALOG.md](./TEMPLATE-CATALOG.md)에서 확인한다.
4. 선택한 도구 폴더에서 `SETUP-GUIDE.md`로 환경을 만들고 `TEST-GUIDE.md`로 실행 절차를 따른다.
5. 새 프로젝트는 기존 템플릿을 복제해서 시작하고, 공통화 가능한 수정은 다시 템플릿에 환류한다.
6. 테스트 산출물은 각 도구 폴더의 `reports/`에 프로젝트명과 날짜 기준으로 정리한다.
7. 실제 배포 파일, Compose, YAML, 스크립트는 각 도구의 `infra/`, `scripts/`, `plans/`, `scenarios/`에 넣는다.
8. 버전은 반드시 고정한다. 실제 구현 시점의 도구 버전과 Java 버전, 이미지 태그를 배포 파일에 명시한다.

## 현재 준비 상태

이 저장소는 `바로 실행 가능한 표준 초안`까지는 준비되어 있다. 다만 실제 프로젝트에 투입하려면 아래 항목은 반드시 각 환경에 맞게 채워야 한다.

- 대상 URL, 계정, 인증 방식
- 테스트 대상별 시나리오와 비율
- 실제 설치 경로, 이미지 태그, 인스턴스 사양
- 모니터링 대상과 결과 저장 위치
- smoke test 1회 이상 실행 결과

즉, `문서`, `샘플 스크립트`, `배포 초안`, `템플릿 구조`는 준비되어 있고, `프로젝트별 환경값 주입`과 `실행 검증`은 아직 사용자 환경에서 마무리해야 한다.

## 템플릿 운영 원칙

- 템플릿은 특정 고객명, 특정 URL, 특정 계정값을 직접 박아 넣지 않는다.
- 환경별 차이는 변수, CSV, 환경변수, 시스템 프로퍼티로 분리한다.
- 공통 흐름은 `health -> login -> list -> detail -> event` 순서의 표준 웹 플로우를 기본 템플릿으로 삼는다.
- 프로젝트 중 재사용 가치가 확인된 스크립트는 고객 전용 파일로 끝내지 말고 범용 템플릿으로 재정리한다.
- 템플릿 수정 시에는 `왜 공통화했는지`, `어떤 프로젝트에서 재사용 가능한지`를 커밋 또는 문서에 남긴다.

## 우선 실행 순서

### 공공기관 IaaS형 웹서비스

- 1순위: `JMeter`
- 보조: `nGrinder`

### 클라우드 네이티브/API 중심 서비스

- 1순위: `k6`
- 보조: `JMeter`

### 단기 즉시 대응 프로젝트

- 1순위: `nGrinder`
- 단, 장기 표준화 대상은 아님

## 참고

- JMeter 공식 문서: <https://jmeter.apache.org/usermanual/index.html>
- JMeter 변경 이력: <https://jmeter.apache.org/changes.html>
- k6 공식 문서: <https://grafana.com/docs/k6/latest/>
- nGrinder 저장소: <https://github.com/naver/ngrinder>
