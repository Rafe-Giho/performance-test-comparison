# JMeter 구축 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

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
- 참고 사항: 공식 문서는 ZIP/TAR 설치와 CLI 실행을 중심으로 설명한다. 이 가이드도 `VM 또는 인스턴스 직접 설치`를 기본 구축 방식으로 본다. 컨테이너는 실행 러너용 부가 방식으로만 다룬다.

## 권장 버전 정책

- JMeter: `5.6.3`
- Java: `Java 17` 권장
- 기준 확인일: `2026-04-27`

공식 다운로드 페이지 기준 Apache JMeter 최신 릴리스는 `5.6.3`이며, 실행 요구사항은 `Java 8+`다. 변경 이력 페이지는 `Java 17 or later recommended`를 명시한다.

## 사전 조건

- 설치 노드는 인터넷 다운로드가 가능하거나, 검증된 `apache-jmeter-5.6.3` 바이너리와 SHA-512 파일을 폐쇄망 반입해야 한다.
- Windows 관리/작성 노드는 PowerShell 실행 정책과 `C:\tools` 쓰기 권한을 확보한다.
- Linux 엔진 노드는 `sudo` 권한, 패키지 저장소 접근, `/opt` 쓰기 권한을 확보한다.
- 분산 실행 시 제어 노드에서 모든 엔진 노드의 `1099/tcp`, `50000/tcp` 접근을 확인한다.
- 클라우드 VPC, subnet, route table, security group, NACL, bastion/VPN 접근 정책을 테스트 전용으로 분리한다.
- 제어/작성 노드와 엔진 노드는 가능하면 같은 region과 같은 VPC 또는 peering/VPN으로 연결된 private subnet에 배치한다.
- 분산 실행의 `RemoteHosts`는 public IP가 아니라 엔진 노드의 private IP 또는 private DNS를 사용한다.
- 본시험 대상 URL, 계정, 경로, 이벤트 payload는 프로젝트 승인된 실제 값만 사용한다.

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

## 클라우드 표준 아키텍처

JMeter는 클라우드 VM 기반 분산 실행을 기본 운영 형태로 본다.

| 역할 | 배치 기준 | 접근 기준 |
| --- | --- | --- |
| 제어/작성 노드 | 관리 subnet 또는 테스트 전용 subnet | 운영자 PC는 bastion/VPN/RDP/SSH로만 접근 |
| 엔진 노드 | 테스트 전용 private subnet | 제어 노드에서만 RMI 포트 접근 허용 |
| 대상 시스템 | 운영과 분리된 검증 환경 또는 승인된 성능시험 대상 | 엔진 노드에서 대상 LB/WAF/API Gateway로 접근 |
| 결과 저장소 | object storage, 파일 저장소, 또는 중앙 NAS | 시험 종료 후 JTL/HTML/로그 장기 보관 |

클라우드 배치 원칙:

- 제어/작성 노드는 GUI 작성과 CLI 실행 관리를 담당한다.
- 엔진 노드는 GUI 없이 headless CLI 실행만 담당한다.
- 엔진 노드는 대상 서비스와 같은 VM에 배치하지 않는다.
- 엔진 노드와 대상 시스템이 같은 subnet에 있으면 결과가 과도하게 좋게 나올 수 있으므로 실제 사용자 경로와 테스트 목적에 맞게 subnet과 routing을 정한다.
- 장시간 시험은 클라우드 VM의 CPU credit, NIC bandwidth, disk I/O limit, LB/WAF rate limit을 사전에 확인한다.

## 클라우드 네트워크 기준

분산 실행 기준 security group 또는 방화벽은 아래를 최소 기준으로 둔다.

| 방향 | 포트 | 출발지 | 목적지 | 용도 |
| --- | --- | --- | --- | --- |
| 운영자 -> 제어 노드 | `22/tcp` 또는 `3389/tcp` | 운영자 고정 IP, VPN, bastion | 제어/작성 노드 | 관리 접속 |
| 제어 노드 -> 엔진 노드 | `1099/tcp` | 제어 노드 security group | 엔진 노드 security group | JMeter server registry |
| 제어 노드 -> 엔진 노드 | `50000/tcp` | 제어 노드 security group | 엔진 노드 security group | 고정 RMI server port |
| 엔진 노드 -> 제어 노드 | `51000/tcp` | 엔진 노드 security group | 제어 노드 security group | 고정 RMI client callback |
| 엔진 노드 -> 대상 시스템 | `80/tcp`, `443/tcp`, 또는 실제 서비스 포트 | 엔진 노드 security group | 대상 LB/WAF/API Gateway | 부하 발생 |
| 모든 노드 -> 패키지 저장소 | `443/tcp` | 제어/엔진 노드 | 공식 미러 또는 내부 저장소 | 설치 파일 다운로드 |

