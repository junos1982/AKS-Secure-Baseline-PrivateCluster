# AKS Secure Baseline (Private Cluster) - All-in-One Terraform Scenario

This scenario provisions the infrastructure required for the Azure Kubernetes Service (AKS) secure baseline using a single Terraform configuration. The deployment creates the following resources:

- Azure resource group
- Virtual network and subnet configured for the private AKS cluster
- Private DNS zone linked to the virtual network
- Log Analytics workspace for cluster diagnostics
- User-assigned managed identity with appropriate permissions
- Private AKS cluster with a system and user node pool

## Prerequisites

1. Terraform 1.5 or later.
2. Azure CLI or Azure AD application credentials with permissions to create the above resources.
3. An SSH public key that will be used for Linux nodes in the AKS cluster.

## Usage

```bash
terraform init
terraform plan -var-file="./example.tfvars"
terraform apply -var-file="./example.tfvars"
```

All commands must be executed from this directory so that the local relative paths resolve correctly.

## Required Variables

The configuration expects the variables defined in [`variables.tf`](./variables.tf). See [`example.tfvars`](./example.tfvars) for a sample set of values. When running the workflow in GitHub Actions, provide the variables as `TF_VAR_*` secrets (for example, `TF_VAR_resource_group_name`, `TF_VAR_location`, `TF_VAR_prefix`, etc.). For list values such as `vnet_address_space`, provide a JSON array string (e.g. `["10.240.0.0/16"]`).

## Cleanup

To remove the resources provisioned by this scenario, run:

```bash
terraform destroy -var-file="./example.tfvars"
```
