module "organizationappointmentservice-application" {
  source = "./modules/app-service-mongo-application"

  application_name      = "organizationappointmentservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Standard"
  tier_size             = "S1"
  apim_ip_addresses     = azurerm_api_management.apim.public_ip_addresses
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING        = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER             = lower(azurerm_servicebus_namespace.namespace.sku)
    SPRING_JMS_SERVICEBUS_TOPICCLIENTID           = azurerm_servicebus_topic.appointment-changed.name
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.organizationappointmentservice-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING         = azurerm_application_insights.organizationappointmentservice-insights.connection_string
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "organizationappointment-api" {
  name                = "organizationappointment-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Organizationappointment API"
  path                = "service/organizationappointment"
  protocols           = ["https"]
  service_url         = "https://${module.organizationappointmentservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "organizationappointment-get-slots" {
  operation_id        = "slots-get"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Slots"
  method              = "GET"
  url_template        = "/api/slots"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "organizationappointmentservice-get-wildcard" {
  operation_id        = "wildcard-get"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Wildcard"
  method              = "GET"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationappointmentservice-get-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationappointmentservice-get-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationappointmentservice-get-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationappointmentservice-get-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationappointmentservice-get-wildcard.operation_id

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
            <required-claims>
                <claim name="groups" match="any" separator=";">
                    <value>admin</value>
                </claim>
            </required-claims>
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

resource "azurerm_api_management_api_operation" "organizationappointmentservice-post-wildcard" {
  operation_id        = "wildcard-post"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Wildcard"
  method              = "POST"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationappointmentservice-post-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationappointmentservice-post-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationappointmentservice-post-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationappointmentservice-post-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationappointmentservice-post-wildcard.operation_id

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
            <required-claims>
                <claim name="groups" match="any" separator=";">
                    <value>admin</value>
                </claim>
            </required-claims>
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

resource "azurerm_api_management_api_operation" "organizationappointmentservice-put-wildcard" {
  operation_id        = "wildcard-put"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put Wildcard"
  method              = "PUT"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationappointmentservice-put-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationappointmentservice-put-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationappointmentservice-put-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationappointmentservice-put-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationappointmentservice-put-wildcard.operation_id

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
            <required-claims>
                <claim name="groups" match="any" separator=";">
                    <value>admin</value>
                </claim>
            </required-claims>
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

resource "azurerm_api_management_api_operation" "organizationappointmentservice-delete-wildcard" {
  operation_id        = "wildcard-delete"
  api_name            = azurerm_api_management_api.organizationappointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Delete Wildcard"
  method              = "DELETE"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationappointmentservice-delete-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationappointmentservice-delete-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationappointmentservice-delete-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationappointmentservice-delete-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationappointmentservice-delete-wildcard.operation_id

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
            <required-claims>
                <claim name="groups" match="any" separator=";">
                    <value>admin</value>
                </claim>
            </required-claims>
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

#########################
# Application insights
#########################
resource "azurerm_application_insights" "organizationappointmentservice-insights" {
  name                = "organizationappointment-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  application_type    = "java"
}