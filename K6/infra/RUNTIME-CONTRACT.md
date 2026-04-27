# k6 런타임 설정 계약

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

이 문서는 `K6/infra/apply-api.ps1`, `K6/infra/apply-browser.ps1` 실행 전에 사용자가 준비해야 하는 실제 Kubernetes 설정 파일의 계약이다.

표준 namespace는 `k6-test`로 고정한다. 이 저장소의 `namespace.yaml`, `k6-api-testrun.yaml`, `k6-browser-pod.yaml`, apply script는 모두 `k6-test`를 기준으로 동작한다.

## 클라우드/NKS 전제

- k6 Operator가 설치되어 있고 `testruns.k6.io` CRD가 존재해야 한다.
- k6 Operator는 `grafana/k6-operator` chart `4.3.2`, app version `1.3.2` 기준으로 설치한다.
- API runner는 `workload=k6-runner` node group에서 운영한다.
- Browser runner는 `workload=k6-browser` node group에서 운영한다.
- Secret manifest는 Git에 커밋하지 않는다.
- 결과 로그와 summary는 프로젝트 표준 object storage 또는 중앙 로그 저장소에 보관한다.

## API 테스트 ConfigMap

`k6-api-testrun.yaml`은 `k6-runtime-config` ConfigMap을 참조한다.

필수 메타데이터:

| 필드 | 값 |
| --- | --- |
| `kind` | `ConfigMap` |
| `metadata.name` | `k6-runtime-config` |
| `metadata.namespace` | `k6-test` |

필수 `data` 키:

| 키 | 검증 기준 |
| --- | --- |
| `BASE_URL` | `http://` 또는 `https://`로 시작 |
| `HEALTH_PATH` | 비어 있지 않은 경로 |
| `LOGIN_PATH` | 비어 있지 않은 경로 |
| `LIST_PATH` | 비어 있지 않은 경로 |
| `DETAIL_PATH` | 비어 있지 않은 경로 |
| `EVENT_PATH` | 비어 있지 않은 경로 |
| `EVENT_PAYLOAD` | 유효한 JSON 문자열 |

## API 테스트 Secret

`k6-api-testrun.yaml`은 `k6-runtime-secret` Secret을 참조한다.

필수 메타데이터:

| 필드 | 값 |
| --- | --- |
| `kind` | `Secret` |
| `metadata.name` | `k6-runtime-secret` |
| `metadata.namespace` | `k6-test` |
| `type` | `Opaque` |

필수 `stringData` 또는 `data` 키:

| 키 | 검증 기준 |
| --- | --- |
| `USERNAME` | 비어 있지 않은 실제 테스트 계정 |
| `PASSWORD` | 비어 있지 않은 실제 테스트 비밀번호 |

## Browser 테스트 ConfigMap

`k6-browser-pod.yaml`은 `k6-runtime-config` ConfigMap의 `BASE_URL`을 사용한다.

Browser Pod는 `nodeSelector: workload=k6-browser`를 사용한다. 해당 라벨의 노드가 없으면 Pod는 pending 상태가 된다.

## 실행

```powershell
.\apply-api.ps1 -RuntimeConfigPath <config-file> -RuntimeSecretPath <secret-file>
.\apply-browser.ps1 -RuntimeConfigPath <config-file>
```

로컬에서 Kubernetes 리소스 생성 전 기본 manifest 검증만 수행하려면 `-DryRun`을 붙인다.

```powershell
.\apply-api.ps1 -RuntimeConfigPath <config-file> -RuntimeSecretPath <secret-file> -DryRun
.\apply-browser.ps1 -RuntimeConfigPath <config-file> -DryRun
```

실제 적용 전 최소 확인 명령:

```powershell
kubectl get ns k6-test
helm status k6-operator -n k6-operator-system
kubectl get crd testruns.k6.io
kubectl get crd privateloadzones.k6.io
kubectl get nodes -l workload=k6-runner
kubectl get nodes -l workload=k6-browser
```
