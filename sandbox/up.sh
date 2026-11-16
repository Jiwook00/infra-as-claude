#!/usr/bin/env bash
# Create (or update) the sandbox stack and print resource IDs.
source "$(dirname "$0")/lib.sh"

"${AWS[@]}" cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$SANDBOX_DIR/sandbox.yaml" \
  --tags Project=iac-sandbox \
  --no-fail-on-empty-changeset

echo ""
"${AWS[@]}" cloudformation describe-stacks --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table

echo ""
echo "Billing has started (~\$0.007/h). Run sandbox/down.sh when done."
