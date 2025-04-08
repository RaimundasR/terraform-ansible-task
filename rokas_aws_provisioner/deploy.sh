#!/bin/bash

# Navigate to the Terraform directory
cd ./terraform/aws/ || exit

# Check if the instance already exists
if terraform state list | grep -q "aws_instance.web"; then
    echo "Instance already exists. Destroying the existing instance..."
    terraform destroy -auto-approve
else
    echo "No existing instance found. Proceeding with Terraform apply..."
fi

# 1. Terraform apply
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# 2. Generate JSON output
echo "Generating instance_info.json..."
terraform output -json > instance_info.json

# 3. Generate Ansible inventory file
echo "Generating Ansible inventory file..."
PUBLIC_IP=$(jq -r '.public_ip.value' instance_info.json)

cat <<EOF > ../../ansible/inventory/aws.yaml
ec2_instances:
  hosts:
    $PUBLIC_IP:
      ansible_ssh_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/demo-key.pem
EOF

# 4. Wait for the instance to be reachable via SSH
echo "Waiting for the instance to be reachable via SSH..."
TIMEOUT=300  # Set timeout duration in seconds
INTERVAL=10  # Set interval between checks in seconds
ELAPSED=0

while ! ssh -o StrictHostKeyChecking=no -i ~/.ssh/demo-key.pem ubuntu@$PUBLIC_IP "exit" 2>/dev/null; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timeout reached. The instance is not reachable via SSH."
        exit 1
    fi
    echo "Instance not reachable yet. Waiting..."
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

# 5. Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i ../../ansible/inventory/aws.yaml ../../ansible/playbook/microk8s-install.yml

# Check if the Ansible playbook ran successfully
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
else
    echo "Ansible playbook failed. Please check the output for errors."
    exit 1
fi