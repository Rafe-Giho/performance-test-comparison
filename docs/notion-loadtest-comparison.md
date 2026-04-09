# 부하 테스트 도구 비교 분석

- 작성 목적: JMeter, nGrinder, k6를 1차 PoC 후보로 비교해 조직 표준 또는 우선 검토 대상을 정리
- 기준일: 2026-03-26
- 검증 기준: 공식 문서, 공식 릴리스 페이지, 공식 프로젝트 페이지

## 빠른 결론

| 도구 | 한 줄 결론 | 우선 추천 상황 | 주의사항 |
| --- | --- | --- | --- |
| JMeter | 가장 범용적인 프로토콜 커버리지와 GUI 기반 작성 경험이 강점 | HTTP 외에 JDBC, JMS, FTP, Mail 등 혼합 프로토콜 테스트가 필요한 경우 | 대규모 분산 운영은 수동 설정 부담이 있고, 웹 브라우저 자체를 실행하는 도구는 아님 |
| nGrinder | 중앙집중형 웹 UI와 Controller-Agent 구조가 강점 | 사내 공용 부하 테스트 플랫폼을 운영하고, 에이전트 기반 분산 실행을 선호하는 경우 | 신규 표준 후보로 보기에는 유지보수 리스크가 큼. GitHub 저장소가 2025-09-24에 archive됨 |
| k6 | 코드 기반, CI/CD 적합성, JS/TS 친화성, Threshold 기반 자동 판정이 강점 | API 중심, DevOps 중심, Git 기반 협업과 파이프라인 자동화를 중시하는 경우 | OSS에서 대규모 분산 실행을 하려면 별도 운영 체계가 필요하며, GUI 기반 레코딩 경험은 JMeter보다 약함 |

## 현재 상태 요약

- JMeter: 공식 변경 이력 페이지 기준 현재 버전은 `5.6.3`, 실행 요구사항은 `Java 8+`이며 `Java 17+` 권장.
- k6: 공식 문서 최신 브랜치는 `v1.7.x`로 표시되며 릴리스 노트에 `v1.7.0`이 노출됨.
- nGrinder: 공식 홈페이지는 아직 `3.5.5-p1`를 표시하지만, 공식 GitHub는 `2025-09-24`에 archive 처리되었음. 신규 비교 시 이 날짜를 반드시 리스크로 봐야 함.

## 상세 비교표

| 비교 항목 | JMeter | nGrinder | k6 |
| --- | --- | --- | --- |
| 기본 철학 | GUI 중심 + 필요 시 스크립트 확장 | 중앙 웹 UI 중심의 조직형 성능 테스트 플랫폼 | 코드 우선(Code-first) 성능 테스트 |
| 주요 작성 방식 | GUI Test Plan(`.jmx`) + JSR223(Groovy 등) | 웹 UI 또는 IDE 기반 Groovy/Jython 스크립트 | JavaScript/TypeScript 스크립트 |
| 강한 영역 | 레거시 포함 다양한 프로토콜, 빠른 레코딩, 폭넓은 레퍼런스 | 여러 사용자가 공유하는 사내 플랫폼, 에이전트 분산 실행 | API 테스트, CI/CD, GitOps, 자동화, 성능 기준선 관리 |
| 지원 프로토콜 성격 | HTTP/HTTPS, SOAP/REST, FTP, JDBC, LDAP, JMS, Mail, TCP 등 폭넓음 | HTTP 중심이지만 라이브러리 확장으로 타 프로토콜 대응 가능 | HTTP/2, WebSocket, gRPC, TLS, Browser 모듈 등 현대 웹/API 중심 |
| 브라우저 관점 | 브라우저가 아니라 프로토콜 레벨 테스트 도구 | 브라우저 자동화 자체가 핵심은 아님 | `k6/browser` 제공, 브라우저 수준 시나리오 가능 |
| 스크립트 버전관리 | 가능하지만 GUI 산출물 diff/merge는 불리한 편 | 스크립트 저장소와 중앙관리 구조에 강점 | 텍스트 기반 코드라 Git diff/PR 협업에 가장 유리 |
| 분산 실행 | Remote/Distributed Testing 가능, 운영 편의성은 낮은 편 | Controller-Agent 구조가 기본, 다중 에이전트/다중 지역 실행 강점 | OSS는 별도 분산 운영 구성이 필요하고, Grafana Cloud k6는 관리형 인프라 제공 |
| 결과 분석 | HTML Dashboard, 다수 플러그인, 로컬 분석 친화적 | 웹 UI 기반 모니터링과 결과 관리 강점 | Threshold, 실시간 출력, 다양한 출력 연동, Grafana 연계 강점 |
| CI/CD 적합성 | 가능하지만 GUI 중심 자산이 누적되면 불리 | 가능하나 조직형 운영 도구 성격이 강함 | 가장 적합. 코드형 테스트와 자동 판정 구조가 명확 |
| 러닝 커브 | 초반 진입 쉬움, 복잡해질수록 Test Plan 관리 난이도 증가 | 설치와 운영 개념을 이해해야 하며 Controller-Agent 구조 학습 필요 | 개발자에게 친숙, 비개발자에게는 코드 작성 장벽이 있을 수 있음 |
| 확장성 | 플러그인과 JSR223 확장이 매우 풍부 | 라이브러리 추가와 커스텀 의존성 사용이 유연 | 확장(extension) 생태계와 출력 연동이 좋음 |
| 장기 유지보수 관점 | 안정적이고 보수적 | 신규 채택 리스크 큼 | 현재 가장 현대적이고 운영 자동화에 유리 |

