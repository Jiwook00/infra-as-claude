# 커맨드 레퍼런스

> 이 파일은 `/update-docs` 에 의해 자동으로 동기화됩니다. 최종 업데이트: _CHANGELOG.md 참고_

---

## /inventory

**파일**: `.claude/commands/inventory.md`

모든 AWS 리소스를 조회하고 상태 스냅샷을 `state/` 에 저장합니다.

이후 실행 시 이전 스냅샷과 비교해 변경 사항을 표시합니다.

**조회 대상**: EC2, ALB, 타겟 그룹, CloudFront, ASG, RDS, Elastic IP, EBS, 보안 그룹, Route 53

**사용법**:
```
/inventory
```

**출력**: 요약 테이블 + `state/` 의 JSON 파일

---

## /costs

**파일**: `.claude/commands/costs.md`

설정된 리전의 온디맨드 가격 기준으로 월간 AWS 비용을 추정합니다.

**사용법**:
```
/costs
/costs my-service    ← 서비스 이름 또는 태그로 필터링
```

**출력**: 리소스별로 그룹화된 비용 분석 테이블

---

## /find-unused

**파일**: `.claude/commands/find-unused.md`

비용을 낭비하거나 불필요한 보안 노출을 만드는 유휴·고아 리소스를 식별합니다.

**검사 항목**: 미연결 EBS, 미연결 EIP, 빈 타겟 그룹, 중지된 EC2, 미사용 보안 그룹, 고아 Lambda ENI, 미사용 시작 템플릿

**사용법**:
```
/find-unused
```

**출력**: 카테고리별로 그룹화된 테이블 + 예상 월간 낭비 비용

---

## /audit-sg

**파일**: `.claude/commands/audit-sg.md`

설정된 VPC의 보안 그룹 감사를 수행합니다.

**검사 항목**: 과도하게 허용된 규칙 (0.0.0.0/0), 미사용 보안 그룹, 보안 그룹 상호 참조 맵

**위험 등급**: HIGH / MEDIUM / LOW / INFO

**사용법**:
```
/audit-sg
```

**출력**: 감사 요약 + 심각도 순으로 정렬된 세부 발견 사항

---

## /plan-removal

**파일**: `.claude/commands/plan-removal.md`

서비스 또는 리소스에 대한 안전한 의존성 순서 삭제 계획을 생성합니다.

공유(보호) 리소스를 자동으로 식별하여 계획에서 제외합니다.

**사용법**:
```
/plan-removal my-service
/plan-removal i-0abc1234
/plan-removal sg-0xyz789
```

**출력**: 순서가 지정된 삭제 테이블 + 보호 리소스 목록 + 삭제 전 체크리스트

---

## /update-docs

**파일**: `.claude/commands/update-docs.md`

최근 활동 로그를 기반으로 문서를 동기화합니다.

**업데이트 대상**:
- `CHANGELOG.md` — 날짜가 포함된 새 항목 추가
- `docs/commands-reference.md` — `.claude/commands/` 의 커맨드 목록 동기화
- `README.md` — 상태 스냅샷이 존재하면 인프라 요약 업데이트

**사용법**:
```
/update-docs
```
