resource "azapi_resource" "apim_backend_ai_foundry" {
  count = local.apim_deploy_sample_apis ? 1 : 0

  name      = "ai-foundry-backend"
  parent_id = module.apim[0].resource_id
  type      = "Microsoft.ApiManagement/service/backends@2024-05-01"

  body = {
    properties = {
      description = "Azure AI Foundry backend service"
      protocol    = "http"
      url         = local.apim_ai_foundry_endpoint
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }

  response_export_values = []
}

resource "azapi_resource" "apim_api_ai_foundry" {
  count = local.apim_deploy_sample_apis ? 1 : 0

  name      = "azure-openai-api"
  parent_id = module.apim[0].resource_id
  type      = "Microsoft.ApiManagement/service/apis@2024-05-01"

  body = {
    properties = {
      description = "Sample API for Azure AI Foundry - validates APIM to AI Foundry connectivity"
      displayName = "Azure OpenAI API"
      path        = "openai"
      protocols   = ["https"]
      serviceUrl  = "${local.apim_ai_foundry_endpoint}/openai"
      type        = "http"
      apiRevision = "1"
      isCurrent   = true
      subscriptionKeyParameterNames = {
        header = "api-key"
        query  = "api-key"
      }
      subscriptionRequired = true
    }
  }

  response_export_values = []

  depends_on = [azapi_resource.apim_backend_ai_foundry]
}

resource "azapi_resource" "apim_api_operation_chat_completions" {
  count = local.apim_deploy_sample_apis ? 1 : 0

  name      = "chat-completions"
  parent_id = azapi_resource.apim_api_ai_foundry[0].id
  type      = "Microsoft.ApiManagement/service/apis/operations@2024-05-01"

  body = {
    properties = {
      description = "Creates a completion for the chat message using a deployed model."
      displayName = "Chat Completions"
      method      = "POST"
      urlTemplate = "/deployments/{deployment-id}/chat/completions"
      templateParameters = [
        {
          name        = "deployment-id"
          description = "The deployment ID of the model to use."
          type        = "string"
          required    = true
        }
      ]
      request = {
        queryParameters = [
          {
            name         = "api-version"
            description  = "The Azure OpenAI API version to use."
            type         = "string"
            required     = true
            defaultValue = "2024-06-01"
          }
        ]
      }
    }
  }

  response_export_values = []
}

resource "azapi_resource" "apim_api_operation_list_models" {
  count = local.apim_deploy_sample_apis ? 1 : 0

  name      = "list-models"
  parent_id = azapi_resource.apim_api_ai_foundry[0].id
  type      = "Microsoft.ApiManagement/service/apis/operations@2024-05-01"

  body = {
    properties = {
      description = "Lists the available models for the Azure OpenAI service."
      displayName = "List Models"
      method      = "GET"
      urlTemplate = "/models"
      request = {
        queryParameters = [
          {
            name         = "api-version"
            description  = "The Azure OpenAI API version to use."
            type         = "string"
            required     = true
            defaultValue = "2024-06-01"
          }
        ]
      }
    }
  }

  response_export_values = []
}

resource "azapi_resource" "apim_api_policy_ai_foundry" {
  count = local.apim_deploy_sample_apis ? 1 : 0

  name      = "policy"
  parent_id = azapi_resource.apim_api_ai_foundry[0].id
  type      = "Microsoft.ApiManagement/service/apis/policies@2024-05-01"

  body = {
    properties = {
      format = "rawxml"
      value  = <<-XML
        <policies>
          <inbound>
            <base />
            <set-backend-service backend-id="${azapi_resource.apim_backend_ai_foundry[0].name}" />
          </inbound>
          <backend>
            <base />
          </backend>
          <outbound>
            <base />
          </outbound>
          <on-error>
            <base />
          </on-error>
        </policies>
      XML
    }
  }

  response_export_values = []
}
