# 운영 검증 하네스

이 문서는 문서와 실행 자산의 정합성을 반복 점검하기 위한 최소 운영 하네스를 정의한다.

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

이 하네스는 팀 배포 전 문서 품질과 실행 자산 정합성을 동시에 확인하는 필수 검증 절차다.

## 목적

- 표준 문서가 실제 템플릿 파일을 정확히 가리키는지 확인한다.
- 모든 Markdown 문서가 팀 배포용 표준 운영 가이드 등급을 명시하는지 확인한다.
- 모든 Markdown 문서가 클라우드 기반 테스트 환경을 전제로 작성되어 있는지 확인한다.
- 도구별 `README`, `SETUP-GUIDE`, `TEST-GUIDE`가 [DOCUMENT-STANDARD.md](./DOCUMENT-STANDARD.md)의 필수 섹션을 갖췄는지 확인한다.
- `JMeter 공통 표준`, `k6 전략 특화`, `nGrinder 한시 운영` 정책이 주요 문서에 일관되게 남아 있는지 확인한다.
- 표준 시나리오 흐름 `health -> login -> list -> detail -> event`가 실제 템플릿에 반영되어 있는지 확인한다.
- 배포 설정 변경이 필요한 항목은 실패 또는 경고로 드러낸다.

## 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1
```

경고까지 실패로 처리하려면 아래처럼 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict
```

## 점검 항목

- 필수 루트 문서와 도구별 `README`, `SETUP-GUIDE`, `TEST-GUIDE` 존재 여부
- 모든 Markdown 문서의 `문서 등급: 팀 배포용 표준 운영 가이드` 표기 여부
- 모든 Markdown 문서의 `운영 환경: 클라우드 기반 테스트 환경` 표기 여부
- Markdown 문서의 미완료 상태 표기 잔존 여부
- 도구별 `SETUP-GUIDE.md`의 적용 대상, 공식 기준, 사전 조건, 설치 Runbook, 검증 Runbook, 보안/네트워크 기준, 장애 조치, 운영 체크리스트, 구축 완료 기준 존재 여부
- 도구별 `TEST-GUIDE.md`의 실행 전제, 표준 시나리오 흐름, 실행 Runbook, 성공/실패 판정, 결과 산출물, 장애 조치, 정리/후속 조치 존재 여부
- 도구별 `README.md`의 역할, 폴더 용도, 표준 템플릿, 먼저 읽을 문서, 운영 포지션, 배포 전 확인 존재 여부
- `TEMPLATE-CATALOG.md`에 적힌 실제 파일 경로 존재 여부
- Markdown 상대 링크의 대상 파일 존재 여부
- 주요 문서의 표준 정책 문구 정합성
- JMeter, k6, nGrinder 표준 템플릿의 `event` 단계 반영 여부
- 운영 파일의 `latest` 이미지 태그 사용 여부
- k6 정적 ConfigMap 사본 재도입 여부
- k6 Operator `4.3.2`, `testruns.k6.io`, `privateloadzones.k6.io`, 런타임 ConfigMap/Secret 계약 반영 여부
- nGrinder `3.5.9-p1`, `docker compose -p ngrinder`, security group, `8080/tcp`, `16001/tcp`, `12000-12009/tcp` 기준 반영 여부

## 검증 수준 표기 기준

문서는 아래 수준을 구분해서 표현한다.

| 수준 | 의미 |
| --- | --- |
| 문서/자산 검증 | 파일 경로, 필수 섹션, 버전 고정, 템플릿 토큰, 스크립트 문법을 검증 |
| 설치 체인 검증 | 도구 설치 또는 컨테이너/Operator 기동과 기본 연결성을 검증 |
| 실행 체인 검증 | 외부 부하가 없는 no-op 또는 dry-run으로 실행 경로를 검증 |
| 대상 부하 검증 | 실제 승인된 대상 시스템에 smoke/load/stress/spike/soak를 수행 |

현재 저장소 기준으로 k6는 NKS Operator 설치 체인과 no-op 실행 체인을 검증했고, nGrinder는 Docker Desktop 설치 체인과 Agent 연결성을 검증했다. JMeter는 문서/자산 검증까지 완료했고 실제 VM 설치와 대상 부하 검증은 프로젝트 환경에서 수행한다.

## 운영 기준

- 기본 실행은 오류가 있으면 실패하고, 경고만 있으면 성공한다.
- `-Strict` 실행은 경고도 실패로 처리한다.
- Kubernetes 리소스, 이미지 태그, 운영 Compose 설정은 승인 후 고친다.
- 새 템플릿이나 문서를 추가하면 `tools/validate-workspace.ps1`의 필수 목록도 함께 갱신한다.
- 팀 배포 전 기준 명령은 `powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict`다.
- 이 명령이 실패하면 문서 배포와 템플릿 배포를 보류한다.
