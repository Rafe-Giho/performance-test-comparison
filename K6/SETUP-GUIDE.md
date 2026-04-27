# k6 구축 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

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
- k6 Operator 설치: <https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/install-k6-operator/>
- TestRun CRD 실행: <https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/usage/executing-k6-scripts-with-testrun-crd/>
- 큰 테스트 가이드: <https://grafana.com/docs/k6/latest/testing-guides/running-large-tests/>
- browser: <https://grafana.com/docs/k6/latest/using-k6-browser/>
- Kubernetes browser: <https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/browser-tests/>

## 권장 버전 정책

- k6 API runner: `grafana/k6:1.7.1`
- k6 browser runner: `grafana/k6:1.7.1-with-browser`
- VM 직접 설치 기준 바이너리: `v1.7.1`
- k6 Operator Helm chart: `grafana/k6-operator` chart `4.3.2`
- k6 Operator app version: `1.3.2`
- 기준 확인일: `2026-04-27`

운영 자산은 버전을 고정한다. 패키지 매니저로 설치한 경우에도 `k6 version` 결과가 표준 버전과 다르면 본시험에 사용하지 않는다.
Kubernetes/NKS 분산 실행은 k6 Operator 설치가 선행 조건이며, chart 버전은 `4.3.2`로 고정한다.

## 사전 조건

- VM 실행 시 Windows 또는 Linux 러너에 네트워크, DNS, 시간 동기화, 결과 저장 경로를 준비한다.
- Kubernetes/NKS 실행 시 `kubectl`, `helm`, `k6-test` namespace 생성 권한, k6 Operator 설치 상태를 확인한다.
- 테스트 namespace는 `k6-test`로 고정한다. 이 저장소의 YAML과 apply 스크립트는 `k6-test`를 표준 namespace로 참조한다.
- API runner용 전용 node group은 `workload=k6-runner`, browser runner용 전용 node group은 `workload=k6-browser` 라벨을 기준으로 구분한다.
- API 테스트에는 실제 `BASE_URL`, `HEALTH_PATH`, `LOGIN_PATH`, `LIST_PATH`, `DETAIL_PATH`, `EVENT_PATH`, `EVENT_PAYLOAD`, 테스트 계정이 필요하다.
- Browser 테스트에는 실제 `BASE_URL`과 Chromium 실행이 가능한 러너 리소스가 필요하다.
- 대상 시스템 모니터링 경로와 테스트 러너 리소스 모니터링 경로를 분리한다.

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

## 클라우드 표준 아키텍처

k6는 클라우드 API/MSA 성능시험에서 `VM 단일/소규모 실행`과 `Kubernetes/NKS 분산 실행`을 분리해서 운영한다.

| 역할 | 배치 기준 | 접근 기준 |
| --- | --- | --- |
| VM API 러너 | 테스트 전용 private subnet 또는 별도 테스트 VPC | 대상 LB/API Gateway/Ingress로 egress 허용 |
| NKS API runner Pod | `k6-test` namespace, `workload=k6-runner` node group | 대상 서비스 또는 Ingress로 egress 허용 |
| NKS browser Pod | `k6-test` namespace, `workload=k6-browser` node group | Chromium 실행 가능 정책과 충분한 CPU/메모리 확보 |
| k6 Operator | `k6-operator-system` namespace | `TestRun` CRD 관리 |
| 런타임 설정 | ConfigMap/Secret | `RUNTIME-CONTRACT.md` key 계약 준수 |
| 결과 저장소 | object storage, 파일 저장소, 또는 중앙 로그 저장소 | summary JSON, Pod logs, threshold 결과 보관 |

운영 원칙:

- API 테스트와 browser 테스트는 node group을 분리한다.
- 대상 애플리케이션 Pod와 k6 runner Pod가 같은 리소스 풀을 공유하지 않도록 한다.
- 대규모 시험에서는 cloud NAT, LB, WAF, API Gateway, node egress bandwidth가 병목이 될 수 있으므로 사전 한도를 확인한다.
- 파일 업로드나 큰 응답 본문 테스트는 네트워크 비용과 러너 메모리 사용량을 별도 산정한다.
- Kubernetes 실행은 실제 적용 전 `-DryRun`으로 namespace, ConfigMap, Secret, script ConfigMap, Pod manifest를 검증한다.

## 클라우드 네트워크 기준

