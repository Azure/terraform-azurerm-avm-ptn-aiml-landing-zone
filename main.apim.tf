

module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.5"
  count   = var.apim_definition.deploy ? 1 : 0

  location                   = azurerm_resource_group.this.location
  name                       = local.apim_name
  publisher_email            = var.apim_definition.publisher_email
  resource_group_name        = azurerm_resource_group.this.name
  additional_location        = var.apim_definition.additional_locations
  certificate                = var.apim_definition.certificate
  client_certificate_enabled = var.apim_definition.client_certificate_enabled
  diagnostic_settings        = local.apim_diagnostic_settings
  enable_telemetry           = var.enable_telemetry
  hostname_configuration     = var.apim_definition.hostname_configuration
  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.mi.id
    ]
  }
  # managed_identities         = var.apim_definition.managed_identities
  min_api_version            = var.apim_definition.min_api_version
  notification_sender_email  = var.apim_definition.notification_sender_email
  private_endpoints = {
    endpoint1 = {
      private_dns_zone_resource_ids = var.private_dns_zones.azure_policy_pe_zone_linking_enabled ? null : (var.flag_platform_landing_zone ? [module.private_dns_zones.apim_zone.resource_id] : [local.private_dns_zones_existing.apim_zone.resource_id])
      subnet_resource_id            = local.subnet_ids["PrivateEndpointSubnet"]
    }
  }
  protocols                     = var.apim_definition.protocols
  public_network_access_enabled = true
  publisher_name                = var.apim_definition.publisher_name
  role_assignments              = local.apim_role_assignments
  sign_in                       = var.apim_definition.sign_in
  sign_up                       = var.apim_definition.sign_up
  sku_name                      = "${var.apim_definition.sku_root}_${var.apim_definition.sku_capacity}"
  tags                          = var.apim_definition.tags
  tenant_access                 = var.apim_definition.tenant_access
  virtual_network_subnet_id     = null
  virtual_network_type          = "None"
  # zones                         = local.region_zones
  zones = startswith(local.apim_sku_name, "Premium_") || startswith(local.apim_sku_name, "PremiumV2_") ? local.region_zones : []
}

data "azurerm_api_management" "check" {
  name                = module.apim[0].name
  resource_group_name = azurerm_resource_group.this.name

  depends_on = [null_resource.wait_for_apim_ready]
}

############################################
# LOCALS (Bicep 'var')
############################################
# data "azurerm_resource_group" "this" {
#   name = azurerm_resource_group.this.name
# }

locals {
  # resourceGroup().location fallback
  location_final = var.location != null ? var.location : azurerm_resource_group.this.location

  # tenant().tenantId
  tenant_id_final = var.tenantId != null ? var.tenantId : data.azurerm_client_config.current.tenant_id

  # subscription().subscriptionId
  subscription_id_final = var.dnsSubscriptionId != null ? var.dnsSubscriptionId : data.azurerm_client_config.current.subscription_id

  # sku check
  isV2SKU = var.sku == "StandardV2" || var.sku == "PremiumV2"

  # public network access mapping
  apimPublicNetworkAccess = var.apimV2PublicNetworkAccess ? "Enabled" : "Disabled"

  # static named values
  openAiApiBackendId        = "openai-backend"
  openAiApiUamiNamedValue   = "uami-client-id"
  openAiApiEntraNamedValue  = "entra-auth"
  openAiApiClientNamedValue = "client-id"
  openAiApiTenantNamedValue = "tenant-id"
  openAiApiAudienceNamedValue = "audience"

  # API versions
  apiManagementMinApiVersion    = "2021-08-01"
  apiManagementMinApiVersionV2  = "2024-05-01"

  # zones logic (exact match)
  apimZones = (
    var.sku == "Premium" && var.skuCount > 1
    ? (var.skuCount == 2 ? ["1", "2"] : ["1", "2", "3"])
    : []
  )
}

############################################
# EXISTING APIM SERVICE
############################################

