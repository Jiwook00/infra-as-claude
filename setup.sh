#!/usr/bin/env bash
# =============================================================================
# infra-as-claude — setup.sh
# Interactively configures your local environment from the kit templates.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}================================================${NC}"
  echo -e "${CYAN}${BOLD}   infra-as-claude  ·  Setup${NC}"
  echo -e "${CYAN}${BOLD}================================================${NC}"
  echo ""
}

print_step() {
  echo -e "\n${BOLD}▶ $1${NC}"
}

print_ok() {
  echo -e "  ${GREEN}✓${NC} $1"
}

print_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "  ${RED}✗${NC} $1"
}

# ── Prerequisites check ──────────────────────────────────────────────────────
print_header

print_step "Checking prerequisites"

if ! command -v aws &>/dev/null; then
  print_error "AWS CLI not found. Install it: https://aws.amazon.com/cli/"
  exit 1
fi
print_ok "AWS CLI found ($(aws --version 2>&1 | head -1))"

if ! command -v python3 &>/dev/null; then
  print_error "python3 not found. Please install Python 3."
  exit 1
fi
print_ok "python3 found"

# ── Collect configuration ────────────────────────────────────────────────────
print_step "AWS Configuration"

# Helper: prompt with an existing value shown as default.
# Sets global PROMPT_RESULT.
prompt_with_default() {
  local label="$1"
  local default="$2"
  local input
  if [[ -n "$default" ]]; then
    read -rp "  $label [${CYAN}${default}${NC}]: " input
    PROMPT_RESULT="${input:-$default}"
  else
    read -rp "  $label: " input
    PROMPT_RESULT="$input"
  fi
}

echo ""
read -rp "  AWS profile name (e.g. mycompany): " AWS_PROFILE

# ── Detect existing values ────────────────────────────────────────────────
EXISTING_REGION=""
EXISTING_ACCOUNT_ID=""
EXISTING_DOMAIN=""
EXISTING_VPC_ID=""
EXISTING_KEY=""

# 1) Pull from .env if it exists
if [[ -f ".env" ]]; then
  EXISTING_REGION=$(grep '^AWS_REGION='     .env 2>/dev/null | cut -d= -f2-)
  EXISTING_ACCOUNT_ID=$(grep '^AWS_ACCOUNT_ID=' .env 2>/dev/null | cut -d= -f2-)
  EXISTING_DOMAIN=$(grep '^MAIN_DOMAIN='    .env 2>/dev/null | cut -d= -f2-)
  EXISTING_VPC_ID=$(grep '^VPC_ID='         .env 2>/dev/null | cut -d= -f2-)
fi

# 2) AWS CLI config takes priority over .env for region / credentials
PROFILE_REGION=$(aws configure get region --profile "$AWS_PROFILE" 2>/dev/null || true)
PROFILE_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE" 2>/dev/null || true)

[[ -n "$PROFILE_REGION" ]] && EXISTING_REGION="$PROFILE_REGION"
[[ -n "$PROFILE_KEY" ]]    && EXISTING_KEY="$PROFILE_KEY"

# Show summary of what was auto-detected
if [[ -n "$EXISTING_REGION" || -n "$EXISTING_KEY" ]]; then
  echo ""
  print_ok "Profile '${AWS_PROFILE}' found — pre-filling detected values (press Enter to keep)"
fi

# ── Per-field prompts ─────────────────────────────────────────────────────
echo ""
prompt_with_default "AWS region        (e.g. eu-central-1)" "$EXISTING_REGION"
AWS_REGION="$PROMPT_RESULT"

prompt_with_default "AWS account ID    (12-digit number)" "$EXISTING_ACCOUNT_ID"
AWS_ACCOUNT_ID="$PROMPT_RESULT"

prompt_with_default "Main domain       (e.g. example.com)" "$EXISTING_DOMAIN"
MAIN_DOMAIN="$PROMPT_RESULT"

prompt_with_default "VPC ID            (e.g. vpc-0abc123)" "$EXISTING_VPC_ID"
VPC_ID="$PROMPT_RESULT"

# ── Credentials ───────────────────────────────────────────────────────────
echo ""
if [[ -n "$EXISTING_KEY" ]]; then
  MASKED_KEY="${EXISTING_KEY:0:4}****${EXISTING_KEY: -4}"
  print_ok "Credentials already set for '${AWS_PROFILE}' (key: ${MASKED_KEY})"
  read -rp "  Reconfigure credentials? [y/N]: " CONFIGURE_CREDS