| 방향 | 포트 | 출발지 | 목적지 | 용도 |
| --- | --- | --- | --- | --- |
| 운영자 -> VM 러너 | `22/tcp` 또는 `3389/tcp` | 운영자 고정 IP, VPN, bastion | VM runner | 관리 접속 |
| VM runner -> 대상 시스템 | `80/tcp`, `443/tcp`, 또는 실제 API 포트 | VM runner security group | LB/WAF/API Gateway/Ingress | API 부하 발생 |
| NKS runner Pod -> 대상 시스템 | `80/tcp`, `443/tcp`, 또는 실제 API 포트 | runner node group 또는 Pod egress 정책 | Service/Ingress/API Gateway | API 부하 발생 |
| NKS control plane -> worker | 클러스터 표준 포트 | NKS control plane | k6 node group | Pod scheduling, logs |
| runner -> object storage/log sink | `443/tcp` | VM 또는 Pod | 결과 저장소 | summary/log 업로드 |

운영 원칙:

- egress 정책은 대상 시스템과 결과 저장소에 필요한 포트만 허용한다.
- 부하 발생 source IP 또는 NAT Gateway IP는 고객 승인 목록에 사전 등록한다.
- private API를 테스트할 때는 runner를 같은 VPC 또는 연결된 VPC/VPN에 배치한다.
- public API를 테스트할 때는 WAF, rate limit, DDoS 보호 정책과 시험 window를 사전 승인받는다.

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

## 설치 Runbook

### 1. Windows 고정 바이너리 설치

팀 표준 설치는 GitHub Releases의 고정 버전 바이너리를 사용한다.

```powershell
$K6Version = "1.7.1"
$InstallRoot = "C:\tools\k6-$K6Version"
$Zip = "$env:USERPROFILE\Downloads\k6-v$K6Version-windows-amd64.zip"
$Checksum = "$env:USERPROFILE\Downloads\k6-v$K6Version-checksums.txt"

Invoke-WebRequest `
  -Uri "https://github.com/grafana/k6/releases/download/v$K6Version/k6-v$K6Version-windows-amd64.zip" `
  -OutFile $Zip
Invoke-WebRequest `
  -Uri "https://github.com/grafana/k6/releases/download/v$K6Version/k6-v$K6Version-checksums.txt" `
  -OutFile $Checksum

$ExpectedHash = (Select-String -Path $Checksum -Pattern "k6-v$K6Version-windows-amd64.zip").Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim()
$ActualHash = (Get-FileHash $Zip -Algorithm SHA256).Hash.ToLower()
if ($ActualHash -ne $ExpectedHash.ToLower()) {
  throw "k6 archive SHA-256 mismatch"
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
Expand-Archive -Path $Zip -DestinationPath $InstallRoot -Force
& "$InstallRoot\k6-v$K6Version-windows-amd64\k6.exe" version
```

필요하면 `C:\tools\k6-1.7.1\k6-v1.7.1-windows-amd64`를 사용자 또는 시스템 `PATH`에 추가한다.

### 2. Linux 고정 바이너리 설치

```bash
K6_VERSION=1.7.1
INSTALL_ROOT=/opt
cd /tmp

curl -fSLO "https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-amd64.tar.gz"
curl -fSLO "https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-checksums.txt"

grep "k6-v${K6_VERSION}-linux-amd64.tar.gz" "k6-v${K6_VERSION}-checksums.txt" | sha256sum -c -
sudo tar -xzf "k6-v${K6_VERSION}-linux-amd64.tar.gz" -C "$INSTALL_ROOT"
sudo ln -sfn "$INSTALL_ROOT/k6-v${K6_VERSION}-linux-amd64" /opt/k6
/opt/k6/k6 version
```

### 3. Docker runner 확인

```powershell
docker run --rm grafana/k6:1.7.1 version
docker run --rm grafana/k6:1.7.1-with-browser version
```

### 4. Kubernetes/NKS 실행 자산 준비

```powershell
kubectl get ns
kubectl get pods -A
helm list -n k6-operator-system
kubectl get crd testruns.k6.io
kubectl get nodes --show-labels

powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>" `
  -DryRun

powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-browser.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -DryRun
```

## k6 Operator 설치 Runbook

Kubernetes/NKS에서 `k6-api-testrun.yaml`을 실행하려면 k6 Operator가 먼저 설치되어 있어야 한다. Operator가 없으면 `TestRun` CRD가 없기 때문에 API 분산 실행은 실패한다.

### 1. Helm repo와 chart 버전 확인

```powershell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
helm search repo grafana/k6-operator --versions
```

표준 설치 버전:

| 항목 | 값 |
| --- | --- |
| Helm chart | `grafana/k6-operator` |
| Chart version | `4.3.2` |
| App version | `1.3.2` |
| Namespace | `k6-operator-system` |

### 2. Operator 설치

```powershell
helm upgrade --install k6-operator grafana/k6-operator `
  --version 4.3.2 `
  --namespace k6-operator-system `
  --create-namespace
```