# resource "azurerm_api_management_api" "api_import" {
#   name                = "petstore-api"
#   resource_group_name = azurerm_resource_group.this.name
#   api_management_name = module.apim[0].name

#   revision     = "1"
#   display_name = "Petstore API"
#   path         = "petstore"
#   protocols    = ["https"]

#   depends_on = [module.apim]
# }

resource "azapi_resource" "applicationInsights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = var.applicationInsightsName
  location  = var.location

  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}"

  body = {
    kind = "web"
    properties = {
      Application_Type = "web"
    }
  }
}

data "azurerm_cognitive_account" "openai" {
  name                = var.openai_resource_name
  resource_group_name = azurerm_resource_group.this.name

    depends_on = [
      module.apim,
      null_resource.wait_for_apim_ready
    ]
}

resource "azurerm_role_assignment" "openai_access" {
  scope                = data.azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
  
  depends_on = [
      module.apim,
      null_resource.wait_for_apim_ready
    ]
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = var.managedIdentityName
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
}

# resource "azapi_resource" "managedIdentity" {
#   type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30"
#   name      = var.managedIdentityName
#   location  = var.location

#   parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.this.name}"

#   body = {}
# }

resource "azurerm_eventhub_namespace" "eh_ns" {
  name                = var.namespace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

# resource "azurerm_eventhub_namespace" "eh_ns" {
#   name                = var.namespace_name
#   location            = var.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku                 = "Standard"
# depends_on = [
#   azurerm_resource_group.this
# ]
# }

resource "azapi_resource" "eventHub" {
  type      = "Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview"
  name      = var.eventHubName
  parent_id = azurerm_eventhub_namespace.eh_ns.id
}

resource "azapi_resource" "eventHubPII" {
  type      = "Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview"
  name      = var.eventHubPIIName
  parent_id = azurerm_eventhub_namespace.eh_ns.id

}

resource "azurerm_eventhub_namespace_authorization_rule" "apim_logger" {
  name                = "apim-logger-policy"
  namespace_name      = azurerm_eventhub_namespace.eh_ns.name
  resource_group_name = azurerm_resource_group.this.name

  listen = false
  send   = true
  manage = false
}

resource "null_resource" "wait_for_apim_ready" {

  depends_on = [module.apim]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for APIM to be ready..."

      for i in {1..60}; do
        state=$(az apim show \
          --name ${local.apim_name} \
          --resource-group ${var.resource_group_name} \
          --query "provisioningState" -o tsv)

        echo "Current state: $state"

        if [ "$state" = "Succeeded" ]; then
          echo "APIM is ready"
          exit 0
        fi

        sleep 30
      done

      echo "Timeout waiting for APIM"
      exit 1
    EOT
  }
}

module "apimOpenaiApi" {
  source = "./api"

  resource_group_name   = azurerm_resource_group.this.name
  serviceName          = module.apim[0].name
  apiName               = "azure-openai-service-api"
  path                  = "openai"
  apiRevision           = "1"
  apiDisplayName        = "Azure OpenAI API"               # Fixed
  subscriptionRequired  = var.entraAuth ? false : true
  subscriptionKeyName   = "api-key"
  apiDescription        = "Azure OpenAI API"
  
  openApiSpecification = "${path.root}/openai-api/oai-api-spec-2024-10-21.yaml"
  policyDocument       = "${path.root}/policies/openai_api_policy.xml"

  enableAPIDeployment   = true
  serviceUrl            = "https://${var.openai_resource_name}.openai.azure.com"
  apiType               = "http"
  apiProtocols          = ["https"]

  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}


module "test_api" {
  source              = "./api"
  resource_group_name = azurerm_resource_group.this.name
  count               = var.enableAzureAISearch ? 1 : 0
  apiDisplayName      = "Test API"

