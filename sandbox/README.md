# sandbox

에픽 #4(팀 단위 안전장치)를 검증하는 데 쓰는 테스트 인프라입니다. 보호해야 하는 리소스, 지워도 되는 리소스, 감사에 걸리는 리소스를 한 스택으로 만들고 한 명령으로 지웁니다.

> **개인 샌드박스 계정에서만 쓰세요.** `up.sh`/`down.sh`는 `SANDBOX_ACCOUNT_ID`와 실제 계정이 다르면 실행하지 않습니다.

## 만들어지는 리소스

| 역할      | 이름                                       | 무엇을 검증하나                              |
| --------- | ------------------------------------------ | -------------------------------------------- |
| 보호      | `iac-sandbox-vpc` (`Protected=true`)       | P2 `delete-vpc` deny, P3 태그 Deny           |
| 보호      | `shared-sg` (`Protected=true`)             | P1 가드 훅, P3 태그 Deny, P6 인젝션 대상     |
| 삭제 대상 | `svc-a` (EC2 `t4g.nano`)                   | 승인 흐름, `/plan-removal` 순서              |
| 삭제 대상 | `svc-a-sg`                                 | 인스턴스를 먼저 지워야 지울 수 있음 (의존성) |
| 삭제 대상 | `svc-a-orphan-data` (EBS 1GB, 미연결)      | `/find-unused`                               |
| 감사 대상 | `legacy-ssh-sg` (22번 `0.0.0.0/0`, 미연결) | `/audit-sg`, `/find-unused`                  |

- `svc-a`에는 `shared-sg`와 `svc-a-sg`가 둘 다 붙어 있습니다. 그래서 `shared-sg`는 실제로 쓰이는 상태고, `svc-a-sg`는 인스턴스를 먼저 지워야 지울 수 있습니다
- IGW, NAT, 퍼블릭 IP는 없습니다. 밖에서 접근할 수 없고 IPv4 요금도 나오지 않습니다
- 모든 리소스에 `Project=iac-sandbox` 태그가 붙습니다. `down.sh`는 이 태그로 남은 리소스가 있는지 확인합니다

## 비용

켜 둔 동안만 과금됩니다. 실험할 때만 `up.sh`를 돌리고, 끝나면 바로 `down.sh`를 돌리세요.

| 항목                            | 단가 (ap-northeast-2, 온디맨드) | 시간당                          |
| ------------------------------- | ------------------------------- | ------------------------------- |
| EC2 `t4g.nano`                  | $0.0052/h                       | $0.0052                         |
| EBS gp3 9GB (루트 8 + 미연결 1) | $0.0912/GB-월                   | $0.0011                         |
| VPC, 서브넷, SG                 | 무료                            | —                               |
| **합계**                        |                                 | **약 $0.007/h (하루 약 $0.15)** |

단가는 2026-11 공시가 기준 추정치입니다. 실제 청구액과는 P5(#10)에서 대조합니다.

## 계정 준비 (한 번만)

스택 밖에서 손으로 하는 설정입니다. 스택에 넣으면 `down.sh`를 돌릴 때 같이 지워지기 때문입니다.

- [ ] 새 AWS 계정 생성, **루트 MFA** 설정
- [ ] **Organizations** 활성화
- [ ] **IAM Identity Center** 활성화, 관리자 사용자 1명 + `AdministratorAccess` 권한 세트 (P3에서 `InfraRead`/`InfraOperator`로 나눕니다)
- [ ] **예산 알림 $10** (Billing → Budgets → 월 비용 예산, 80%/100% 이메일 알림)
- [ ] **Cost Explorer** 활성화 (데이터가 쌓이는 데 최대 24시간. P5에서 씁니다)
- [ ] CLI 프로필 설정

  ```bash
  aws configure sso --profile iac-sandbox   # 리전 ap-northeast-2
  aws sso login --profile iac-sandbox
  ```

- [ ] `sandbox/.env` 작성 (gitignore 대상)

  ```bash
  SANDBOX_PROFILE=iac-sandbox
  SANDBOX_ACCOUNT_ID=123456789012
  # SANDBOX_REGION=ap-northeast-2   # 생략하면 프로필 리전
  ```

킷 자체도 샌드박스를 보게 하려면 `./setup.sh`에서 프로필 `iac-sandbox`, VPC는 `up.sh` 출력의 `VpcId`를 넣으세요.

## 사용법

```bash
sandbox/up.sh      # 스택 생성 (약 2~3분), 리소스 ID 출력
# Claude Code에서: /inventory, /audit-sg, /find-unused, ...
sandbox/down.sh    # 스택 삭제 + 남은 리소스 확인
```

- 실험 중에 리소스를 지웠거나 바꿨다면 `down.sh` → `up.sh`로 초기화하세요. `up.sh`만 다시 돌리면 CloudFormation이 바뀐 것을 알아채지 못해 복구되지 않습니다
- 실험 중에 스택 밖에서 만든 리소스(예: P6 시나리오용 SG)가 VPC 안에 남아 있으면 스택 삭제가 실패합니다. `down.sh`가 실패한 리소스를 보여 줍니다

## 완료 확인 (#5)

1. `up.sh` → `/inventory` → `down.sh`가 한 번에 돈다
2. `down.sh` 뒤 `/find-unused`에서 샌드박스 리소스가 나오지 않는다
