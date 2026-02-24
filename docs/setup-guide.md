# 설치 가이드

`claude-aws-infra-kit` 을 처음부터 설정하는 단계별 가이드입니다.

---

## 1. AWS CLI v2 설치

### macOS

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
```

### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

---

## 2. IAM 사용자 생성 (없는 경우)

일상적인 인프라 관리를 위해 읽기 권한과 최소한의 쓰기 권한을 가진 전용 IAM 사용자를 생성합니다.

### 최소 권장 권한

다음 AWS 관리형 정책을 연결하세요:

| 정책 | 목적 |
|------|------|
| `ReadOnlyAccess` | 모든 리소스 읽기 (`/inventory`, `/costs` 등에 필수) |
| `AmazonEC2FullAccess` | EC2 관리가 필요한 경우 |
| `ElasticLoadBalancingFullAccess` | ALB 관리가 필요한 경우 |

또는 관리하는 서비스에만 범위를 한정한 커스텀 정책을 사용하세요.

### 액세스 키 생성

1. IAM → 사용자 → 해당 사용자 → 보안 자격 증명으로 이동
2. **액세스 키 만들기** 클릭
3. 사용 사례로 **CLI** 선택
4. **액세스 키 ID** 와 **비밀 액세스 키** 를 다운로드하거나 복사

---

## 3. setup.sh 실행

```bash
git clone https://github.com/YOUR_USERNAME/claude-aws-infra-kit.git
cd claude-aws-infra-kit
./setup.sh
```

프롬프트가 나타나면 다음을 입력하세요:

- **AWS 프로파일 이름** — 이 계정/환경에 사용할 이름 (예: `mycompany`, `prod`, `dev`)
- **AWS 리전** — 기본 리전 (예: `us-east-1`, `ap-northeast-2`)
- **AWS 계정 ID** — AWS 콘솔 우측 상단의 12자리 숫자
- **메인 도메인** — 기본 도메인 (예: `example.com`), 없으면 빈칸으로
- **VPC ID** — EC2 → VPC 또는 `aws ec2 describe-vpcs --output json` 에서 확인
- **자격 증명 설정?** — 액세스 키 ID와 시크릿을 입력하려면 `y`

---

## 4. 설정 확인

```bash
# 생성된 파일이 존재하는지 확인
ls CLAUDE.md .claude/settings.json state/ logs/

# AWS 연결 확인
aws sts get-caller-identity --profile YOUR_PROFILE
```

---

## 5. Claude Code 실행

```bash
claude
```

첫 번째 커맨드:

```
/inventory
```

모든 AWS 리소스를 조회하고 스냅샷을 `state/` 에 저장합니다.

---

## 6. CLAUDE.md 커스터마이즈

`CLAUDE.md` 를 열어 **보호 리소스** 테이블에 환경의 공유 리소스를 추가하세요. 이 리소스들은 삭제 계획 전에 Claude가 경고를 표시하는 대상입니다.

일반적인 예시:
- 여러 서비스에서 사용하는 공유 ALB
- 여러 EC2 인스턴스에서 사용하는 배스천 호스트 보안 그룹
- 여러 서브도메인을 커버하는 ACM 인증서
- Route 53 호스팅 영역

---

## 문제 해결

### "Unable to locate credentials"

```bash
aws configure list --profile YOUR_PROFILE
```

자격 증명이 없다면 `./setup.sh` 를 다시 실행하고 자격 증명 설정 여부를 묻는 단계에서 `y` 를 입력하세요.

### "An error occurred (AccessDenied)"

IAM 사용자에게 필요한 권한이 없습니다. IAM 사용자 또는 역할에 `ReadOnlyAccess` 를 추가하세요.

### Claude가 커맨드를 인식하지 못하는 경우

kit 디렉토리에서 `claude` 를 실행하고 있는지 확인하세요. Claude Code는 현재 디렉토리에서 `CLAUDE.md` 를 로드합니다.
