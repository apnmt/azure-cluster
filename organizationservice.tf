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
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = data.azurerm_application_insights.organizationservice-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING         = data.azurerm_application_insights.organizationservice-insights.connection_string
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "organization-api" {
  name                = "organization-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Organization API"
  path                = "service/organization"
  protocols           = ["https"]
  service_url         = "https://${module.organizationservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "organizationservice-get-opening-hours" {
  operation_id        = "opening-hours-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Opening-Hours for Organization"
  method              = "GET"
  url_template        = "/api/opening-hours/organization/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "organizationservice-get-working-hours" {
  operation_id        = "working-hours-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Working-Hours for Organization"
  method              = "GET"
  url_template        = "/api/working-hours/organization/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "organizationservice-get-employees" {
  operation_id        = "employees-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Employees for Organization"
  method              = "GET"
  url_template        = "/api/employees/organization/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "organizationservice-get-closing-times" {
  operation_id        = "closing-times-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Closing-Times for Organization"
  method              = "GET"
  url_template        = "/api/closing-times/organization/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
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

resource "azurerm_api_management_api_operation" "organizationservice-post-organizations" {
  operation_id        = "organizations-post"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Organizations"
  method              = "POST"
  url_template        = "/api/organizations"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "organizationservice-get-wildcard" {
  operation_id        = "wildcard-get"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Wildcard"
  method              = "GET"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationservice-get-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationservice-get-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationservice-get-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationservice-get-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationservice-get-wildcard.operation_id

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
                    <value>manager</value>
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

resource "azurerm_api_management_api_operation" "organizationservice-post-wildcard" {
  operation_id        = "wildcard-post"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Wildcard"
  method              = "POST"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationservice-post-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationservice-post-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationservice-post-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationservice-post-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationservice-post-wildcard.operation_id

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
                    <value>manager</value>
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

resource "azurerm_api_management_api_operation" "organizationservice-put-wildcard" {
  operation_id        = "wildcard-put"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put Wildcard"
  method              = "PUT"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationservice-put-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationservice-put-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationservice-put-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationservice-put-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationservice-put-wildcard.operation_id

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
                    <value>manager</value>
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

resource "azurerm_api_management_api_operation" "organizationservice-delete-wildcard" {
  operation_id        = "wildcard-delete"
  api_name            = azurerm_api_management_api.organization-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Delete Wildcard"
  method              = "DELETE"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "organizationservice-delete-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.organizationservice-delete-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.organizationservice-delete-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.organizationservice-delete-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.organizationservice-delete-wildcard.operation_id

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
                    <value>manager</value>
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
resource "azurerm_servicebus_subscription" "org-organization-activation-changed-subscription" {
  name               = "org-organization-activation-changed-subscription"
  topic_id           = azurerm_servicebus_topic.organization-activation-changed.id
  max_delivery_count = 3
}

#########################
# Application insights
#########################
data "azurerm_application_insights" "organizationservice-insights" {
  name                = "organization-insights"
  resource_group_name = "apnmt_applications"
}