# 권장 패턴

`claude-aws-infra-kit` 을 효과적으로 활용하기 위한 워크플로우와 모범 사례입니다.

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

## 인프라 변경 이력 추적

`state/` 폴더를 git에 커밋하세요. 인프라 이력이 쌓입니다:

```bash
git add state/
git commit -m "infra snapshot: old-service EC2 제거"
```

상태 파일에 `git diff` 를 사용하면 임의의 두 시점 사이에 무엇이 변경됐는지 파악할 수 있습니다.

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

## Kit 최신 상태 유지

매월 업스트림 개선 사항을 확인하세요:

```bash
git fetch upstream
git log upstream/main --oneline -10   # 변경 사항 미리보기
git merge upstream/main
./setup.sh                            # 템플릿이 변경된 경우 재생성
```
