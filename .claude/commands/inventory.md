Query all AWS resources and save a state snapshot to the `state/` folder.

## Resources to query

Use the profile and region from your CLAUDE.md context (`$AWS_PROFILE`, `$AWS_REGION`) for all commands below.

Run each query and save the result to the corresponding file in `state/`:

1. **EC2 Instances** → `state/ec2.json`
   ```
   aws ec2 describe-instances --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

2. **ALB (Application Load Balancers)** → `state/alb.json`
   ```
   aws elbv2 describe-load-balancers --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

3. **Target Groups** → `state/target-groups.json`
   ```
   aws elbv2 describe-target-groups --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

4. **CloudFront Distributions** → `state/cloudfront.json`
   ```
   aws cloudfront list-distributions --profile $AWS_PROFILE --output json
   ```

5. **Auto Scaling Groups** → `state/asg.json`
   ```
   aws autoscaling describe-auto-scaling-groups --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

6. **RDS Instances** → `state/rds.json`
   ```
   aws rds describe-db-instances --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

7. **Elastic IPs** → `state/eip.json`
   ```
   aws ec2 describe-addresses --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

8. **EBS Volumes** → `state/ebs.json`
   ```
   aws ec2 describe-volumes --profile $AWS_PROFILE --region $AWS_REGION --output json
   ```

9. **Security Groups (VPC-scoped)** → `state/security-groups.json`
   ```
   aws ec2 describe-security-groups --profile $AWS_PROFILE --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" --output json
   ```

10. **Route 53 Hosted Zones** → `state/route53.json`
    ```
    aws route53 list-hosted-zones --profile $AWS_PROFILE --output json
    ```

## Output

1. Save each result to `state/<resource>.json` (overwrite — keep only the latest snapshot)
2. If a previous snapshot exists, show a diff summary of what changed
3. Print a summary table:

| Resource Type | Count | Changes |
|--------------|-------|---------|
| EC2          | N     | +1 / -0 |
| ALB          | N     | no change |
| ...          | ...   | ...     |
