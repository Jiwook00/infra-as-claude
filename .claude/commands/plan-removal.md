Create a safe, dependency-ordered removal plan for the specified resource or service.

The user will pass a target as an argument (service name, resource ID, or tag).

Use the profile and region from your CLAUDE.md context (`$AWS_PROFILE`, `$AWS_REGION`).

## Step 1 — Identify target resources

Query all resources associated with the given target (by name, tag, or ID). Group them.

## Step 2 — Dependency analysis

For each resource, map its dependencies:

```
EC2          → Security Group, Subnet, EBS volumes, Target Group, IAM Role
ALB          → Listeners → Target Groups → EC2
CloudFront   → ALB / S3 origin
Route 53     → ALB / CloudFront / EC2
ASG          → Launch Template → AMI → Security Group
Target Group → ALB Listener Rule
```

## Step 3 — Protected resource check

Cross-reference against the **Protected Resources** table in CLAUDE.md.

- **Protected**: Exclude from deletion. Show a warning.
- **Dedicated**: Safe to delete. Sort by dependency order.

## Step 4 — Generate removal plan

Enter plan mode and output the following:

---

## Removal Plan: [target name]

### Resources to delete (in order)

| # | Type | Resource ID | Name | Notes |
|---|------|-------------|------|-------|
| 1 | Route 53 Record | — | service.example.com | Delete DNS first |
| 2 | CloudFront | dist-xxx | — | Wait for deployment |
| 3 | ALB Listener Rule | — | — | Remove rule only, keep ALB |
| 4 | Target Group | tg-xxx | service-tg | Deregister targets first |
| 5 | ASG | asg-xxx | service-asg | Set desired=0, then delete |
| 6 | EC2 | i-xxx | service-server | Terminate after ASG |
| 7 | Security Group | sg-xxx | service-sg | Delete last |
| 8 | EBS Volume | vol-xxx | — | Snapshot first? |

### Protected resources (preserved)

| Type | Resource ID | Reason |
|------|-------------|--------|
| ALB | alb-xxx | Shared with other services |
| ... | ... | ... |

### Pre-removal checklist

- [ ] Confirm zero active traffic (check CloudWatch metrics)
- [ ] Verify DNS TTL has propagated before removing records
- [ ] Snapshot any EBS volumes with data worth preserving
- [ ] Notify team / update runbook

### Estimated savings after removal

~$XX.XX/month

---

**Do not proceed to execution without explicit user approval.**
