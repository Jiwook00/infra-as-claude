Estimate the monthly AWS costs for all running resources.

Use the profile and region from your CLAUDE.md context (`$AWS_PROFILE`, `$AWS_REGION`).

## Step 1 — Load resource data

Check `state/` for existing snapshots. If snapshots are missing or older than 1 hour, re-query the relevant resources first.

Resources to consider:
- EC2 instances (type, state, count)
- RDS instances (class, engine, multi-AZ)
- NAT Gateways
- Elastic IPs (unattached ones incur cost)
- EBS volumes (type, size)
- ALBs
- CloudFront distributions

## Step 2 — Estimate monthly cost

Use on-demand pricing for the configured region. Base estimates on:

| Resource | Pricing basis |
|----------|--------------|
| EC2 | instance type × $0.0XX/hr × 730 hrs |
| RDS | instance class × $0.0XX/hr × 730 hrs |
| EBS | volume type × GB × $/GB-month |
| NAT GW | $0.045/hr + $0.045/GB processed |
| Elastic IP | $0.005/hr if unattached |
| ALB | $0.008/hr + LCU cost |
| CloudFront | requests + data transfer (estimate if unknown) |

## Step 3 — Output

Print a cost breakdown table:

| Resource | Detail | Est. Monthly (USD) |
|----------|--------|--------------------|
| EC2 i-xxx | t3.medium · running | $XX.XX |
| RDS xxx | db.t3.medium · postgres | $XX.XX |
| EBS vol-xxx | gp3 20GB | $X.XX |
| NAT GW | 1 gateway | $XX.XX |
| **Total** | | **$XXX.XX** |

If the user passes an argument (e.g. a service name or tag), filter the analysis to only those resources.

Add a note at the bottom: _"Prices are estimates based on on-demand rates. Actual costs may differ due to Reserved Instances, Savings Plans, data transfer, or support fees."_