### 3. 설치 검증

```powershell
helm status k6-operator -n k6-operator-system
helm list -n k6-operator-system
kubectl get deploy -n k6-operator-system
kubectl get pods -n k6-operator-system
kubectl get crd testruns.k6.io
kubectl get crd privateloadzones.k6.io
```

### 4. 권한 검증

```powershell
kubectl auth can-i create configmaps -n k6-test
kubectl auth can-i create secrets -n k6-test
kubectl auth can-i create testruns.k6.io -n k6-test
kubectl auth can-i get pods -n k6-test
kubectl auth can-i get logs -n k6-test
```

### 5. 운영 기준

- Operator chart는 `4.3.2`로 고정한다.
- chart upgrade는 별도 변경 승인 후 수행한다.
- `helm install k6-operator grafana/k6-operator`처럼 버전 없는 설치 명령은 사용하지 않는다.
- 설치 후 `testruns.k6.io` CRD가 없으면 API 분산 실행을 진행하지 않는다.
- 제거가 필요하면 테스트 리소스 정리 후 `helm uninstall k6-operator -n k6-operator-system`을 승인받아 수행한다.

## 클라우드 VM 준비 Runbook

### 1. VM 러너 준비

```bash
sudo hostnamectl set-hostname <k6-runner-name>
sudo timedatectl set-timezone Asia/Seoul
date
ip addr
```

### 2. 대상 접근 확인

```bash
curl -k -I "<actual-base-url><actual-health-path>"
```

### 3. 로컬 summary 저장 경로 확인

```powershell
New-Item -ItemType Directory -Path .\K6\reports\<project-name>\<yyyymmdd> -Force
```

### 4. VM smoke 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\scripts\run-api.ps1 `
  -ProjectName "<project-name>" `
  -BaseUrl "<actual-base-url>" `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

성공 시 `K6/reports/<project-name>/<yyyymmdd>/summary-api-*.json`이 생성된다.

## Kubernetes/NKS 준비 Runbook

### 1. k6 Operator 설치 확인

```powershell
kubectl get ns k6-operator-system
helm status k6-operator -n k6-operator-system
kubectl get deploy -n k6-operator-system
kubectl get crd testruns.k6.io
kubectl auth can-i create configmaps -n k6-test
kubectl auth can-i create secrets -n k6-test
kubectl auth can-i create testruns.k6.io -n k6-test
```

Operator가 없으면 `k6 Operator 설치 Runbook`을 먼저 수행한다. 설치 후 `helm list -n k6-operator-system` 결과를 프로젝트 기록에 남긴다.

### 2. 전용 node group 라벨 확인

```powershell
kubectl get nodes -l workload=k6-runner
kubectl get nodes -l workload=k6-browser
```

browser Pod manifest는 `nodeSelector: workload=k6-browser`를 사용한다. 해당 라벨 노드가 없으면 browser Pod는 pending 상태가 된다.

### 3. 런타임 ConfigMap/Secret 작성

[infra/RUNTIME-CONTRACT.md](./infra/RUNTIME-CONTRACT.md)의 key 계약에 맞춰 실제 ConfigMap과 Secret 파일을 작성한다.

```powershell
kubectl apply --dry-run=client -f "<actual-runtime-config.yaml>"
kubectl apply --dry-run=client -f "<actual-runtime-secret.yaml>"
```

### 4. API TestRun dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>" `
  -DryRun
```

### 5. API TestRun 적용

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>"
kubectl get testrun -n k6-test
kubectl get pods -n k6-test
```

### 6. Browser Pod dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-browser.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -DryRun
```

## 기본 구축 절차

1. Linux VM 또는 NKS 준비
2. k6 바이너리 또는 컨테이너 이미지 확보
3. `scripts/`, `data/`, `reports/` 경로 생성
4. 표준 스크립트 smoke test
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
- API runner node group은 `workload=k6-runner`, browser runner node group은 `workload=k6-browser`로 구분한다.
- 테스트 namespace는 `k6-test`, operator namespace는 `k6-operator-system`으로 관리한다.
- `k6-api-testrun.yaml`은 Operator의 `TestRun` CRD를 사용하고, 스크립트는 apply script가 `K6/scripts/event_api_load.js`에서 ConfigMap을 생성한다.
- browser 검증은 Pod 단위 smoke로 시작하고, Chromium 실행 정책과 리소스 요청량을 먼저 확인한다.

## 표준 디렉터리 매핑

- 스크립트: `scripts/`
- 시나리오 정의: `scenarios/`
- 데이터: `data/`
- 인프라 파일: `infra/`
- 결과: `reports/<project>/<yyyymmdd>/`

## 템플릿 적용 원칙

- API 성능시험은 `event_api_load.js`를 기준으로 실제 `BASE_URL`, path, `EVENT_PATH`, threshold, VU를 주입한다.
- browser 검증은 `browser_smoke.js`를 기준으로 실제 `BASE_URL`과 리소스를 주입한다.
- Kubernetes 배포는 `RUNTIME-CONTRACT.md`에 맞는 실제 ConfigMap/Secret을 준비한 뒤 `k6-api-testrun.yaml`, `k6-browser-pod.yaml`을 적용한다.
- `k6-api-testrun.yaml`의 runner 이미지는 `grafana/k6:1.7.1`, browser Pod 이미지는 `grafana/k6:1.7.1-with-browser`로 고정한다.

## 검증 Runbook

### 1. 로컬 API smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\scripts\run-api.ps1 `
  -ProjectName "<project-name>" `
  -BaseUrl "<actual-base-url>" `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