## 도구별 해석

### 1. JMeter

- 장점
  - 공식 페이지 기준 지원 프로토콜 범위가 세 도구 중 가장 넓다.
  - GUI Test IDE, 레코딩, 디버깅, HTML 리포트가 잘 갖춰져 있어 PoC 시작이 빠르다.
  - HTTP 외에도 JDBC, JMS, FTP, Mail, TCP 등 이질적인 시스템을 한 도구로 묶기 좋다.
- 단점
  - 테스트 자산이 커질수록 GUI 중심 산출물 관리가 어려워진다.
  - 분산 실행은 가능하지만 여러 노드 버전 정합성, 네트워크 설정, 원격 서버 관리 부담이 존재한다.
  - 공식 문서가 명시하듯 브라우저 자체를 실행하지 않으므로 실제 프론트엔드 렌더링 성능 측정 도구로 보면 한계가 있다.
- 적합한 조직
  - QA 중심
  - 레거시/혼합 프로토콜 환경
  - 빠른 시각적 설계와 레코딩이 필요한 팀

### 2. nGrinder

- 장점
  - Controller-Agent 구조와 웹 UI가 기본이라 사내 공용 성능 테스트 플랫폼처럼 운영하기 좋다.
  - 공식 소개 기준 다중 에이전트, 다중 지역 배치, 동시 테스트 실행, 결과 관리에 강점이 있다.
  - Jython 또는 Groovy 기반이며 외부 라이브러리와 Maven 의존성 확장이 가능하다.
- 단점
  - 가장 큰 이슈는 유지보수 신호다. 공식 GitHub 저장소가 `2025-09-24`에 archive 되었고 read-only 상태다.
  - 공식 홈페이지의 버전 표기(`3.5.5-p1`)와 GitHub 최신 상태가 어긋나므로, 신규 도입 시 운영/보안/호환성 검토를 더 엄격히 해야 한다.
  - 현대적인 DevOps 파이프라인 표준 도구로 밀기에는 생태계 활력이 약하다.
- 적합한 조직
  - 이미 nGrinder 경험이 있는 팀
  - 사내 온프레미스 다중 에이전트 플랫폼이 꼭 필요한 조직
  - 운영 플랫폼 관점이 중요하고 신규 표준화보다 기존 자산 활용이 우선인 경우

### 3. k6

- 장점
  - JavaScript/TypeScript 기반의 코드형 테스트라 Git, PR, 코드리뷰, CI/CD에 가장 잘 맞는다.
  - 공식 문서 체계상 `Thresholds`, `Checks`, `Scenarios`, `Results output`가 선명하게 정리되어 있어 자동 판정 파이프라인 구축이 쉽다.
  - `HTTP/2`, `WebSockets`, `gRPC`, `k6/browser` 등 현대 웹/API 테스트 포인트에 잘 맞는다.
  - Grafana Cloud k6를 쓰면 분산 인프라 스케일링과 메트릭 저장/집계를 관리형으로 처리할 수 있다.
