module "organizationservice-application" {
  source = "./modules/app-service-postgres-application"

  application_name      = "organizationservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Standard"
  tier_size             = "S1"
  postgres_sku_name     = "GP_Gen5_8"
  apim_ip_addresses     = azurerm_api_management.apim.public_ip_addresses
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING        = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER             = lower(azurerm_servicebus_namespace.namespace.sku)
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.organizationservice-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING         = azurerm_application_insights.organizationservice-insights.connection_string
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "organization-api" {
  name                = "apnmt-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Apnmt API"
  path                = "service/organization"
  protocols           = ["https"]
  service_url         = "https://${module.organizationservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "organizationservice-get-organizations" {
  operation_id        = "organizations-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Organizations"
  method              = "GET"
  url_template        = "/api/organizations"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationservice-get-organizations-policy" {
  api_name            = azurerm_api_management_api_operation.organizationservice-get-organizations.api_name
  api_management_name = azurerm_api_management_api_operation.organizationservice-get-organizations.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationservice-get-organizations.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationservice-get-organizations.operation_id

  xml_content = <<XML
<policies>
    <inbound>
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
            <openid-config url="${var.open-id-url}" />
            <audiences>
                <audience>${var.client-id}</audience>
            </audiences>
            <issuers>
                <issuer>${var.issuer}</issuer>
            </issuers>
        </validate-jwt>
        <base />
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

#################
# Subscriptions
#################
resource "azurerm_servicebus_subscription" "org-organization-activation-changed-subscription" {
  name               = "org-organization-activation-changed-subscription"
  topic_id           = azurerm_servicebus_topic.organization-activation-changed.id
  max_delivery_count = 3
}

#########################
# Application insights
#########################
resource "azurerm_application_insights" "organizationservice-insights" {
  name                = "organization-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  application_type    = "java"
}