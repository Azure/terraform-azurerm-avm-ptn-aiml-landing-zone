# Deployment Instructions

This directory contains the Terraform configuration for deploying the AI Foundry Landing Zone.

## Prerequisites

1.  **Azure Subscription**: You need an active Azure subscription.
2.  **Terraform**: Install Terraform (v1.9+).
3.  **Azure CLI**: Install the Azure CLI.

## Local Deployment

1.  **Navigate to the deploy directory**:
    ```bash
    cd deploy
    ```

2.  **Login to Azure**:
    ```bash
    az login
    ```

3.  **Initialize Terraform**:

    *Option A: Local State (Simple)*
    Edit `main.tf` and comment out the `backend "azurerm" {}` block.
    ```bash
    terraform init
    ```

    *Option B: Remote State (Recommended)*
    Ensure you have a Storage Account created for the state file.
    ```bash
    terraform init \
      -backend-config="resource_group_name=<resource_group_name>" \
      -backend-config="storage_account_name=<storage_account_name>" \
      -backend-config="container_name=<container_name>" \
      -backend-config="key=terraform.tfstate"
    ```

4.  **Plan the Deployment**:
    ```bash
    terraform plan -var="subscription_id=<your_subscription_id>" -out=tfplan
    ```

5.  **Apply the Deployment**:
    ```bash
    terraform apply tfplan
    ```

## GitHub Actions Deployment

The repository includes a GitHub Actions workflow in `.github/workflows/deploy.yml`.

1.  **Configure Federation**: Set up Workload Identity Federation for your GitHub repository to allow it to authenticate with Azure.

2.  **Set GitHub Secrets**:
    Go to your repository settings -> Secrets and variables -> Actions, and add the following secrets:
    *   `AZURE_CLIENT_ID`: The Client ID of your User Assigned Identity or App Registration.
    *   `AZURE_TENANT_ID`: Your Azure Tenant ID.
    *   `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.
    *   `TF_BACKEND_RG`: Resource Group of your State Storage Account.
    *   `TF_BACKEND_SA`: Name of your State Storage Account.
    *   `TF_BACKEND_CONTAINER`: Name of the container in the Storage Account.

3.  **Update Workflow**:
    Uncomment the backend configuration section in `.github/workflows/deploy.yml` to enable remote state management.

4.  **Trigger**:
    Push changes to the `main` branch or manually trigger the workflow from the Actions tab.
