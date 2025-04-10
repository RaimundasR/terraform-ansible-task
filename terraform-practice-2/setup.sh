#!/bin/bash

set -euo pipefail

ACTION=""

# ──────────────────────────────────────────────────────────────
# 📌 1. FLAG HANDLING SECTION — this is where flags are parsed
# Supports: -a | --apply | --create | --creates
#           -d | --delete | --destroy | --deletes
# ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--apply|--create|--creates)
      ACTION="create"
      shift
      ;;
    -d|--delete|--destroy|--deletes)
      ACTION="delete"
      shift
      ;;
    *)
      echo "❌ Unknown flag: $1"
      echo "Usage: $0 [-a|--create] or [-d|--delete]"
      exit 1
      ;;
  esac
done

# 🔒 Validate that action is set
if [[ -z "$ACTION" ]]; then
  echo "❌ No action provided."
  echo "Usage: $0 -a|--create or -d|--delete"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# 📁 2. PATH SETUP
# ──────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$ROOT_DIR/terraform/aws"
ANSIBLE_DIR="$ROOT_DIR/ansible/playbook"
INVENTORY="$ROOT_DIR/inventory.ini"
CONFIG_FILE="$ROOT_DIR/config/infra.config.json"
PLAYBOOK="$ANSIBLE_DIR/playbook.yml"

# ──────────────────────────────────────────────────────────────
# 🧱 3. TERRAFORM LOGIC
# ──────────────────────────────────────────────────────────────
cd "$TF_DIR"
if [[ "$ACTION" == "create" ]]; then
  echo "📦 Running Terraform init & apply..."
  terraform init
  terraform apply -auto-approve
elif [[ "$ACTION" == "delete" ]]; then
  echo "🔥 Running Terraform destroy..."
  terraform destroy -auto-approve
fi

# ──────────────────────────────────────────────────────────────
# 🤖 4. ANSIBLE LOGIC
# ──────────────────────────────────────────────────────────────
cd "$ANSIBLE_DIR"
echo "🎯 Running Ansible playbook with action: $ACTION"
ansible-playbook -i "$INVENTORY" playbook.yml \
  --extra-vars "@$CONFIG_FILE" \
  --extra-vars "operation=$ACTION"

echo "✅ All done!"
echo "📜 Terraform and Ansible actions completed successfully."