Find idle or orphaned AWS resources that are wasting money or creating security surface.

Use the profile and region from your CLAUDE.md context (`$AWS_PROFILE`, `$AWS_REGION`, `$VPC_ID`).

## Checks to perform

### 1. Unattached EBS Volumes
```
aws ec2 describe-volumes --profile $AWS_PROFILE --region $AWS_REGION \
  --filters "Name=status,Values=available" --output json
```

### 2. Unassociated Elastic IPs
```
aws ec2 describe-addresses --profile $AWS_PROFILE --region $AWS_REGION --output json
```
→ Filter for entries where `AssociationId` is missing.

### 3. Target Groups with no registered targets
```
aws elbv2 describe-target-groups --profile $AWS_PROFILE --region $AWS_REGION --output json
```
→ For each TG, run `describe-target-health` and flag any with 0 registered targets.

### 4. Unused Security Groups
```
aws ec2 describe-security-groups --profile $AWS_PROFILE --region $AWS_REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" --output json
aws ec2 describe-network-interfaces --profile $AWS_PROFILE --region $AWS_REGION --output json
```
→ Cross-reference: flag SGs not referenced by any ENI. Exclude `default` and any SGs listed in CLAUDE.md as protected.

### 5. Stopped EC2 Instances
```
aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION \
  --filters "Name=instance-state-name,Values=stopped" --output json
```

### 6. Orphaned Lambda ENIs
```
aws ec2 describe-network-interfaces --profile $AWS_PROFILE --region $AWS_REGION \
  --filters "Name=description,Values=AWS Lambda VPC ENI*" --output json
```
→ Flag ENIs whose associated Lambda function no longer exists.

### 7. Unused Launch Templates / Launch Configurations
```
aws ec2 describe-launch-templates --profile $AWS_PROFILE --region $AWS_REGION --output json
aws autoscaling describe-launch-configurations --profile $AWS_PROFILE --region $AWS_REGION --output json
```
→ Flag any not referenced by an Auto Scaling Group.

## Output

Group findings by category with estimated monthly waste:

| Category | Resource ID | Name / Description | Created | Est. Monthly Waste |
|----------|-------------|-------------------|---------|-------------------|
| EBS Volume | vol-xxx | — | 2024-01-01 | $X.XX |
| Elastic IP | eipalloc-xxx | — | — | $X.XX |
| ... | ... | ... | ... | ... |
| **Total potential savings** | | | | **$XX.XX** |

Conclude with a recommendation for the highest-impact items to clean up first.
