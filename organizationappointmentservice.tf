module "organizationappointmentservice-application" {
  source = "./modules/app-service-mongo-application"

  application_name = "organizationappointmentservice"
  location         = var.location
  resource_group   = azurerm_resource_group.rg.name
  tier             = "Basic"
  tier_size        = "B1"
}

#################
# API
#################
resource "azurerm_api_management_api" "organizationappointment-api" {
  name                = "apnmt-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Apnmt API"
  path                = "service/organizationappointment"
  protocols           = ["https"]
  service_url         = "https://${module.organizationappointmentservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "organizationappointment-get-services" {
  operation_id        = "services-get"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Services"
  method              = "GET"
  url_template        = "/api/services"

  response {
    status_code = 200
  }
}