- 단점
  - GUI로 빠르게 찍어내는 방식보다 코드 작성 전제가 강하다.
  - OSS만으로 대규모 분산 실행을 하려면 Kubernetes Operator 등 별도 운영 구성이 필요하다.
  - DB/JMS/레거시 엔터프라이즈 프로토콜 범용성은 JMeter보다 약하다.
- 적합한 조직
  - 개발팀 주도 성능 테스트
  - API 성능 테스트 자동화
  - CI 파이프라인에서 SLA/Threshold 미달 시 즉시 실패 처리하려는 팀

## PoC 관점 추천

### 추천 우선순위

1. `k6`
2. `JMeter`
3. `nGrinder`

### 추천 이유

- `k6`를 1순위로 두는 이유
  - 이번 비교가 신규 표준 또는 우선 투자 대상을 고르는 목적이라면, 코드형 협업과 자동화 적합성이 가장 중요하다.
  - 현대적인 API 중심 서비스와 CI/CD 정착에는 k6가 가장 자연스럽다.
- `JMeter`를 2순위로 두는 이유
  - 조직 시스템이 혼합 프로토콜이고 레거시가 많다면, k6보다 JMeter가 실제 PoC 커버리지가 넓다.
  - 따라서 k6를 기본 후보로 보되, 프로토콜 다양성이 핵심이면 JMeter를 병행 검증하는 전략이 합리적이다.
- `nGrinder`를 3순위로 두는 이유
  - 기능 자체보다도 유지보수 상태가 신규 채택의 가장 큰 리스크다.
  - 이미 내부 경험이나 운영 자산이 없다면, 새 표준 도구로 선정할 근거가 약하다.

## PoC에서 실제로 비교해야 할 항목

아래 항목은 세 도구를 같은 시나리오로 비교할 때 바로 사용할 수 있다.

| 평가 항목 | 확인 포인트 |
| --- | --- |
| 스크립트 작성 생산성 | 동일 API 시나리오를 처음 작성하는 데 걸린 시간 |
| 파라미터화/상관관계 처리 | 토큰 추출, 세션 유지, 동적 값 치환이 얼마나 쉬운지 |
| 부하 모델링 | Ramp-up, Spike, Soak, Arrival rate 표현이 얼마나 직관적인지 |
| 분산 실행 난이도 | 1대에서 3대로 확장할 때 설치/설정/운영 부담 |
| 결과 분석 | 테스트 후 리포트 가독성, 비교 기능, 재현성 |
| CI/CD 적합성 | Jenkins/GitHub Actions/GitLab CI에서 자동 실행과 실패 판정이 쉬운지 |
| 협업성 | Git diff, PR 리뷰, 공통 템플릿 재사용이 쉬운지 |
| 장기 유지보수 | 테스트 자산이 10개에서 100개로 늘어날 때 관리 가능한지 |

## 회의용 요약 문안

다음 문단은 노션 상단 요약에 그대로 붙여넣기 좋다.

> 2026-03-26 기준으로 JMeter, nGrinder, k6를 비교한 결과, 신규 표준 도구 후보는 k6가 가장 유리하다. k6는 JavaScript/TypeScript 기반의 코드형 성능 테스트 도구로 Git/PR/CI-CD 연동과 Threshold 기반 자동 판정에 강하다. JMeter는 GUI와 폭넓은 프로토콜 지원이 강점이라 레거시와 혼합 프로토콜 환경에서 여전히 유효한 대안이다. nGrinder는 Controller-Agent 구조와 중앙 웹 UI 장점이 있으나, 공식 GitHub 저장소가 2025-09-24에 archive되어 신규 표준화 후보로는 유지보수 리스크가 크다.

## 출처

- Apache JMeter 변경 이력: https://jmeter.apache.org/changes.html
- Apache JMeter 공식 소개: https://jmeter.apache.org/
- Apache JMeter 분산 테스트 튜토리얼: https://jmeter.apache.org/usermanual/jmeter_distributed_testing_step_by_step.pdf
- nGrinder 공식 페이지: https://naver.github.io/ngrinder/
- nGrinder GitHub 저장소: https://github.com/naver/ngrinder
- nGrinder Releases: https://github.com/naver/ngrinder/releases
- Grafana k6 릴리스 노트: https://grafana.com/docs/k6/latest/release-notes/
- Grafana k6 공식 문서: https://grafana.com/docs/k6/latest/
- Grafana Cloud k6 소개: https://grafana.com/docs/grafana-cloud/testing/k6/introduction/
