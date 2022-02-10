module "organizationappointmentservice-application" {
  source = "./modules/app-service-mongo-application"

  application_name      = "organizationappointmentservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Basic"
  tier_size             = "B1"
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER      = lower(azurerm_servicebus_namespace.namespace.sku)
    SPRING_JMS_SERVICEBUS_TOPICCLIENTID    = azurerm_servicebus_topic.appointment-changed.name
  }
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

resource "azurerm_api_management_api_operation_policy" "organizationappointment-get-services-policy" {
  api_name            = azurerm_api_management_api_operation.organizationappointment-get-services.api_name
  api_management_name = azurerm_api_management_api_operation.organizationappointment-get-services.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationappointment-get-services.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationappointment-get-services.operation_id

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
resource "azurerm_servicebus_subscription" "orgapnmt-appointment-changed-subscription" {
  name               = "orgapnmt-appointment-changed-subscription"
  topic_id           = azurerm_servicebus_topic.appointment-changed.id
  max_delivery_count = 3
}

resource "azurerm_servicebus_subscription" "orgapnmt-service-changed-subscription" {
  name               = "orgapnmt-service-changed-subscription"
  topic_id           = azurerm_servicebus_topic.service-changed.id
  max_delivery_count = 3
}

resource "azurerm_servicebus_subscription" "orgapnmt-closing-time-changed-subscription" {
  name               = "orgapnmt-closing-time-changed-subscription"
  topic_id           = azurerm_servicebus_topic.closing-time-changed.id
  max_delivery_count = 3
}

resource "azurerm_servicebus_subscription" "orgapnmt-opening-hour-changed-subscription" {
  name               = "orgapnmt-opening-hour-changed-subscription"
  topic_id           = azurerm_servicebus_topic.opening-hour-changed.id
  max_delivery_count = 3
}

resource "azurerm_servicebus_subscription" "orgapnmt-working-hour-changed-subscription" {
  name               = "orgapnmt-working-hour-changed-subscription"
  topic_id           = azurerm_servicebus_topic.working-hour-changed.id
  max_delivery_count = 3
}