module "organizationservice-application" {
  source = "./modules/app-service-postgres-application"

  application_name      = "organizationservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Basic"
  tier_size             = "B1"
  postgres_sku_name     = "B_Gen5_1"
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER      = lower(azurerm_servicebus_namespace.namespace.sku)
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

#################
# Subscriptions
#################
resource "azurerm_servicebus_subscription" "org-organization-activation-changed-subscription" {
  name               = "org-organization-activation-changed-subscription"
  topic_id           = azurerm_servicebus_topic.organization-activation-changed.id
  max_delivery_count = 3
}