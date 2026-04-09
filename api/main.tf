terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.10.0"
    }
  }
}

# ================= VARIABLES =================

variable "apiName" { type = string }
variable "apiDisplayName" { type = string }
variable "openApiSpecification" { type = string }
variable "policyDocument" { type = string }
variable "serviceName" { type = string }
variable "resource_group_name" { type = string }

variable "apiDescription" {
  type    = string
  default = ""
}

variable "path" {
  type    = string
  default = ""
}

variable "serviceUrl" {
  type    = string
  default = ""
}

variable "subscriptionRequired" {
  type    = bool
  default = true
}

variable "apiRevision" {
  type    = string
  default = "1"
}

variable "subscriptionKeyName" {
  type    = string
  default = "Ocp-Apim-Subscription-Key"
}

variable "enableAPIDeployment" {
  type    = bool
  default = true
}

variable "apiType" {
  type    = string
  default = "http"
}

variable "apiProtocols" {
  type    = list(string)
  default = ["https"]
}

variable "aad_fragment_name" {}
variable "validate_fragment_name" {}
variable "backend_fragment_name" {}
variable "openai_usage_fragment_name" {}

# ================= DATA =================

data "azurerm_api_management" "apimService" {
  name                = var.serviceName
  resource_group_name = var.resource_group_name
}

# ================= LOCALS =================

locals {
  isWebSocketAPI = var.apiType == "websocket" || contains(var.apiProtocols, "ws") || contains(var.apiProtocols, "wss")

  hasSpec   = var.openApiSpecification != "" && var.openApiSpecification != "NA"
  hasPolicy = var.policyDocument != "" && var.policyDocument != "NA"

  isFile = endswith(var.openApiSpecification, ".json") || endswith(var.openApiSpecification, ".yaml") || endswith(var.openApiSpecification, ".yml")
  is_url = can(regex("^https?://", var.openApiSpecification))

  specContent = local.hasSpec ? (
      local.is_url ? var.openApiSpecification : file(var.openApiSpecification)
    ) : null

  # specContent = local.hasSpec ? (
  #   local.isFile ? file(var.openApiSpecification) : var.openApiSpecification
  # ) : null

  isJson = local.hasSpec && (
    startswith(trimspace(local.specContent), "{") ||
    endswith(var.openApiSpecification, ".json")
  )

  contentFormat = local.isJson ? "openapi+json" : "openapi"

  policyContent = local.hasPolicy ? file(var.policyDocument) : null

  apiPath = var.path != "" ? var.path : var.apiName
}

# ================= HTTP API =================

resource "azurerm_api_management_api" "api" {
  count = var.enableAPIDeployment && !local.isWebSocketAPI ? 1 : 0

  name                = var.apiName
  resource_group_name = var.resource_group_name
  api_management_name = var.serviceName

  revision     = var.apiRevision
  display_name = var.apiDisplayName
  path         = local.apiPath
  protocols    = var.apiProtocols

  description           = var.apiDescription
  subscription_required = var.subscriptionRequired

  subscription_key_parameter_names {
    header = var.subscriptionKeyName
    query  = var.subscriptionKeyName
  }

  service_url = var.serviceUrl != "" ? var.serviceUrl : "https://example.com"

  # ✅ OpenAPI import (CRITICAL)
  dynamic "import" {
    for_each = local.hasSpec ? [1] : []
    content {
      content_format = local.contentFormat
      content_value  = local.specContent
    }
  }

  lifecycle {
    ignore_changes = [revision]
  }

  depends_on = [
    data.azurerm_api_management.apimService
  ]
}

# ================= POLICY =================

resource "azurerm_api_management_api_policy" "policy" {
  count = var.enableAPIDeployment && local.hasPolicy && !local.isWebSocketAPI ? 1 : 0

  api_name            = azurerm_api_management_api.api[0].name
  api_management_name = var.serviceName
  resource_group_name = var.resource_group_name
  xml_content = file("${path.root}/policies/openai_api_policy.xml")
  # xml_content = local.policyContent
  
  depends_on = [
    azurerm_api_management_api.api
  ]
}

# ================= WEBSOCKET (KEEP AZAPI) =================

resource "azapi_resource" "api_websocket" {
  count = var.enableAPIDeployment && local.isWebSocketAPI ? 1 : 0

  type      = "Microsoft.ApiManagement/service/apis@2022-08-01"
  name      = var.apiName
  parent_id = data.azurerm_api_management.apimService.id

  body = {
    properties = {
      displayName = var.apiDisplayName
      path        = local.apiPath
      apiRevision = var.apiRevision
      type        = "websocket"
      protocols   = var.apiProtocols

      subscriptionRequired = var.subscriptionRequired

      serviceUrl = var.serviceUrl != "" ? var.serviceUrl : null
    }
  }
}

# ================= OUTPUTS =================

output "id" {
  value = var.enableAPIDeployment ? (
    local.isWebSocketAPI ?
    azapi_resource.api_websocket[0].id :
    azurerm_api_management_api.api[0].id
  ) : null
}

output "api_name" {
  value = var.apiName
}

output "path" {
  value = local.apiPath
}