운영 원칙:

- security group은 CIDR보다 가능하면 source security group 기준으로 제한한다.
- RMI 포트는 public internet에 열지 않는다.
- 운영망 대상 시험은 고객 승인된 window, source IP, rate limit 예외 정책을 문서화한 뒤 실행한다.
- 폐쇄망이면 공식 바이너리와 SHA 파일을 object storage 또는 내부 artifact 저장소로 반입하고 동일한 검증 절차를 수행한다.

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

- 기본 구축은 `VM 또는 인스턴스 직접 설치`
- 작성은 GUI
- 실행은 CLI
- 대규모 시험은 다중 엔진 분산
- 새 프로젝트는 `web-standard-template.jmx`를 복제해 시작

### 부가 방식: 실행 러너 컨테이너화

- 가능: `예`
- 적합한 용도:
  - headless CLI runner
  - 분산 엔진 컨테이너
  - CI/CD 내 단기 실행
- 전제:
  - 기본 구축을 대체하지 않는다.
  - 제어/작성 노드는 컨테이너 대상이 아니다.
- 비적합한 용도:
  - JMeter 기본 구축 방식을 전부 컨테이너로 가져가는 방식
  - GUI 작성 환경을 컨테이너로 고정하는 방식
- 실무 권장:
  - `GUI 작성/디버깅은 로컬 또는 VM`
  - `기본 본시험 인프라는 VM 또는 인스턴스 직접 설치`
  - `필요할 때만 Docker 기반 CLI runner를 추가`

### 용어 정리

- `제어/작성 노드`: GUI로 `.jmx`를 만들고 실행을 관리하는 노드
- `실행 러너`: headless CLI로 실제 부하를 발생시키는 노드
- `엔진 노드`: 문맥상 실행 러너와 거의 같은 뜻으로 써도 되지만, 이 가이드에서는 `부하를 실제로 발생시키는 실행 노드`라는 의미로 사용한다.
- 따라서 이 가이드의 기본 JMeter 구축은 `제어/작성 노드`와 `엔진 노드`를 VM 또는 인스턴스에 직접 설치하는 방식이다.
- 이번 컨테이너 예시는 그 위에 선택적으로 붙이는 `실행 러너(엔진 노드)` 전용 부가 구성이다.

### 비권고 방식

- 운영 서버와 같은 인스턴스에서 실행
- GUI 상태로 장시간 본시험 실행
- `latest` 버전 무고정 배포

## 설치 Runbook

관리/작성 노드는 Windows 수동 설치 또는 PowerShell 자동 설치 중 하나를 선택한다. Linux 엔진 노드는 Linux 직접 설치 Runbook을 따른다.

## 클라우드 VM 준비 Runbook

### 1. VM 역할과 이름 확정

| 역할 | 이름 예시 | 기본 OS | 비고 |
| --- | --- | --- | --- |
| 제어/작성 노드 | `jmeter-control-01` | Windows Server 또는 Linux | GUI 작성이 필요하면 Windows 권장 |
| 엔진 노드 | `jmeter-engine-01`, `jmeter-engine-02` | Linux | headless 실행 |
| 결과 저장소 | `perf-results-<project>` | object storage 또는 파일 저장소 | 시험 산출물 보관 |

### 2. 공통 OS 준비

Linux 엔진 노드:

```bash
sudo hostnamectl set-hostname <jmeter-engine-name>
sudo timedatectl set-timezone Asia/Seoul
date
```

Windows 제어 노드:

```powershell
hostname
Get-Date
Get-NetIPConfiguration
```

### 3. private IP와 DNS 기록

아래 값을 프로젝트 실행 기록에 남긴다.