### 2. Kubernetes API dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-api.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -RuntimeSecretPath "<actual-runtime-secret.yaml>" `
  -DryRun
```

### 3. Browser pod dry-run

```powershell
powershell -ExecutionPolicy Bypass -File .\K6\infra\apply-browser.ps1 `
  -RuntimeConfigPath "<actual-runtime-config.yaml>" `
  -DryRun
```

## 보안/네트워크 기준

- 테스트 계정과 토큰은 Kubernetes Secret 또는 실행 시점 환경변수로만 주입한다.
- `K6/infra/RUNTIME-CONTRACT.md`의 key 이름을 임의 변경하지 않는다.
- 러너 Pod는 대상 애플리케이션 Pod와 같은 리소스 풀을 강하게 공유하지 않는다.
- Browser 테스트는 CPU와 메모리 사용량이 크므로 API 러너와 분리한다.
- 외부 대상 부하 테스트는 방화벽, WAF, rate limit 정책 승인 후 실행한다.
- Secret manifest는 Git에 커밋하지 않는다.
- object storage나 로그 저장소에 업로드하는 결과에는 비밀번호, 토큰, 세션값이 포함되지 않도록 한다.

## 장애 조치

- `k6 executable not found`가 발생하면 PATH 또는 고정 바이너리 설치 경로를 확인한다.
- `EVENT_PAYLOAD` 오류는 JSON 문자열 유효성을 먼저 확인한다.
- threshold 실패는 테스트 실패로 처리하고, 대상 시스템 지표와 함께 원인을 기록한다.
- Kubernetes dry-run이 실패하면 namespace 권한, k6 Operator 설치 상태, ConfigMap/Secret 이름을 확인한다.
- Browser pod가 pending이면 `workload=k6-browser` node label, taint/toleration, CPU/메모리 요청량을 확인한다.
- API TestRun runner가 생성되지 않으면 `testruns.k6.io` CRD, k6 Operator deployment, `k6-api-script` ConfigMap 생성 여부를 확인한다.
- egress 실패는 NKS node group 보안그룹, NetworkPolicy, NAT Gateway, DNS, WAF 허용 목록을 확인한다.

## 운영 체크리스트

- `k6 version` 결과가 `v1.7.1` 계열이다.
- `helm status k6-operator -n k6-operator-system`이 성공한다.
- k6 Operator chart가 `4.3.2`, app version이 `1.3.2`로 확인된다.
- `testruns.k6.io`, `privateloadzones.k6.io` CRD가 존재한다.
- API runner 이미지가 `grafana/k6:1.7.1`로 고정되어 있다.
- Browser runner 이미지가 `grafana/k6:1.7.1-with-browser`로 고정되어 있다.
- 실제 런타임 ConfigMap/Secret이 `RUNTIME-CONTRACT.md`와 일치한다.
- smoke 실행 결과 threshold pass/fail이 기록됐다.
- VM 실행은 `summary-api-*.json` 또는 `summary-browser-*.json`을 남긴다.
- NKS 실행은 Pod logs, TestRun 상태, runner Pod 리소스 사용량을 결과 저장소에 보관한다.
- `workload=k6-runner`, `workload=k6-browser` node group 분리가 확인됐다.
- 팀 배포 전 루트에서 `powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict`를 실행한다.

## 구축 완료 기준

- k6 버전 확인
- 단일 스크립트 smoke test 성공
- 결과 로그 및 요약 출력 확인
- 분산 실행 시 runner/pod 생성 확인
- `k6-test` namespace에서 API TestRun dry-run과 browser Pod dry-run이 통과
- 결과 산출물이 클라우드 결과 저장소에 보관됨
