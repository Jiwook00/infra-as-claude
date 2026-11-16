# Shared by up.sh / down.sh. Refuses to run against anything but the sandbox account.
#
# Required:
#   SANDBOX_PROFILE      AWS CLI profile for the sandbox account
#   SANDBOX_ACCOUNT_ID   12-digit sandbox account ID (safety check)
# Optional:
#   SANDBOX_REGION       defaults to the profile's region, then ap-northeast-2
#
# Values can also live in sandbox/.env (gitignored).

set -euo pipefail

SANDBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="iac-sandbox"

[[ -f "$SANDBOX_DIR/.env" ]] && source "$SANDBOX_DIR/.env"

: "${SANDBOX_PROFILE:?SANDBOX_PROFILE is required (see sandbox/README.md)}"
: "${SANDBOX_ACCOUNT_ID:?SANDBOX_ACCOUNT_ID is required (see sandbox/README.md)}"
SANDBOX_REGION="${SANDBOX_REGION:-$(aws configure get region --profile "$SANDBOX_PROFILE" 2>/dev/null || true)}"
SANDBOX_REGION="${SANDBOX_REGION:-ap-northeast-2}"

AWS=(aws --profile "$SANDBOX_PROFILE" --region "$SANDBOX_REGION")

actual_account="$("${AWS[@]}" sts get-caller-identity --query Account --output text)" || {
  echo "✗ Cannot call sts get-caller-identity. Session expired? Try: aws sso login --profile $SANDBOX_PROFILE" >&2
  exit 1
}
if [[ "$actual_account" != "$SANDBOX_ACCOUNT_ID" ]]; then
  echo "✗ Profile '$SANDBOX_PROFILE' points to account $actual_account, expected sandbox $SANDBOX_ACCOUNT_ID. Aborting." >&2
  exit 1
fi
echo "✓ sandbox account $actual_account · $SANDBOX_REGION · stack $STACK_NAME"