| 항목 | 값 |
| --- | --- |
| 제어 노드 private IP | `<control-private-ip>` |
| 엔진 노드 private IP 목록 | `<engine-private-ip-1>,<engine-private-ip-2>` |
| 대상 서비스 DNS | `<actual-target-dns>` |
| 대상 서비스 포트 | `<actual-target-port>` |
| 결과 저장 위치 | `<actual-result-storage>` |

### 4. security group 적용 확인

제어 노드에서 엔진 노드로 확인:

```powershell
Test-NetConnection <engine-private-ip-1> -Port 1099
Test-NetConnection <engine-private-ip-1> -Port 50000
```

엔진 노드에서 제어 노드 callback 포트 확인:

```bash
nc -vz <control-private-ip> 51000
```

엔진 노드에서 대상 서비스 접근 확인:

```bash
curl -k -I "https://<actual-target-dns>/<actual-health-path>"
```

## Windows 설치 Runbook

관리/작성 노드에서 GUI 작성과 CLI smoke를 모두 수행할 때 사용한다.

### 1. Java 확인

```powershell
java -version
```

기대 기준:

- Java가 실행된다.
- 버전은 `17` 이상을 권장한다.

Java가 없으면 Temurin 또는 조직 표준 JDK를 설치하고 새 터미널에서 다시 확인한다.

### 2A. 웹사이트에서 수동 설치

Windows 관리/작성 노드에서는 이 방식이 가장 직관적이다.

1. Apache JMeter 다운로드 페이지 접속: <https://jmeter.apache.org/download_jmeter.cgi>
2. `Binaries`에서 `apache-jmeter-5.6.3.zip` 다운로드
3. 같은 항목의 `sha512` 파일 다운로드
4. ZIP 파일을 `C:\tools` 아래에 압축 해제
5. 최종 경로가 `C:\tools\apache-jmeter-5.6.3\bin\jmeter.bat`인지 확인

다운로드 파일을 `Downloads` 폴더에 받은 경우 SHA-512 확인:

```powershell
$Zip = "$env:USERPROFILE\Downloads\apache-jmeter-5.6.3.zip"
$Sha = "$env:USERPROFILE\Downloads\apache-jmeter-5.6.3.zip.sha512"

$ExpectedHash = (Get-Content $Sha -Raw).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim()
$ActualHash = (Get-FileHash $Zip -Algorithm SHA512).Hash.ToLower()

if ($ActualHash -ne $ExpectedHash.ToLower()) {
  throw "JMeter archive SHA-512 mismatch"
}
```

압축 해제:

```powershell
New-Item -ItemType Directory -Path "C:\tools" -Force | Out-Null
Expand-Archive -Path "$env:USERPROFILE\Downloads\apache-jmeter-5.6.3.zip" -DestinationPath "C:\tools" -Force
& "C:\tools\apache-jmeter-5.6.3\bin\jmeter.bat" --version
```

GUI 실행:

```powershell
& "C:\tools\apache-jmeter-5.6.3\bin\jmeter.bat"
```

### 2B. PowerShell 자동 설치

반복 구축, 폐쇄망 반입 검증, 설치 로그 확보가 필요할 때 사용한다. 수동 설치가 더 편하면 2A만 수행해도 된다.

```powershell
$JMeterVersion = "5.6.3"
$InstallRoot = "C:\tools"
$Zip = Join-Path $env:TEMP "apache-jmeter-$JMeterVersion.zip"
$Sha = "$Zip.sha512"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
Invoke-WebRequest `
  -Uri "https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-$JMeterVersion.zip" `
  -OutFile $Zip
Invoke-WebRequest `
  -Uri "https://downloads.apache.org/jmeter/binaries/apache-jmeter-$JMeterVersion.zip.sha512" `
  -OutFile $Sha
```

SHA-512 확인:

```powershell
$ExpectedHash = (Get-Content $Sha -Raw).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim()
$ActualHash = (Get-FileHash $Zip -Algorithm SHA512).Hash.ToLower()

if ($ActualHash -ne $ExpectedHash.ToLower()) {
  throw "JMeter archive SHA-512 mismatch"
}
```

압축 해제:

```powershell
Expand-Archive -Path $Zip -DestinationPath $InstallRoot -Force
$env:JMETER_HOME = Join-Path $InstallRoot "apache-jmeter-$JMeterVersion"
& "$env:JMETER_HOME\bin\jmeter.bat" --version
```