  serviceName          = module.apim[0].name
  apiName              = "debug test api"
  path                 = "debug"
  apiRevision          = "1"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "api-key"
  openApiSpecification = "https://petstore3.swagger.io/api/v3/openapi.json"
  apiDescription       = "Azure AI Search Index Client APIs"
  policyDocument       = ""
  enableAPIDeployment  = true
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}


module "apimAiSearchIndexApi" {
  source              = "./api"
  resource_group_name = azurerm_resource_group.this.name
  count               = var.enableAzureAISearch ? 1 : 0
  apiDisplayName      = "Azure AI Search Index API"   # also fixed this - was wrongly set to "Azure OpenAI API"

  serviceName          = module.apim[0].name
  apiName              = "azure-ai-search-index-api"
  path                 = "search"
  apiRevision          = "1"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "api-key"
  openApiSpecification = "${path.root}/ai-search-api/ai-search-index-2024-07-01-api-spec.json"
  apiDescription       = "Azure AI Search Index Client APIs"
  policyDocument       = "${path.root}/policies/ai-search-index-api-policy.xml"                 # path only
  enableAPIDeployment  = true
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}

module "apimAiModelInferenceApi" {
  source              = "./api"
  resource_group_name = azurerm_resource_group.this.name
  count               = var.enableAIModelInference ? 1 : 0

  serviceName          = module.apim[0].name
  apiName              = "ai-model-inference-api"
  path                 = "models"
  apiRevision          = "1"
  apiDisplayName       = "AI Model Inference API"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "api-key"
  openApiSpecification = "${path.root}/ai-model-inference/ai-model-inference-api-spec.yaml" # path only
  apiDescription       = "Access to AI inference models published through Azure AI Foundry"
  policyDocument       = "${path.root}/policies/ai-model-inference-api-policy.xml"           # path only
  enableAPIDeployment  = true
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}

module "apimOpenAIRealTimetApi" {

  source = "./api"

  count = var.enableOpenAIRealtime ? 1 : 0
  resource_group_name = azurerm_resource_group.this.name
  serviceName          = module.apim[0].name
  apiName              = "openai-realtime-ws-api"
  path                 = "openai/realtime"
  apiRevision          = "1"
  apiDisplayName       = "Azure OpenAI Realtime API"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "api-key"

  openApiSpecification = "NA"

  apiDescription      = "Access Azure OpenAI Realtime API for real-time voice and text conversion."
  policyDocument      = "${path.root}/policies/openai-realtime-policy.xml"
  enableAPIDeployment = true

  serviceUrl  = "wss://to-be-replaced-by-policy"
  apiType     = "websocket"
  apiProtocols = ["wss"]
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}

module "apimDocumentIntelligenceLegacy" {

  source = "./api"

  count = var.enableDocumentIntelligence ? 1 : 0
  resource_group_name = azurerm_resource_group.this.name
  serviceName          = module.apim[0].name
  apiName              = "document-intelligence-api-legacy"
  path                 = "formrecognizer"
  apiRevision          = "1"
  apiDisplayName       = "Document Intelligence API (Legacy)"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "Ocp-Apim-Subscription-Key"

  openApiSpecification = "${path.root}/doc-intel-api/document-intelligence-2024-11-30-compressed.openapi.yaml"

  apiDescription      = "Uses (/formrecognizer) url path. Extracts content, layout, and structured data from documents."
  policyDocument      = "${path.root}/policies/doc-intelligence-api-policy.xml"
  enableAPIDeployment = true
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}

module "apimDocumentIntelligence" {

  source = "./api"

  count = var.enableDocumentIntelligence ? 1 : 0
  resource_group_name = azurerm_resource_group.this.name
  serviceName          = module.apim[0].name
  apiName              = "document-intelligence-api"
  path                 = "documentintelligence"
  apiRevision          = "1"
  apiDisplayName       = "Document Intelligence API"
  subscriptionRequired = var.entraAuth ? false : true
  subscriptionKeyName  = "Ocp-Apim-Subscription-Key"

