#!/usr/bin/env bash
# Delete the sandbox stack and verify no tagged resources remain.
source "$(dirname "$0")/lib.sh"

if "${AWS[@]}" cloudformation describe-stacks --stack-name "$STACK_NAME" &>/dev/null; then
  "${AWS[@]}" cloudformation delete-stack --stack-name "$STACK_NAME"
  echo "Deleting stack $STACK_NAME ..."
  if ! "${AWS[@]}" cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"; then
    echo "✗ Stack deletion failed. Resources created outside the stack (e.g. during experiments)" >&2
    echo "  may be blocking it. Failed resources:" >&2
    "${AWS[@]}" cloudformation describe-stack-events --stack-name "$STACK_NAME" \
      --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
      --output table >&2
    exit 1
  fi
  echo "✓ Stack deleted"
else
  echo "Stack $STACK_NAME does not exist, checking for leftovers only"
fi

# Leftover check: anything tagged Project=iac-sandbox that still bills or blocks.
TAG=(--filters "Name=tag:Project,Values=iac-sandbox")
left_instances="$("${AWS[@]}" ec2 describe-instances "${TAG[@]}" \
  "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId' --output text)"
left_volumes="$("${AWS[@]}" ec2 describe-volumes "${TAG[@]}" --query 'Volumes[].VolumeId' --output text)"
left_sgs="$("${AWS[@]}" ec2 describe-security-groups "${TAG[@]}" --query 'SecurityGroups[].GroupId' --output text)"
left_vpcs="$("${AWS[@]}" ec2 describe-vpcs "${TAG[@]}" --query 'Vpcs[].VpcId' --output text)"

leftovers="$left_instances $left_volumes $left_sgs $left_vpcs"
if [[ -n "${leftovers// /}" ]]; then
  echo "✗ Leftover resources tagged Project=iac-sandbox: $leftovers" >&2
  exit 1
fi
echo "✓ No leftover sandbox resources. Double-check with /find-unused."