GUI 실행 확인:

```powershell
& "C:\tools\apache-jmeter-5.6.3\bin\jmeter.bat"
```

GUI는 작성과 디버깅에만 사용한다. 본시험은 CLI로 실행한다.

## Linux 직접 설치 Runbook

엔진 노드 또는 Linux 기반 관리 노드에서 사용한다.

### 1. Java 설치 및 확인

Ubuntu 계열:

```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jre-headless curl unzip netcat-openbsd
java -version
```

Rocky/RHEL 계열:

```bash
sudo dnf install -y java-17-openjdk-headless curl unzip nmap-ncat
java -version
```

### 2. JMeter 다운로드, 검증, 설치

```bash
JMETER_VERSION=5.6.3
INSTALL_ROOT=/opt
cd /tmp

curl -fSLO "https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz"
curl -fSLO "https://downloads.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz.sha512"

EXPECTED_HASH="$(awk '{print $1}' "apache-jmeter-${JMETER_VERSION}.tgz.sha512")"
ACTUAL_HASH="$(sha512sum "apache-jmeter-${JMETER_VERSION}.tgz" | awk '{print $1}')"
test "$EXPECTED_HASH" = "$ACTUAL_HASH"

sudo tar -xzf "apache-jmeter-${JMETER_VERSION}.tgz" -C "$INSTALL_ROOT"
sudo ln -sfn "$INSTALL_ROOT/apache-jmeter-${JMETER_VERSION}" /opt/jmeter
/opt/jmeter/bin/jmeter --version
```

### 3. 환경변수 설정

```bash
cat <<'EOF' | sudo tee /etc/profile.d/jmeter.sh
export JMETER_HOME=/opt/jmeter
export PATH=$JMETER_HOME/bin:$PATH
EOF

source /etc/profile.d/jmeter.sh
jmeter --version
```

## 검증 Runbook

### 1. 표준 플랜 CLI Smoke 실행

실제 대상 값으로만 실행한다. 아래 값은 모두 실제 환경 기준으로 바꿔야 한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\Jmeter\scripts\run-local.ps1 `
  -ProjectName "<project-name>" `
  -JMeterHome "C:\tools\apache-jmeter-5.6.3" `
  -Protocol "https" `
  -Host "<actual-host>" `
  -Port 443 `
  -Threads 1 `
  -RampUp 0 `
  -Loops 1 `
  -ThinkTimeMs 0 `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

성공 확인:

```powershell
Get-ChildItem .\Jmeter\reports\<project-name> -Recurse
```

확인해야 할 산출물:

- `*.jtl`
- `html-*` 디렉터리
- `html-*/index.html`

### 2. HTML Dashboard 단독 생성

이미 생성된 JTL에서 리포트만 다시 만들 때 사용한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\Jmeter\scripts\generate-report.ps1 `
  -JMeterHome "C:\tools\apache-jmeter-5.6.3" `
  -JtlFile "<actual-result-jtl-path>" `
  -HtmlDir "<actual-html-output-dir>"
```

## Docker/Container 운영 해석

- JMeter 공식 문서는 Docker를 주요 설치 경로로 전면에 두지 않지만, Java 기반 구조상 컨테이너 실행은 충분히 가능하다.
- 다만 JMeter의 핵심은 `GUI 설계`와 `CLI 실행`이 분리된다는 점이다.
- 따라서 이 저장소에서는 아래를 기본 원칙으로 본다.
  - JMeter 표준 구축은 `VM 또는 인스턴스 직접 설치`
  - Docker는 `실행 러너 보조 수단`
- 실무에서는 보통 아래처럼 운용한다.
  - 설계자 PC 또는 관리 VM에서 `.jmx` 작성
  - 엔진 노드 또는 러너는 VM에 직접 설치해 기본 운영
  - 필요한 경우에만 Docker 컨테이너를 `-n` CLI 실행 전용으로 추가
  - 결과 JTL/HTML은 볼륨 마운트로 외부 저장