  openApiSpecification = "${path.root}/doc-intel-api/document-intelligence-2024-11-30-compressed.openapi.yaml"

  apiDescription      = "Uses (/documentintelligence) url path. Extracts content, layout, and structured data from documents."
  policyDocument      = "${path.root}/policies/doc-intelligence-api-policy.xml"
  enableAPIDeployment = true
  aad_fragment_name          = azapi_resource.aadAuthPolicyFragment.name
  validate_fragment_name     = azapi_resource.validateRoutesPolicyFragment.name
  backend_fragment_name      = azapi_resource.backendRoutingPolicyFragment.name
  openai_usage_fragment_name = azapi_resource.openAIUsagePolicyFragment.name

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azurerm_user_assigned_identity.mi
  ]
}

resource "azapi_resource" "retailProduct" {
  type      = "Microsoft.ApiManagement/service/products@2022-08-01"
  name      = "oai-retail-assistant"

  parent_id = local.apim_id

  # "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ApiManagement/service/${module.apim[0].name}"

  body = {
    properties = {
      displayName          = "OAI-Retail-Assistant"
      description          = "Offering OpenAI services for the retail and e-commerce platforms assistant."
      subscriptionRequired = true
      approvalRequired     = true
      subscriptionsLimit   = 200
      state                = "published"
      terms                = "By subscribing to this product, you agree to the terms and conditions."
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}


resource "azapi_resource" "retailProductOpenAIApi" {

  type      = "Microsoft.ApiManagement/service/products/apiLinks@2023-05-01-preview"
  name      = "retail-product-openai-api"
  parent_id = azapi_resource.retailProduct.id

  body = {
    properties = {
      apiId = module.apimOpenaiApi.id
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    module.apimOpenaiApi
  ]
}

resource "azapi_resource" "retailProductPolicy" {

  type      = "Microsoft.ApiManagement/service/products/policies@2022-08-01"
  name      = "policy"
  parent_id = azapi_resource.retailProduct.id

  body = {
    properties = {
      value  = file("${path.root}/policies/retail_product_policy.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    module.apimOpenaiApi,
    azapi_resource.retailProductOpenAIApi,
    null_resource.wait_for_apim_ready
  ]
}

locals {
  apim_id = length(module.apim) > 0 ? format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.ApiManagement/service/%s",
    data.azurerm_client_config.current.subscription_id,
    azurerm_resource_group.this.name,
    module.apim[0].name
  ) : ""
}

resource "azapi_resource" "hrProduct" {
  type      = "Microsoft.ApiManagement/service/products@2022-08-01"
  name      = "oai-hr-assistant"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName          = "OAI-HR-Assistant"
      description          = "Offering OpenAI services for the internal HR platforms."
      subscriptionRequired = true
      approvalRequired     = true
      subscriptionsLimit   = 200
      state                = "published"
      terms                = "By subscribing to this product, you agree to the terms and conditions."
    }
  }

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

resource "azapi_resource" "retailSubscription" {
  type      = "Microsoft.ApiManagement/service/subscriptions@2022-08-01"
  name      = "oai-retail-assistant-sub-01"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "AI-Retail-Internal-Subscription"
      state       = "active"
      scope = "/products/${azapi_resource.retailProduct.name}"
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.retailProduct,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "hrProductOpenAIApi" {

  type      = "Microsoft.ApiManagement/service/products/apiLinks@2023-05-01-preview"
  name      = "hr-product-openai-api"
  parent_id = azapi_resource.hrProduct.id

  body = {
    properties = {
      apiId = module.apimOpenaiApi.id
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    module.apimOpenaiApi
  ]
}

resource "azapi_resource" "hrProductPolicy" {

  type      = "Microsoft.ApiManagement/service/products/policies@2022-08-01"
  name      = "policy"
  parent_id = azapi_resource.hrProduct.id

  body = {
    properties = {
      value  = file("${path.root}/policies/hr_product_policy.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    module.apimOpenaiApi,
    azapi_resource.hrProductOpenAIApi,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "hrSubscription" {
  type      = "Microsoft.ApiManagement/service/subscriptions@2022-08-01"
  name      = "oai-hr-assistant-sub-01"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "OAI-HR-Assistant-Sub-01"
      state       = "active"
      scope = "/products/${azapi_resource.hrProduct.name}"
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.hrProduct
  ]
}

resource "azapi_resource" "hrPIIProduct" {
  type      = "Microsoft.ApiManagement/service/products@2022-08-01"
  name      = "oai-hr-pii-assistant"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName          = "OAI-HR-PII-Assistant"
      description          = "Offering OpenAI services for the internal HR platforms with PII anonymization processing."
      subscriptionRequired = true
      approvalRequired     = true
      subscriptionsLimit   = 200
      state                = "published"
      terms                = "By subscribing to this product, you agree to the terms and conditions."
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.contentSafetyBackend
  ]
}

resource "azapi_resource" "hrPIIProductOpenAIApi" {

  type      = "Microsoft.ApiManagement/service/products/apiLinks@2023-05-01-preview"
  name      = "hr-pii-product-openai-api"
  parent_id = azapi_resource.hrPIIProduct.id

  body = {
    properties = {
      apiId = module.apimOpenaiApi.id
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "hrPIIProductPolicy" {

  type      = "Microsoft.ApiManagement/service/products/policies@2022-08-01"
  name      = "policy"
  parent_id = azapi_resource.hrPIIProduct.id

  body = {
    properties = {
      value  = file("${path.root}/policies/hr_pii_product_policy.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    module.apimOpenaiApi
  ]
}

resource "azapi_resource" "searchHRProduct" {

  count = var.enableAzureAISearch ? 1 : 0

  type      = "Microsoft.ApiManagement/service/products@2022-08-01"
  name      = "src-hr-assistant"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName          = "SRC-HR-Assistant"
      description          = "Offering AI Search services for the HR systems."
      subscriptionRequired = true
      approvalRequired     = true
      subscriptionsLimit   = 200
      state                = "published"
      terms                = "By subscribing to this product, you agree to the terms and conditions."
    }
  }

  depends_on = [
      module.apim,
      null_resource.wait_for_apim_ready
    ]
  }


resource "azapi_resource" "searchHRProductAISearchApi" {

  count = var.enableAzureAISearch ? 1 : 0

  type      = "Microsoft.ApiManagement/service/products/apiLinks@2023-05-01-preview"
  name      = "src-hr-product-ai-search-api"
  parent_id = azapi_resource.searchHRProduct[0].id

  body = {
    properties = {
      apiId = module.apimAiSearchIndexApi[0].id
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "searchHRProductPolicy" {

  count = var.enableAzureAISearch ? 1 : 0

  type      = "Microsoft.ApiManagement/service/products/policies@2022-08-01"
  name      = "policy"
  parent_id = azapi_resource.searchHRProduct[0].id

  body = {
    properties = {
      value  = file("${path.root}/policies/search_hr_product_policy.xml")
      format = "rawxml"
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready,
    azapi_resource.searchHRProductAISearchApi
  ]
}

resource "azapi_resource" "searchHRSubscription" {

  count = var.enableAzureAISearch ? 1 : 0

  type      = "Microsoft.ApiManagement/service/subscriptions@2022-08-01"
  name      = "src-hr-assistant-sub-01"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "SRC-HR-Assistant-Sub-01"
      state       = "active"
      scope       = length(azapi_resource.searchHRProduct) > 0 ? azapi_resource.searchHRProduct[0].id : null
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.searchHRProduct,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "openAiBackends" {

  for_each = {
    for uri in var.openAiUris :
    uri => uri
  }

  type      = "Microsoft.ApiManagement/service/backends@2022-08-01"
  name      = "${local.openAiApiBackendId}-${replace(each.key, "https://", "")}"
  parent_id = local.apim_id

  body = {
    properties = {
      description = local.openAiApiBackendId
      url         = each.value
      protocol    = "https"

      # No credentials block needed

      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }

depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "aiSearchBackends" {

  for_each = var.enableAzureAISearch ? {
    for idx, instance in var.aiSearchInstances :
    idx => instance
  } : {}

  type      = "Microsoft.ApiManagement/service/backends@2022-08-01"
  name      = each.value.name
  parent_id = local.apim_id

  body = {
    properties = {
      description = each.value.description
      url         = each.value.url
      protocol    = "http"
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }

depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

data "azurerm_client_config" "current" {}

locals {
  apim_service_id = length(module.apim) > 0 ? format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.ApiManagement/service/%s",
    data.azurerm_client_config.current.subscription_id,
    azurerm_resource_group.this.name,
    local.apim_name
  ) : null
}

resource "azapi_resource" "contentSafetyBackend" {
  count = var.contentSafetyServiceUrl != "" && length(module.apim) > 0 ? 1 : 0

  type      = "Microsoft.ApiManagement/service/backends@2022-08-01"
  name      = "content-safety-backend"
  parent_id = local.apim_service_id   # also fix this (see below)

  body = {
    properties = {
      description = "Content Safety Service Backend"
      url         = var.contentSafetyServiceUrl
      protocol    = "http"
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}


############################################
# OpenAI UAMI Client ID (Secret)
############################################
resource "azapi_resource" "apimOpenaiApiUamiNamedValue" {

  count = var.openAiApiUamiNamedValue != "" ? 1 : 0

  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = var.openAiApiUamiNamedValue
  parent_id = local.apim_service_id

  body = {
    properties = {
      displayName = var.openAiApiUamiNamedValue
      secret      = true
      value = azurerm_user_assigned_identity.mi.client_id
      # value       = azapi_resource.managedIdentity.output.properties.clientId
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

locals {
  entra_name = var.openAiApiEntraNamedValue
}

resource "azapi_resource" "apiopenAiApiEntraNamedValue" {

  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = local.entra_name
  parent_id = local.apim_service_id
  body = {
    properties = {
      displayName = local.entra_name
      secret      = false
      value       = tostring(var.entraAuthUrl) # bool -> "true"/"false"
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

############################################
# Client App ID (Secret)
############################################
locals {
  client_name = var.openAiApiClientNamedValue != "" ? var.openAiApiClientNamedValue : "client-id"
}

resource "azapi_resource" "apiopenAiApiClientNamedValue" {
  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = "client-id"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "client-id"
      value       = var.clientAppId   # MUST NOT be empty
      secret      = true
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

############################################
# Tenant ID (Secret)
############################################
locals {
  tenant_name = var.openAiApiTenantNamedValue != "" ? var.openAiApiTenantNamedValue : "tenant-id"
}

resource "azapi_resource" "apiopenAiApiTenantNamedValue" {

  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = local.tenant_name
  parent_id = local.apim_service_id

  body = {
    properties = {
      displayName = local.tenant_name   # FIX
      secret      = true
      value       = var.tenantId
    }
  }
  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

############################################
# Audience (Secret)
############################################
locals {
  audience_name = var.openAiApiAudienceNamedValue != "" ? var.openAiApiAudienceNamedValue : "audience"
}

resource "azapi_resource" "apimOpenaiApiAudienceNamedValue" {

  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = local.audience_name
  parent_id = local.apim_service_id   # FIX

  body = {
    properties = {
      displayName = local.audience_name   # FIX
      secret      = true
      value       = var.audience
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

############################################
# PII Service URL (Non-secret)
############################################

resource "azapi_resource" "piiServiceUrlNamedValue" {
  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = "piiServiceUrl"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName = "piiServiceUrl"
      value       = var.aiLanguageServiceUrl
      secret      = false
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

############################################
# PII Service Key (Secret - Placeholder)
############################################
resource "azapi_resource" "piiServiceKeyNamedValue" {

  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = "piiServiceKey"
  parent_id = local.apim_service_id

  body = {
    properties = {
      displayName = "piiServiceKey"
      secret      = true
      value       = "replace-with-language-service-key-if-needed"
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

############################################
# Content Safety Service URL (Non-secret)
############################################
# Tenant ID
resource "azapi_resource" "tenantIdNamedValue" {
  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = "tenant-id"
  parent_id = local.apim_service_id

  body = {
    properties = {
      displayName = "tenant-id"
      value       = var.tenantId
      secret      = false
    }
  }

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

# Content Safety URL
resource "azapi_resource" "contentSafetyServiceUrlNamedValue" {
  type      = "Microsoft.ApiManagement/service/namedValues@2022-08-01"
  name      = "contentSafetyServiceUrl"
  parent_id = local.apim_service_id

  body = {
    properties = {
      displayName = "contentSafetyServiceUrl"
      value       = var.contentSafetyServiceUrl
      secret      = false
    }
  }

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "aadAuthPolicyFragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "aad-auth"
  parent_id = local.apim_service_id

  body = {
    properties = {
      format = "rawxml"
      value  = <<-XML
<fragment>
  <choose>

    <when condition="@(context.Request.Headers.ContainsKey("Authorization"))">
      <validate-jwt header-name="Authorization"
                    failed-validation-httpcode="401"
                    failed-validation-error-message="Unauthorized">

        <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />

        <issuers>
          <issuer>https://sts.windows.net/{{tenant-id}}/</issuer>
        </issuers>

        <required-claims>
          <claim name="aud">
            <value>{{audience}}</value>
          </claim>
        </required-claims>

      </validate-jwt>

    </when>

    <otherwise>
      <return-response>
        <set-status code="401" reason="Unauthorized" />
        <set-body>@("Authorization header missing or invalid")</set-body>
      </return-response>
    </otherwise>

  </choose>
</fragment>
XML
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.tenantIdNamedValue,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "validateRoutesPolicyFragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "validate-routes"
  parent_id = local.apim_service_id

  body = {
    properties = {
      value  = file("${path.root}/policies/frag-validate-routes.xml")
      format = "rawxml"
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

resource "azapi_resource" "backendRoutingPolicyFragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "backend-routing"
  parent_id = local.apim_service_id

  body = {
    properties = {
      value  = file("${path.root}/policies/frag-backend-routing.xml")
      format = "rawxml"
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}

resource "azapi_resource" "openAIUsagePolicyFragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "openai-usage"
  parent_id = local.apim_id

  body = {
    properties = {
      value  = file("${path.root}/policies/frag-openai-usage.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.ehUsageLogger,
    null_resource.wait_for_apim_ready
  ]

}

resource "azapi_resource" "aiUsagePolicyFragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "ai-usage"
  parent_id = local.apim_id

  body = {
    properties = {
      value  = file("${path.root}/policies/frag-ai-usage.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.ehUsageLogger,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "piiStateSavingPolicyFragment" {

  count = var.enablePIIAnonymization ? 1 : 0

  type      = "Microsoft.ApiManagement/service/policyFragments@2022-08-01"
  name      = "pii-state-saving"
  parent_id = local.apim_id

  body = {
    properties = {
      value  = file("${path.root}/policies/frag-pii-state-saving.xml")
      format = "rawxml"
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.ehPIIUsageLogger,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "apimLogger" {

  type      = "Microsoft.ApiManagement/service/loggers@2022-08-01"
  name      = "appinsights-logger"
  parent_id = local.apim_id

  body = {
    properties = {
      credentials = {
        instrumentationKey = azapi_resource.applicationInsights.output.properties.InstrumentationKey
      }
      description = "Application Insights logger for API observability"
      isBuffered  = false
      loggerType  = "applicationInsights"
      resourceId  = azapi_resource.applicationInsights.id
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.applicationInsights,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "ehUsageLogger" {

  type      = "Microsoft.ApiManagement/service/loggers@2022-08-01"
  name      = "usage-eventhub-logger"
  parent_id = local.apim_id

  body = {
    properties = {
      loggerType  = "azureEventHub"
      description = "Event Hub logger for OpenAI usage metrics"

      credentials = {
        name = var.eventHubName

        connectionString = "${azurerm_eventhub_namespace_authorization_rule.apim_logger.primary_connection_string};EntityPath=${var.eventHubName}"
      }
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.eventHub,
    azurerm_eventhub_namespace_authorization_rule.apim_logger,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "ehPIIUsageLogger" {

  count = var.enablePIIAnonymization ? 1 : 0

  type      = "Microsoft.ApiManagement/service/loggers@2022-08-01"
  name      = "pii-usage-eventhub-logger"
  parent_id = local.apim_id

  body = {
    properties = {
      loggerType  = "azureEventHub"
      description = "Event Hub logger for PII usage metrics and logs"
      credentials = {
        connectionString = "${azurerm_eventhub_namespace_authorization_rule.apim_logger.primary_connection_string};EntityPath=${var.eventHubPIIName}"
      }
      # credentials = {
      #   name             = azapi_resource.eventHubPII.name
      #   endpointAddress  = replace(var.eventHubPIIEndpoint, "https://", "")
      #   # identityClientId = azapi_resource.managedIdentity.output.properties.clientId
      #   identityClientId = azurerm_user_assigned_identity.mi.client_id
      # }
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.eventHubPII,
    azurerm_user_assigned_identity.mi,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "apimAppInsights" {

  type      = "Microsoft.ApiManagement/service/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = local.apim_id

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "W3C"
      verbosity               = "information"
      logClientIp             = true
      loggerId                = azapi_resource.apimLogger.id
      metrics                 = true

      sampling = {
        samplingType = "fixed"
        percentage   = 25
      }

      frontend = {
        request  = { body = { bytes = 0 } }
        response = { body = { bytes = 0 } }
      }

      backend = {
        request  = { body = { bytes = 0 } }
        response = { body = { bytes = 0 } }
      }
    }
  }

  depends_on = [
    module.apim,
    azapi_resource.apimLogger,
    azapi_resource.applicationInsights,
    null_resource.wait_for_apim_ready
  ]
}


resource "azapi_resource" "apimRetailDevUser" {

  type      = "Microsoft.ApiManagement/service/users@2022-08-01"
  name      = "ai-retail-dev-user"
  parent_id = local.apim_id

  body = {
    properties = {
      firstName = "Retail AI"
      lastName  = "Developer"
      email     = "myuser@example.com"
      state     = "active"
    }
  }

  depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]
}

resource "azapi_resource" "apimRetailDevUserSubscription" {

  type      = "Microsoft.ApiManagement/service/subscriptions@2022-08-01"
  name      = "retail-ai-dev-user-subscription"
  parent_id = local.apim_id

  body = {
    properties = {
      displayName  = "Retail AI Dev User Subscription"
      ownerId      = "/users/${azapi_resource.apimRetailDevUser.name}"
      state        = "active"
      allowTracing = true
      scope        = "/products/${azapi_resource.retailProduct.name}"
    }
  }
    depends_on = [
    module.apim,
    null_resource.wait_for_apim_ready
  ]

}


############################################
# APIM Name
############################################
output "apimName" {
  description = "The name of the deployed API Management service."
  value       = try(module.apim[0].name, null)
}

############################################
# OpenAI API Path
############################################
output "apimOpenaiApiPath" {
  description = "The path for the OpenAI API in the deployed API Management service."
  value       = module.apimOpenaiApi.path
}

############################################
# APIM Gateway URL
############################################

output "apimGatewayUrl" {
  value = try(
    "https://${module.apim[0].name}.azure-api.net",
    null
  )
}
