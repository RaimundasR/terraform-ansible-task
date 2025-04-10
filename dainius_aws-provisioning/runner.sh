#!/bin/bash

USAGE="Usage: $0 --action <create|delete> --name <instance name>"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --action)
            ACTION="$2"
            shift 2
            ;;
        --name)
            INSTANCE_NAME="$2" # bka-kubernetes-cluster
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
elif [ "$ACTION" = "create" ]; then
  if [ -z "$INSTANCE_NAME" ]; then
    echo "empty --action | $USAGE"
    exit 1
  else
    echo "perform CREATE"
  fi  
elif [ "$ACTION" = "delete" ]; then
    echo "perform DELETE"
else
    echo "❌ unsupported action: $ACTION"
    exit 1
fi

set -euo pipefail

# Extract value from JSON config
echo "Extract value from JSON config"
function get_config_value() {
  jq -r ".$1" "$CONFIG_FILE"
}
echo "Values from JSON config extracted"

# Current path
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "root dir:$ROOT_DIR"

TF_DIR="terraform"
ANSIBLE_DIR="ansible"
INVENTORY="$ANSIBLE_DIR/inventory/aws.auto.yaml"
CONFIG_FILE="$ROOT_DIR/config/infra.config.json"
PLAYBOOKS_DIR="$ANSIBLE_DIR/playbook"
PLAYBOOK_FILE_MICROK8S="$PLAYBOOKS_DIR/install_microk8s.yaml"
PLAYBOOK_FILE_PODINFO="$PLAYBOOKS_DIR/install_podinfo.yaml"
CLOUDFLARE_API_TOKEN=$(get_config_value i_cloudflare_api_token)
SUBDOMAIN_NAME=$(get_config_value i_subdomain_name)
DOMAIN_ZONE=$(get_config_value i_domain)

if [[ "$ACTION" == "create" ]]; then
  echo "📦 Running Terraform init & apply... EC2 Instance"
  cd "$ROOT_DIR/$TF_DIR/aws"
  terraform init
  terraform apply -auto-approve -var="instance_name=$INSTANCE_NAME"
  EXTERNAL_IP=$(terraform output -raw public_ip)
  if [[ -z "$EXTERNAL_IP" ]]; then
    echo "Error: Could not retrieve external IP from terraform output."
    exit 1
  else
    echo "External IP is: $EXTERNAL_IP"
  fi
  
  echo "📦 Running Terraform init & apply... Cloudflare"
  cd "$ROOT_DIR/$TF_DIR/cloudflare"
  terraform init
  terraform apply -auto-approve -var="ip_address=$EXTERNAL_IP" -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" -var="subdomain_name=$SUBDOMAIN_NAME" -var="zone_name=$DOMAIN_ZONE"
  
elif [[ "$ACTION" == "delete" ]]; then
  echo "🔥 Running Terraform destroy..."
  cd "$ROOT_DIR/$TF_DIR/aws"
  terraform destroy -auto-approve
  cd "$ROOT_DIR/$TF_DIR/cloudflare"
  terraform destroy -auto-approve -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" -var="subdomain_name=$SUBDOMAIN_NAME" -var="zone_name=$DOMAIN_ZONE"
  
  exit 0
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
echo "🎯 Running Ansible playbook with action: $ACTION - $PLAYBOOK_FILE_MICROK8S"
ansible-playbook -i "$ROOT_DIR/$INVENTORY" "$ROOT_DIR/$PLAYBOOK_FILE_MICROK8S" --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -e kube_config_file="$ROOT_DIR/kube_config_remote" #\
  #--extra-vars "@$CONFIG_FILE" \
  #--extra-vars "operation=$ACTION" \

echo "🎯 Running Ansible playbook with action: $ACTION - $PLAYBOOK_FILE_PODINFO"
ansible-playbook -i "$ROOT_DIR/$INVENTORY" "$ROOT_DIR/$PLAYBOOK_FILE_PODINFO" --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -e domain="$SUBDOMAIN_NAME.$DOMAIN_ZONE" #\

echo "✅ All done!"



#ideti cia https://github.com/RaimundasR/terraform-ansible-task

#ansible-playbook -i ../inventory/aws.yaml install_microk8s.yaml