- 즉, `JMeter를 Docker로 할 수 있느냐`의 답은 `예`이지만, 이 가이드의 메인 구축 방식은 Docker가 아니다.

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
2. `PROJECT_NAME`, `PROTOCOL`, `HOST`, `PORT`, `THREADS`, `LOOPS`, `HEALTH_PATH`, `LOGIN_PATH`, `LIST_PATH`, `DETAIL_PATH`, `EVENT_PATH`, `EVENT_PAYLOAD`, `USERNAME`, `PASSWORD`를 실제 값으로 입력
3. Compose 설정을 검증
4. `Jmeter/infra/docker-runner/run.ps1` 실행
5. 결과는 `Jmeter/reports/<PROJECT_NAME>/<yyyymmdd>/`에 생성

```powershell
Copy-Item .\Jmeter\infra\docker-runner\.env.example .\Jmeter\infra\docker-runner\.env
notepad .\Jmeter\infra\docker-runner\.env

docker compose `
  --env-file .\Jmeter\infra\docker-runner\.env `
  -f .\Jmeter\infra\docker-runner\docker-compose.yml `
  config

powershell -ExecutionPolicy Bypass -File .\Jmeter\infra\docker-runner\run.ps1
```

컨테이너 실행 후 결과 확인:

```powershell
Get-ChildItem .\Jmeter\reports -Recurse
```

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
- 실행 스크립트는 임시 기본값을 제공하지 않으며, 필수 인자가 비어 있으면 실패해야 한다.
- 프로젝트에서 반복 검증된 구조는 템플릿 원본에 환류한다.

## 보안/네트워크 기준

- 테스트 계정은 운영 개인 계정이 아니라 승인된 부하테스트 전용 계정만 사용한다.
- 비밀번호, 토큰, 세션값은 `.jmx`, PowerShell, Git 추적 파일에 저장하지 않는다.
- RMI 포트 `1099/tcp`, `50000/tcp`는 테스트 제어 노드와 엔진 노드 사이에서만 허용한다.
- `server.rmi.ssl.disable=true`는 격리된 테스트 네트워크에서만 허용한다.
- 부하발생기는 운영 서비스와 같은 인스턴스에 배치하지 않는다.

## 원격/분산 운영 원칙

- 모든 엔진은 같은 JMeter 버전을 사용한다.
- 테스트 플랜은 엔진 수만큼 동일하게 실행되므로 총 부하가 선형에 가깝게 증가하는지 본시험 전 확인한다.
- 본시험 전 반드시 단일 엔진 smoke test를 수행한다.
- 엔진 CPU 80% 이상이면 인스턴스를 키우기보다 엔진 수를 늘리는 것을 먼저 검토한다.
- CSV 같은 데이터 파일은 제어 노드가 자동 전송하지 않으므로 각 엔진에 동일 경로로 배치한다.

## 원격/분산 실행 Runbook

### 1. 엔진 노드 설치

각 엔진 노드에 Linux 직접 설치 Runbook과 동일한 버전의 JMeter를 설치한다.

```bash
/opt/jmeter/bin/jmeter --version
java -version
```

### 2. 엔진 노드 RMI 포트 고정

방화벽 환경에서는 RMI 동적 포트가 문제를 만들 수 있으므로 로컬 포트를 고정한다.

```bash
cat <<'EOF' | sudo tee -a /opt/jmeter/bin/user.properties
server.rmi.localport=50000
server.rmi.ssl.disable=true
EOF
```

클라우드 VM에서 RMI가 public IP, hostname, loopback 주소를 잘못 광고하면 엔진 private IP를 JVM system property로 고정한다.

```bash
PRIVATE_IP="<engine-private-ip>"
echo "JVM_ARGS=-Djava.rmi.server.hostname=${PRIVATE_IP}" | sudo tee /etc/default/jmeter-server
```

주의:

- `server.rmi.ssl.disable=true`는 격리된 테스트 네트워크에서만 사용한다.
- 운영 보안 기준상 RMI SSL이 필요하면 keystore를 구성하고 이 값을 사용하지 않는다.

### 3. 엔진 노드 방화벽 허용

Ubuntu UFW 사용 시:

```bash
sudo ufw allow 1099/tcp
sudo ufw allow 50000/tcp
sudo ufw status
```

firewalld 사용 시:

```bash
sudo firewall-cmd --add-port=1099/tcp --permanent
sudo firewall-cmd --add-port=50000/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

### 4. 엔진 서버 기동

```bash
SERVER_PORT=1099 /opt/jmeter/bin/jmeter-server
```

백그라운드 기동이 필요하면 systemd 단위로 등록한다.

