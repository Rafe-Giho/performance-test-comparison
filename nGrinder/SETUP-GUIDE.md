# nGrinder 구축 가이드

## 문서 등급

문서 등급: 팀 배포용 표준 운영 가이드

## 운영 환경

운영 환경: 클라우드 기반 테스트 환경

이 문서의 구축, 실행, 검증 기준은 클라우드 기반 테스트 환경을 전제로 한다. 테스트 인프라는 프로젝트별 클라우드 VM, 컨테이너, Kubernetes/NKS 자원으로 구성하고 운영 서비스와 논리적으로 분리한다.

## 적용 대상

- 단기 프로젝트에서 빠르게 웹 UI 기반 부하 테스트 환경을 올려야 하는 경우
- `Controller 1 + Agent N` 구조를 Docker Compose로 재현해야 하는 경우
- 장기 표준 도구가 아니라 한시 운영 도구로 nGrinder를 활용하는 경우
- 테스트 대상과 같은 클라우드 VPC 안의 private subnet에서 부하를 발생시켜야 하는 경우

## 공식 기준

- 저장소: <https://github.com/naver/ngrinder>
- 릴리스: <https://github.com/naver/ngrinder/releases>
- 설치 가이드: <https://github.com/naver/ngrinder/wiki/Installation-Guide>
- Agent 설정 가이드: <https://github.com/naver/ngrinder/wiki/Agent-Configuration-Guide>
- Docker Engine 설치 기준: <https://docs.docker.com/engine/install/ubuntu/>

운영 기준 버전은 `ngrinder/controller:3.5.9-p1`, `ngrinder/agent:3.5.9-p1`이다. GitHub 기준 `ngrinder-3.5.9-p1-20240613`이 최신 릴리스이며, 저장소는 `2025-09-24` 이후 archive 상태다. archive 상태 도구이므로 인터넷 공개형 상시 플랫폼으로 운영하지 않고 프로젝트 단위 단기 환경으로 제한한다.

## 사전 조건

- 클라우드 VPC 안에 테스트 전용 VM을 준비한다.
- Controller VM은 운영자 VPN 또는 bastion에서만 접근 가능해야 한다.
- Agent는 Controller와 같은 private subnet 또는 라우팅 가능한 테스트 subnet에 둔다.
- 대상 시스템 부하 테스트 승인 범위, 허용 시간, 허용 TPS, 계정, 데이터가 확정되어 있다.
- Docker Engine과 Docker Compose plugin이 설치되어 있다.
- Controller 결과 볼륨 백업 위치와 object storage 보관 정책이 정해져 있다.
- 보안그룹 또는 방화벽에서 아래 포트를 승인한다.

| 방향 | 포트 | 허용 주체 | 목적 |
| --- | --- | --- | --- |
| 운영자 -> Controller | `8080/tcp` | VPN 또는 bastion CIDR | Controller UI |
| Agent -> Controller | `16001/tcp` | Agent security group | Agent 제어 채널 |
| Agent -> Controller | `12000-12009/tcp` | Agent security group | 테스트 실행 콘솔 포트 |
| Controller -> Monitor | `13243/tcp` | 대상 서버 또는 Monitor subnet | 선택 운영 시 시스템 모니터링 |
| Agent -> 대상 시스템 | `80/tcp`, `443/tcp` 또는 승인 포트 | Agent security group | 부하 발생 |
| 운영자 -> VM | `22/tcp` | bastion CIDR | SSH 운영 |

## 설치 Runbook

### 1. 클라우드 VM 준비

권장 시작 사양은 Controller와 Agent를 분리하는 구성이다.

| 규모 | Controller | Agent |
| --- | --- | --- |
| Smoke/소규모 | `2 vCPU / 4 GB / 50 GB` | `2대`, 각 `4 vCPU / 8 GB / 50 GB` |
| 중규모 | `4 vCPU / 8 GB / 100 GB` | `3~5대`, 각 `8 vCPU / 16 GB / 100 GB` |
| 단일 통합 VM | `8 vCPU / 16 GB` 이상 | Controller와 Agent 동거 |

단일 통합 VM은 빠르게 구축할 수 있지만 Controller와 Agent가 CPU, 메모리, I/O를 공유한다. 결과 해석 시 부하 발생기 병목을 반드시 분리한다.

### 2. Ubuntu VM에 Docker 설치

Ubuntu 22.04/24.04 LTS 기준이다. Docker 공식 apt repository 방식을 사용한다.

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
docker version
docker compose version
```

운영 계정으로 Docker를 직접 실행해야 한다면 승인된 운영 VM에서만 아래를 적용한다.

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker version
```

### 3. Compose 설정 검증

저장소 루트에서 실행한다.

```bash
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml config
```

Windows 운영 PC 또는 PowerShell이 설치된 VM에서는 동일 검증을 아래처럼 수행할 수 있다.

```powershell
docker compose -p ngrinder -f .\nGrinder\compose\docker-compose.yml config
```

### 4. Controller + Agent 기동

클라우드 Linux VM에서 직접 실행하는 기본 명령이다.

```bash
mkdir -p nGrinder/compose/volumes/controller
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml pull
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml up -d --scale agent=1 --remove-orphans
```

