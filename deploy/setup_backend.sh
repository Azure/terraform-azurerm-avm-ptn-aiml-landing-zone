#!/bin/bash

# Set variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate$(date +%s)" # Unique name
CONTAINER_NAME="tfstate"
LOCATION="swedencentral"

# Create Resource Group
echo "Creating Resource Group: $RESOURCE_GROUP_NAME..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create Storage Account
echo "Creating Storage Account: $STORAGE_ACCOUNT_NAME..."
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Retrieve Account Key
echo "Retrieving Storage Account Key..."
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create Blob Container
echo "Creating Blob Container: $CONTAINER_NAME..."
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "--------------------------------------------------"
echo "Backend Setup Complete!"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container Name: $CONTAINER_NAME"
echo "--------------------------------------------------"
echo "Run the following command to initialize Terraform:"
echo ""
echo "terraform init \\"
echo "  -backend-config=\"resource_group_name=$RESOURCE_GROUP_NAME\" \\"
echo "  -backend-config=\"storage_account_name=$STORAGE_ACCOUNT_NAME\" \\"
echo "  -backend-config=\"container_name=$CONTAINER_NAME\" \\"
echo "  -backend-config=\"key=terraform.tfstate\""
