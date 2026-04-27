# 최종 산출물

이 문서는 현재 저장소의 최종 산출물 기준 목록이다.

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

팀 배포 산출물은 이 목록과 [DOCUMENT-STANDARD.md](./DOCUMENT-STANDARD.md)의 문서 품질 기준을 함께 만족해야 한다.

## 산출물 목록

1. 도구 비교 분석 문서
   - [docs/notion-loadtest-comparison.md](./docs/notion-loadtest-comparison.md)

2. 표준 부하테스트 구축 및 수행 가이드
   - [STANDARD-LOADTEST-GUIDE.md](./STANDARD-LOADTEST-GUIDE.md)

3. 비교 보고 가이드
   - [COMPARISON-REPORT-GUIDE.md](./COMPARISON-REPORT-GUIDE.md)

4. 기본 준비 체크리스트
   - [PREP-CHECKLIST.md](./PREP-CHECKLIST.md)

5. 운영 검증 하네스
   - [OPERATIONS-HARNESS.md](./OPERATIONS-HARNESS.md)
   - [tools/validate-workspace.ps1](./tools/validate-workspace.ps1)

6. 문서 표준 운영 기준
   - [DOCUMENT-STANDARD.md](./DOCUMENT-STANDARD.md)

7. 도구별 표준 운영 문서와 실행 자산
   - [Jmeter/README.md](./Jmeter/README.md)
   - [Jmeter/SETUP-GUIDE.md](./Jmeter/SETUP-GUIDE.md)
   - [Jmeter/TEST-GUIDE.md](./Jmeter/TEST-GUIDE.md)
   - [K6/README.md](./K6/README.md)
   - [K6/SETUP-GUIDE.md](./K6/SETUP-GUIDE.md)
   - [K6/TEST-GUIDE.md](./K6/TEST-GUIDE.md)
   - [K6/infra/RUNTIME-CONTRACT.md](./K6/infra/RUNTIME-CONTRACT.md)
   - [nGrinder/README.md](./nGrinder/README.md)
   - [nGrinder/SETUP-GUIDE.md](./nGrinder/SETUP-GUIDE.md)
   - [nGrinder/TEST-GUIDE.md](./nGrinder/TEST-GUIDE.md)

## 검증 상태 요약

| 도구 | 완료된 검증 | 대상 시스템 부하 실행 |
| --- | --- | --- |
| JMeter | 표준 문서, `.jmx`, 실행 스크립트, Docker runner 자산, 하네스 검증 | 프로젝트별 실제 환경에서 수행 |
| k6 | NKS k6 Operator 설치와 no-op `TestRun`, CRD, server dry-run, 적용 스크립트 dry-run | 프로젝트별 실제 환경에서 수행 |
| nGrinder | Docker Desktop Compose 기동, Controller HTTP `200`, Agent 연결 로그 | 프로젝트별 실제 환경에서 수행 |

## 사용 기준

- 후속 작업 지시는 이 문서의 산출물 목록을 기준으로 한다.
- 산출물 추가 또는 변경 시 이 문서를 함께 갱신한다.
