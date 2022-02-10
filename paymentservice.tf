module "paymentservice-application" {
  source = "./modules/app-service-postgres-application"

  application_name      = "paymentservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Basic"
  tier_size             = "B1"
  postgres_sku_name     = "B_Gen5_1"
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING        = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER             = lower(azurerm_servicebus_namespace.namespace.sku)
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.paymentservice-insights.instrumentation_key
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "payment-api" {
  name                = "apnmt-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Apnmt API"
  path                = "service/payment"
  protocols           = ["https"]
  service_url         = "https://${module.paymentservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "paymentservice-get-products" {
  operation_id        = "products-get"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get products"
  method              = "GET"
  url_template        = "/api/products"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-get-organizations-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-get-products.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-get-products.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-get-products.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-get-products.operation_id

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

#########################
# Application insights
#########################
resource "azurerm_application_insights" "paymentservice-insights" {
  name                = "payment-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  application_type    = "java"
}