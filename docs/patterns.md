# 권장 패턴

`infra-as-claude` 을 효과적으로 활용하기 위한 워크플로우와 모범 사례입니다.

---

## 주간 루틴

가볍게 주 1회 인프라를 점검하는 워크플로우:

```
1. /inventory          ← 현재 상태 스냅샷, 변경 사항 확인
2. /find-unused        ← 새로 생긴 유휴 리소스 식별
3. /costs              ← 지난주 대비 비용 변화 확인
4. /update-docs        ← 체인지로그 및 문서 동기화
```

약 10분 정도 소요되며 인프라 가시성을 높게 유지할 수 있습니다.

---

## 삭제 전 필수 절차

항상 다음 순서를 따르세요:

```
1. /inventory                    ← state/ 가 최신 상태인지 확인
2. /plan-removal <대상>          ← 의존성 순서가 정렬된 계획 검토
3. 보호 리소스 검토              ← 공유 리소스가 범위에 포함되지 않았는지 확인
4. 계획 승인                     ← Claude가 확인을 요청합니다
5. /update-docs                  ← CHANGELOG.md에 삭제 내역 기록
```

계획 단계를 절대 건너뛰지 마세요. "단순한" EC2 종료도 ALB 타겟 그룹을 망가뜨리거나 고아 EBS 볼륨을 남길 수 있습니다.

---

## 인프라 변경 이력 추적 (opt-in)

`state/*.json` 은 **기본적으로 gitignore** 됩니다 — 스냅샷에는 사설 IP, ARN 등 인프라
메타데이터가 담기므로 실수로 공개 저장소에 올라가는 것을 막기 위함입니다.

팀에서 인프라 이력을 공유하고 싶다면 **private 저장소**에서만 opt-in 하세요. `.gitignore`
에서 `state/*.json` 줄을 제거한 뒤 커밋합니다:

```bash
# .gitignore 에서 `state/*.json` 줄을 먼저 제거 (private repo에서만!)
git add state/
git commit -m "infra snapshot: old-service EC2 제거"
```

상태 파일에 `git diff` 를 사용하면 임의의 두 시점 사이에 무엇이 변경됐는지 파악할 수 있습니다.

> ⚠️ 공개 저장소에는 절대 `state/` 를 커밋하지 마세요. 인프라 구조가 그대로 노출됩니다.

---

## 새 서비스 추가 시

새 서비스를 배포할 때 즉시 `CLAUDE.md` 에 문서화하세요:

1. 공유 리소스(ALB, SG)를 사용한다면 보호 리소스 테이블에 추가
2. `## Services` 섹션에 메모 추가 (없으면 생성)
3. `/inventory` 실행으로 초기 상태 캡처
4. `/update-docs` 실행으로 추가 내역 기록

---

## 비용이 급증했을 때

```
1. /costs               ← 어떤 리소스 유형이 증가했는지 파악
2. /find-unused         ← 새로 고아가 된 리소스 확인
3. /inventory           ← 이전 스냅샷과 비교해 새로 추가된 리소스 탐색
```

`/inventory` 의 diff가 대부분 원인을 직접 가리킵니다.

---

## 보안 검토

인프라 변경 후에는 항상 보안 검토를 실행하세요:

```
/audit-sg
```

HIGH 발견 사항은 즉시 조치하세요. MEDIUM은 매주 검토하고, LOW/INFO는 정보성 항목으로 월 1회 검토하면 됩니다.

---

## 팀에서 함께 쓰기

여러 명이 같은 AWS 계정을 관리할 때, "무엇을 공유하고(committed) 무엇을 각자 로컬에 두는지"
를 명확히 나눠야 A가 바꾼 설정이 B에게 충돌 없이 전파됩니다.

### 항상 공유 (기본 committed)

킷이 처음부터 커밋하는 파일들 — 그대로 pull/merge 하면 전파됩니다.

- `.claude/commands/*` — 슬래시 커맨드 정의
- `CLAUDE.md.template`, `.claude/settings.json.example` — 템플릿
- `setup.sh`, `docs/`

### 항상 로컬 (절대 커밋 금지)

- `~/.aws/credentials` 의 **실제 액세스 키** (레포 밖에 저장됨 — 어떤 경우에도 커밋 금지)
- `.env` (프로필 이름 등 개인 값), `logs/` (개인 활동 로그)

### 권장: 프로파일 이름 통일 + 직접 커밋

`CLAUDE.md`(보호 리소스·규칙·계정 정보)와 `.claude/settings.json`(권한 허용 목록)은
내용이 팀 전체에 동일합니다. 문제는 이 두 파일에 박히는 **AWS 프로파일 이름**만 사람마다
다르다는 점 — 이것만 통일하면 두 파일을 그대로 공유할 수 있습니다.

1. **팀이 동일한 프로파일 이름을 합의합니다** (예: `team-prod`).
   각 팀원은 `aws configure --profile team-prod` 로 **본인 키만** 로컬에 등록합니다.
   (키는 `~/.aws/credentials` 에만 저장되고 커밋되지 않습니다.)
2. **private 포크에서** `.gitignore` 의 `CLAUDE.md` 와 `.claude/settings.json` 줄을 제거하고
   두 파일을 커밋합니다.
3. 이제 A가 보호 리소스를 추가하거나 권한을 바꾸면, B는 `git pull` 만으로 그대로 반영됩니다.
   `setup.sh` 재실행이나 수동 병합이 필요 없습니다.

> ⚠️ `CLAUDE.md` 에는 계정 ID·VPC·보호 리소스가 들어갑니다. **반드시 private 저장소에서만**
> 커밋하세요. `state/` 이력 공유도 위 "인프라 변경 이력 추적 (opt-in)" 방식으로 함께 쓸 수 있습니다.

---

## Kit 최신 상태 유지

매월 업스트림 개선 사항을 확인하세요:

```bash
git fetch upstream
git log upstream/main --oneline -10   # 변경 사항 미리보기
git merge upstream/main
./setup.sh                            # 템플릿이 변경된 경우 재생성
```
