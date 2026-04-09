# k6 테스트 수행 가이드

## 기본 원칙

- k6는 `전략 특화` 도구다.
- API 중심, 이벤트성 트래픽, 클라우드 네이티브, CI/CD 연계가 핵심일 때 우선 적용한다.
- 신규 프로젝트는 범용 스크립트 템플릿에서 시작한다.

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
2. 시나리오 정의
3. threshold 정의
4. smoke test
5. load/stress/spike/soak 실행
6. 애플리케이션 메트릭과 상관분석
7. threshold pass/fail 정리

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

## 템플릿 환류 규칙

- 반복적으로 쓰는 executor 조합은 공통 템플릿으로 승격한다.
- 고객 전용 URL과 토큰은 템플릿에 남기지 않는다.
- threshold 기준이 조직 표준으로 굳어지면 공통 스크립트에 반영한다.

## 비권고 상황

- 비개발자 중심 조직에서 공통 표준 하나로만 쓰려는 경우
- 레거시 혼합 프로토콜 중심 프로젝트
- 공공기관 고객이 익숙한 GUI 기반 도구를 강하게 요구하는 경우
