#!/bin/bash

USAGE="Usage: $0 --action <create|delete> --domain <domain name>"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --action)
            ACTION="$2"
            shift 2
            ;;
        --domain)
            DOMAIN_NAME="$2"
            shift 2
            ;;
        *)
            echo "$USAGE"
            exit 1
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    echo "empty --action | $USAGE"
    exit 1
fi

set -euo pipefail

# Current path
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo 'root dir:"$ROOT_DIR"'


TF_DIR="terraform"
ANSIBLE_DIR="ansible"
INVENTORY="$ANSIBLE_DIR/inventory/aws.auto.yaml"
CONFIG_FILE="$ANSIBLE_DIR/config/infra.config.json"
PLAYBOOKS_DIR="$ANSIBLE_DIR/playbook"
PLAYBOOK_FILE="$PLAYBOOKS_DIR/install_microk8s.yaml"

# Terraform step
cd "$ROOT_DIR/$TF_DIR"
if [[ "$ACTION" == "create" ]]; then
  echo "📦 Running Terraform init & apply..."
  terraform init
  terraform apply -auto-approve
  EXTERNAL_IP=$(terraform output -raw public_ip)
  if [[ -z "$EXTERNAL_IP" ]]; then
    echo "Error: Could not retrieve external IP from terraform output."
    exit 1
  else
    echo "External IP is: $EXTERNAL_IP"
  fi
elif [[ "$ACTION" == "delete" ]]; then
  echo "🔥 Running Terraform destroy..."
  terraform destroy -auto-approve
  exit 0
else
  echo "❌ Unknown action: $ACTION"
  exit 1
fi

echo "Creating Ansible inventory at $INVENTORY..."

echo "Waiting for SSH to become available on $EXTERNAL_IP..."

while ! nc -z "$EXTERNAL_IP" 22; do
  echo "SSH not ready yet. Retrying in 5 seconds..."
  sleep 5
done

echo "SSH is now available."

cat > "$ROOT_DIR/$INVENTORY" <<EOF
microk8s:
  hosts:
    ec2_instance:
      ansible_host: $EXTERNAL_IP
      ansible_user: ubuntu
      ansible_ssh_private_key_file: /home/tenant/terraform/bka-key-pair.pem
EOF

echo "Inventory file created: $ROOT_DIR/$INVENTORY"

# Ansible step
cd "$ROOT_DIR/$PLAYBOOKS_DIR"
echo "🎯 Running Ansible playbook with action: $ACTION"
ansible-playbook -i "$ROOT_DIR/$INVENTORY" "$ROOT_DIR/$PLAYBOOK_FILE" --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" #\
  #--extra-vars "@$CONFIG_FILE" \
  #--extra-vars "operation=$ACTION" \

echo "✅ All done!"



#ideti cia https://github.com/RaimundasR/terraform-ansible-task

#ansible-playbook -i ../inventory/aws.yaml install_microk8s.yaml