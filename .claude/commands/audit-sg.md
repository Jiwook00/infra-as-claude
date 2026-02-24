Perform a security group audit for the configured VPC.

Use the profile and region from your CLAUDE.md context (`$AWS_PROFILE`, `$AWS_REGION`, `$VPC_ID`).

## Step 1 — Fetch all Security Groups in the VPC

```
aws ec2 describe-security-groups --profile $AWS_PROFILE --region $AWS_REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" --output json
```

## Step 2 — Fetch all Network Interfaces (for usage cross-reference)

```
aws ec2 describe-network-interfaces --profile $AWS_PROFILE --region $AWS_REGION --output json
```

## Analysis

### A. Overly permissive inbound rules (0.0.0.0/0 or ::/0)

Extract all inbound rules where source is `0.0.0.0/0` or `::/0`.

| SG ID | SG Name | Port | Protocol | Source | Attached Resource |
|-------|---------|------|----------|--------|------------------|
| sg-xxx | web-sg | 80 | TCP | 0.0.0.0/0 | ALB |

### B. Unused Security Groups

Cross-reference all SG IDs with ENI references.
Flag any SG not associated with any ENI.

Exclude: `default` SG and any SGs listed in CLAUDE.md as protected.

| SG ID | SG Name | Created | Description |
|-------|---------|---------|-------------|
| sg-xxx | old-sg | 2024-01-01 | ... |

### C. SG cross-reference map

Map which SGs reference other SGs in their inbound rules (for dependency awareness):

```
sg-web (sg-aaa)
  ← inbound from: sg-alb (sg-bbb) on port 80,443
  → outbound to:  sg-db  (sg-ccc) on port 5432
```

## Risk Classification

Classify each finding:

- **HIGH**: 0.0.0.0/0 open on SSH (22), RDP (3389), or DB ports (3306, 5432, 27017)
- **MEDIUM**: 0.0.0.0/0 on non-standard ports or wide port ranges (0–65535)
- **LOW**: 0.0.0.0/0 on HTTP (80) / HTTPS (443) only — normal for public ALBs
- **INFO**: Unused SG — no cost, but cleanup recommended

## Output

### Audit Summary

| Severity | Count |
|----------|-------|
| HIGH | N |
| MEDIUM | N |
| LOW | N |
| INFO | N |

### Detailed Findings

List by severity (HIGH first). For each HIGH/MEDIUM finding, include a specific remediation recommendation.
