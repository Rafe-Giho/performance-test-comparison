# k6 구축 가이드

## 적용 대상

- Kubernetes/MSA/API 중심 서비스
- 이벤트성 API 폭주 재현
- CI/CD 품질게이트
- 클라우드 네이티브 전환 사업
- 범용 API 및 browser 템플릿을 기준으로 프로젝트를 시작해야 하는 경우

## 공식 기준

- 문서: <https://grafana.com/docs/k6/latest/>
- 설치: <https://grafana.com/docs/k6/latest/get-started/installation/>
- 분산 실행: <https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/>
- 큰 테스트 가이드: <https://grafana.com/docs/k6/latest/testing-guides/running-large-tests/>
- browser: <https://grafana.com/docs/k6/latest/using-k6-browser/>

## 표준 토폴로지

### API 테스트 최소 구성

- 러너 1대: `2 vCPU / 4 GB / 30 GB SSD`

### API 테스트 권장 시작점

- 러너 1대: `4 vCPU / 8 GB / 50 GB SSD`
- 또는 러너 2대: 각 `4 vCPU / 8 GB / 50 GB SSD`

### Browser 테스트 최소 구성

- 러너 2대: 각 `4 vCPU / 8 GB / 30 GB SSD`

### Browser 테스트 권장 시작점

- 러너 2대: 각 `8 vCPU / 16 GB / 50 GB SSD`

### 대규모 또는 이벤트성 시험

- API 러너 2~4대: 각 `8 vCPU / 16 GB / 50 GB SSD`
- 또는 Kubernetes/NKS 분산 실행
- browser/hybrid는 전용 node group 또는 고사양 러너 분리

## 구축 방식

### VM 방식

- API 중심 시험에 권장
- 빠른 PoC에 적합
- `event_api_load.js` 같은 범용 템플릿 적용에 적합

### Kubernetes/NKS 방식

- 분산 실행
- 클라우드 네이티브 대상
- runner/pod를 전용 node group에 배치
- 범용 YAML 템플릿을 프로젝트에 맞게 조정해서 재사용

## 기본 구축 절차

1. Linux VM 또는 NKS 준비
2. k6 바이너리 또는 컨테이너 이미지 확보
3. `scripts/`, `data/`, `reports/` 경로 생성
4. 샘플 스크립트 smoke test
5. 메트릭 및 로그 수집 경로 확인

## 규모별 준비 항목

### 소규모

- 단일 러너
- smoke + 짧은 load 테스트
- 스크립트와 threshold 기본 확인

### 중규모

- 러너 2대 또는 고사양 러너 1대
- 대상 시스템 메트릭 연동
- scenario 비율과 도착률 정의

### 대규모

- 러너 2~4대 또는 Kubernetes 분산
- node group 분리
- 결과 저장, 로그 수집, 메트릭 시각화 준비
- browser 테스트는 별도 자원군 준비

## Kubernetes/NKS 운영 원칙

- 대상 서비스와 같은 클러스터에 놓아도 되지만, 전용 node group 분리를 권장한다.
- 가능하면 대상 클러스터 밖 별도 테스트 환경 또는 별도 노드풀에서 실행한다.
- runner 리소스와 대상 애플리케이션 리소스가 서로 잠식하지 않도록 한다.

## 표준 디렉터리 매핑

- 스크립트: `scripts/`
- 시나리오 정의: `scenarios/`
- 데이터: `data/`
- 인프라 파일: `infra/`
- 결과: `reports/<project>/<yyyymmdd>/`

## 템플릿 적용 원칙

- API 성능시험은 `event_api_load.js`를 기준으로 path와 threshold를 조정한다.
- browser 검증은 `browser_smoke.js`를 기준으로 대상 URL과 리소스만 조정한다.
- Kubernetes 배포는 `k6-api-testrun.yaml`, `k6-browser-pod.yaml`에서 namespace, 병렬도, 리소스만 변경한다.

## 구축 완료 기준

- k6 버전 확인
- 단일 스크립트 smoke test 성공
- 결과 로그 및 요약 출력 확인
- 분산 실행 시 runner/pod 생성 확인