PowerShell wrapper를 사용할 경우 아래를 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\nGrinder\compose\up.ps1 -ProjectName ngrinder -AgentScale 1 -Pull
```

Agent를 늘릴 때는 먼저 smoke가 성공한 뒤 단계적으로 확장한다.

```bash
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml up -d --scale agent=3 --remove-orphans
```

### 5. 기동 상태 확인

```bash
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml ps
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml logs --tail=100 controller
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml logs --tail=100 agent
curl -I http://127.0.0.1:8080
```

원격 운영자는 VPN 또는 bastion 경유로 `http://<controller-vm-private-ip>:8080`에 접속한다. Controller UI를 공인 인터넷에 직접 노출하지 않는다.

## 검증 Runbook

### 1. 이미지와 버전 검증

```bash
docker image inspect ngrinder/controller:3.5.9-p1 --format '{{.RepoTags}} {{.Id}}'
docker image inspect ngrinder/agent:3.5.9-p1 --format '{{.RepoTags}} {{.Id}}'
docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml ps
```

### 2. Controller UI 검증

```bash
curl -I http://127.0.0.1:8080
```

정상 기준은 HTTP `200`, `302`, 또는 로그인 페이지 응답이다. 브라우저에서는 `admin/admin` 초기 계정으로 접속한 뒤 즉시 비밀번호를 변경한다.

### 3. Agent 연결 검증

- Controller UI의 Agent Management에서 Agent가 연결 상태로 보이는지 확인한다.
- Compose scale 수와 UI의 Agent 수가 일치하는지 확인한다.
- Agent가 보이지 않으면 `16001/tcp`, `12000-12009/tcp`, Docker network DNS `controller` 해석 여부를 확인한다.

### 4. 표준 스크립트 검증

- `nGrinder/scripts/web_standard_template.groovy`를 프로젝트 스크립트로 복제한다.
- `test.baseUrl`, `test.healthPath`, `test.loginPath`, `test.listPath`, `test.detailPath`, `test.eventPath`, `test.eventPayload`, `test.username`, `test.password`를 승인된 실제 값으로 입력한다.
- Agent 1개, 낮은 vuser, 짧은 duration으로 smoke를 먼저 실행한다.
- smoke 성공 후에만 Load/Stress/Spike/Soak 실행으로 넘어간다.

### 5. 결과 보관 검증

```bash
mkdir -p nGrinder/reports/<project>/<yyyymmdd>
```

Controller UI 결과 화면, 실행 스크립트 사본, Agent 수, vuser, duration, 대상 시스템 지표를 `nGrinder/reports/<project>/<yyyymmdd>/`에 저장한다. 장기 보관이 필요한 산출물은 object storage 버킷으로 복제한다.

## 보안/네트워크 기준

- Controller UI `8080/tcp`는 VPN 또는 bastion CIDR에만 허용한다.
- Agent 통신 포트 `16001/tcp`, `12000-12009/tcp`는 Agent security group에서만 허용한다.
- 테스트 계정과 비밀번호는 Groovy 원본 파일에 저장하지 않는다.
- Controller 볼륨 `nGrinder/compose/volumes/controller`에는 스크립트와 결과가 남으므로 프로젝트 종료 후 보관 또는 폐기한다.
- Docker가 host firewall을 우회할 수 있으므로 클라우드 보안그룹과 VM 내부 `DOCKER-USER` chain 정책을 함께 확인한다.
- archive 상태 도구이므로 장기 인터넷 노출, 멀티테넌트 상시 운영, 신규 표준 플랫폼 채택은 금지한다.

## 장애 조치

- Controller UI가 열리지 않으면 `docker compose ps`, `docker compose logs controller`, `8080/tcp` 포트 점유를 확인한다.
- Agent가 연결되지 않으면 Agent 로그, Controller service DNS, `16001/tcp`, `12000-12009/tcp` 방화벽을 확인한다.
- Agent scale이 늘지 않으면 고정 `container_name` 또는 공유 Agent home volume이 Compose 파일에 재도입됐는지 확인한다.
- JVM 메모리 오류가 발생하면 Agent 수, vuser, 컨테이너 메모리, VM 메모리를 함께 줄이거나 증설한다.
- TPS가 기대보다 낮으면 Agent CPU/메모리 병목과 대상 시스템 병목을 분리한다.
- 결과 저장이 누락되면 Controller 볼륨 권한과 디스크 사용량을 확인한다.

## 운영 체크리스트

- Controller/Agent 이미지가 `3.5.9-p1`로 고정되어 있다.
- `docker compose -p ngrinder -f nGrinder/compose/docker-compose.yml config`가 통과한다.
- Controller UI가 VPN 또는 bastion을 통해서만 접근된다.
- Agent가 Controller UI에서 연결 상태로 보인다.
- smoke 테스트 결과가 생성되고 에러율, TPS, 응답시간을 확인했다.
- 결과를 `reports/<project>/<yyyymmdd>/`와 object storage에 보관했다.
- 팀 배포 전 루트에서 `powershell -ExecutionPolicy Bypass -File .\tools\validate-workspace.ps1 -Strict`를 실행했다.

## 구축 완료 기준

- Docker Engine과 Docker Compose plugin 버전 확인 완료
- `ngrinder/controller:3.5.9-p1`, `ngrinder/agent:3.5.9-p1` 이미지 pull 완료
- `docker compose -p ngrinder ... up -d --scale agent=1` 기동 완료
- Controller UI 접속 가능
- Agent 연결 확인
- 표준 Groovy smoke 테스트 정상 실행
- 결과 리포트와 보관 위치 확인