else
  read -rp "  Do you want to configure AWS credentials now? [y/N]: " CONFIGURE_CREDS
fi

if [[ "$CONFIGURE_CREDS" =~ ^[Yy]$ ]]; then
  echo ""
  read -rp "  AWS Access Key ID: " AWS_ACCESS_KEY_ID
  read -rsp "  AWS Secret Access Key (hidden): " AWS_SECRET_ACCESS_KEY
  echo ""

  aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$AWS_PROFILE"
  aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$AWS_PROFILE"
  aws configure set region "$AWS_REGION" --profile "$AWS_PROFILE"
  print_ok "AWS credentials saved to ~/.aws/credentials (profile: $AWS_PROFILE)"
fi

# ── Validate AWS connection ──────────────────────────────────────────────────
print_step "Validating AWS connection"

if aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" --output json &>/dev/null; then
  CALLER=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" --output json)
  ACTUAL_ACCOUNT=$(echo "$CALLER" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
  print_ok "Connected as account: $ACTUAL_ACCOUNT"

  if [[ "$ACTUAL_ACCOUNT" != "$AWS_ACCOUNT_ID" ]]; then
    print_warn "Account ID mismatch: you entered $AWS_ACCOUNT_ID but connected to $ACTUAL_ACCOUNT"
    read -rp "  Use the connected account ID ($ACTUAL_ACCOUNT)? [Y/n]: " USE_ACTUAL
    if [[ ! "$USE_ACTUAL" =~ ^[Nn]$ ]]; then
      AWS_ACCOUNT_ID="$ACTUAL_ACCOUNT"
    fi
  fi
else
  print_warn "Could not validate AWS connection. Proceeding anyway."
  print_warn "Check your credentials and profile name later."
fi

# ── Generate CLAUDE.md ───────────────────────────────────────────────────────
print_step "Generating CLAUDE.md from template"

python3 - <<PYEOF
import re

with open('CLAUDE.md.template', 'r') as f:
    content = f.read()

replacements = {
    '{{AWS_PROFILE}}':    '${AWS_PROFILE}',
    '{{AWS_REGION}}':     '${AWS_REGION}',
    '{{AWS_ACCOUNT_ID}}': '${AWS_ACCOUNT_ID}',
    '{{MAIN_DOMAIN}}':    '${MAIN_DOMAIN}',
    '{{VPC_ID}}':         '${VPC_ID}',
}

for placeholder, value in replacements.items():
    content = content.replace(placeholder, value)

with open('CLAUDE.md', 'w') as f:
    f.write(content)

print("  Written: CLAUDE.md")
PYEOF

print_ok "CLAUDE.md generated"

# ── Generate .claude/settings.json ──────────────────────────────────────────
print_step "Generating .claude/settings.json"

python3 - <<PYEOF
with open('.claude/settings.json.example', 'r') as f:
    content = f.read()

content = content.replace('{{AWS_PROFILE}}', '${AWS_PROFILE}')

with open('.claude/settings.json', 'w') as f:
    f.write(content)

print("  Written: .claude/settings.json")
PYEOF

print_ok ".claude/settings.json generated"

# ── Create runtime directories ───────────────────────────────────────────────
print_step "Creating runtime directories"

mkdir -p state logs
print_ok "state/  — AWS resource snapshots will be saved here"
print_ok "logs/   — Activity logs will be saved here"

# ── Save .env for reference ──────────────────────────────────────────────────
cat > .env <<ENVEOF
# Generated by setup.sh — DO NOT COMMIT
AWS_PROFILE=${AWS_PROFILE}
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
MAIN_DOMAIN=${MAIN_DOMAIN}
VPC_ID=${VPC_ID}
ENVEOF

print_ok ".env saved (gitignored)"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}================================================${NC}"
echo -e "${GREEN}${BOLD}   Setup complete!${NC}"
echo -e "${GREEN}${BOLD}================================================${NC}"
echo ""
echo -e "  Next steps:"
echo -e "  1. Open this folder in Claude Code:  ${CYAN}claude${NC}"
echo -e "  2. Run your first inventory:          ${CYAN}/inventory${NC}"
echo -e "  3. Check costs:                       ${CYAN}/costs${NC}"
echo ""
echo -e "  📖 Full guide: ${CYAN}docs/setup-guide.md${NC}"
echo ""