```bash
cat <<'EOF' | sudo tee /etc/systemd/system/jmeter-server.service
[Unit]
Description=Apache JMeter Server
After=network-online.target

[Service]
Type=simple
Environment=JMETER_HOME=/opt/jmeter
EnvironmentFile=-/etc/default/jmeter-server
Environment=SERVER_PORT=1099
ExecStart=/opt/jmeter/bin/jmeter-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now jmeter-server
sudo systemctl status jmeter-server --no-pager
```

### 5. 제어 노드에서 연결 확인

```powershell
Test-NetConnection <engine-ip-1> -Port 1099
Test-NetConnection <engine-ip-1> -Port 50000
```

### 6. 분산 smoke 실행

```powershell
powershell -ExecutionPolicy Bypass -File .\Jmeter\scripts\run-distributed.ps1 `
  -ProjectName "<project-name>" `
  -JMeterHome "C:\tools\apache-jmeter-5.6.3" `
  -RemoteHosts "<engine-ip-1>,<engine-ip-2>" `
  -ClientRmiLocalPort 51000 `
  -Protocol "https" `
  -Host "<actual-host>" `
  -Port 443 `
  -Threads 1 `
  -RampUp 0 `
  -Loops 1 `
  -ThinkTimeMs 0 `
  -HealthPath "<actual-health-path>" `
  -LoginPath "<actual-login-path>" `
  -ListPath "<actual-list-path>" `
  -DetailPath "<actual-detail-path>" `
  -EventPath "<actual-event-path>" `
  -EventPayload '<actual-json-payload>' `
  -Username "<actual-username>" `
  -Password "<actual-password>"
```

분산 실행 해석:

- `Threads=1`, 엔진 2대면 총 실행 thread는 2개다.
- 본시험 전 반드시 `Threads=1`, `Loops=1`로 연결성과 결과 생성을 먼저 확인한다.
- 클라우드에서는 `<engine-ip>`에 public IP가 아니라 private IP 또는 private DNS를 사용한다.

## 기본 검증 항목

1. GUI 실행 확인
2. CLI 실행 확인
3. CSV 결과 파일 생성 확인
4. HTML Dashboard 생성 확인
5. 다중 엔진 시 네트워크 통신 확인

## 장애 조치

- `java` 명령이 없으면 JDK 설치 후 새 터미널에서 `java -version`을 다시 실행한다.
- SHA-512 검증이 실패하면 바이너리를 사용하지 말고 공식 미러 또는 archive 경로에서 다시 내려받는다.
- CLI 실행이 실패하면 `JMeterHome`, 대상 host/path, 인증값, 결과 디렉터리 권한을 순서대로 확인한다.
- 분산 실행이 실패하면 엔진별 `jmeter-server` 상태, security group, NACL, route table, RMI 포트, 동일 JMeter 버전을 확인한다.
- RMI 연결이 한쪽 방향만 실패하면 엔진에서 제어 노드 callback 포트 `51000/tcp`로 접근 가능한지 확인한다.
- HTML Dashboard 생성이 실패하면 기존 출력 디렉터리를 비우고 JTL 파일이 비어 있지 않은지 확인한다.

## 운영 체크리스트

- `jmeter --version` 또는 `jmeter.bat --version` 결과가 `5.6.3`이다.
- Java 버전이 조직 기준을 만족한다.
- 표준 플랜 복제본이 실제 대상 경로와 계정을 사용한다.
- smoke 실행 결과 `*.jtl`과 `html-*/index.html`이 생성된다.
- 분산 시험은 모든 엔진에서 같은 JMeter 버전과 같은 데이터 파일을 사용한다.
- 제어/엔진/대상 시스템 간 private network 경로와 security group 정책이 기록되어 있다.
- 결과 산출물은 프로젝트 표준 object storage 또는 파일 저장소에 보관된다.
- 팀 배포 전 루트에서 `powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict`를 실행한다.

## 구축 완료 기준

- JMeter GUI/CLI가 정상 실행된다.
- 표준 플랜이 단일 엔진에서 정상 완료된다.
- 클라우드 private network 기반 분산 smoke가 정상 완료된다.
- HTML Dashboard가 생성된다.
- 결과 로그가 `reports/`에 정리된다.
- 결과 산출물이 클라우드 결과 저장소에 보관된다.
