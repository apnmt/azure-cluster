module "appointmentservice-application" {
  source = "./modules/app-service-postgres-application"

  application_name      = "appointmentservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Standard"
  tier_size             = "S1"
  postgres_sku_name     = "GP_Gen5_8"
  apim_ip_addresses     = azurerm_api_management.apim.public_ip_addresses
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING        = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER             = lower(azurerm_servicebus_namespace.namespace.sku)
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = data.azurerm_application_insights.appointmentservice-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING         = data.azurerm_application_insights.appointmentservice-insights.connection_string
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "appointment-api" {
  name                = "apnmt-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Appointment API"
  path                = "service/appointment"
  protocols           = ["https"]
  service_url         = "https://${module.appointmentservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "appointments-wildcard-get" {
  operation_id        = "appointments-wildcard-get"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Wildcard"
  method              = "GET"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointments-post" {
  operation_id        = "appointments-post"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "POST Appointment"
  method              = "POST"
  url_template        = "/api/appointments"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointments-put" {
  operation_id        = "appointments-put"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "PUT Appointment"
  method              = "PUT"
  url_template        = "/api/appointments/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointment-delete" {
  operation_id        = "appointment-delete"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "DELETE Appointment"
  method              = "DELETE"
  url_template        = "/api/appointments/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointments-get-one" {
  operation_id        = "appointments-get-one"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Appointment by Id"
  method              = "GET"
  url_template        = "/api/appointments/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointments-organization-get" {
  operation_id        = "appointments-organization-get"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Appointments for Organization"
  method              = "GET"
  url_template        = "/api/appointments/organization/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "appointments-organization-get-policy" {
  api_name            = azurerm_api_management_api_operation.appointments-organization-get.api_name
  api_management_name = azurerm_api_management_api_operation.appointments-organization-get.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointments-organization-get.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointments-organization-get.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointments-get" {
  operation_id        = "appointments-get"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Appointments"
  method              = "GET"
  url_template        = "/api/appointments"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "appointments-get-policy" {
  api_name            = azurerm_api_management_api_operation.appointments-get.api_name
  api_management_name = azurerm_api_management_api_operation.appointments-get.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointments-get.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointments-get.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-get-customers-organization" {
  operation_id        = "get-customers-organization"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Customers for Organization"
  method              = "GET"
  url_template        = "/api/customers/organization{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-get-customers-organization-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-get-customers-organization.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-get-customers-organization.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-get-customers-organization.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-get-customers-organization.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-get-customers" {
  operation_id        = "get-customers"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET Customers"
  method              = "GET"
  url_template        = "/api/customers"

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-get-customers-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-get-customers.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-get-customers.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-get-customers.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-get-customers.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-customer-post" {
  operation_id        = "customers-post"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post customers"
  method              = "POST"
  url_template        = "/api/customers"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointmentservice-customer-put" {
  operation_id        = "customers-put"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put customers"
  method              = "PUT"
  url_template        = "/api/customers/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "appointmentservice-post-service" {
  operation_id        = "service-post"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "POST Service"
  method              = "POST"
  url_template        = "/api/services"

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-post-service-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-post-service.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-post-service.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-post-service.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-post-service.operation_id

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
                    <value>manager</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-put-service" {
  operation_id        = "service-put"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "PUT Service"
  method              = "PUT"
  url_template        = "/api/services/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-put-service-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-put-service.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-put-service.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-put-service.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-put-service.operation_id

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
                    <value>manager</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-delete-service" {
  operation_id        = "service-delete"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "DELETE Service"
  method              = "DELETE"
  url_template        = "/api/services/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-delete-service-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-delete-service.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-delete-service.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-delete-service.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-delete-service.operation_id

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
                    <value>manager</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointments-delete" {
  operation_id        = "appointments-delete"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "DELETE Appointments"
  method              = "DELETE"
  url_template        = "/api/appointments"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "appointments-delete-policy" {
  api_name            = azurerm_api_management_api_operation.appointments-delete.api_name
  api_management_name = azurerm_api_management_api_operation.appointments-delete.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointments-delete.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointments-delete.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-delete-customers" {
  operation_id        = "delete-customers"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "DELETE Customers"
  method              = "DELETE"
  url_template        = "/api/customers"

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-delete-customers-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-delete-customers.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-delete-customers.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-delete-customers.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-delete-customers.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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

resource "azurerm_api_management_api_operation" "appointmentservice-delete-services" {
  operation_id        = "delete-services"
  api_name            = azurerm_api_management_api.appointment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "DELETE Services"
  method              = "DELETE"
  url_template        = "/api/services"

  response {
    status_code = 201
  }
}

resource "azurerm_api_management_api_operation_policy" "appointmentservice-delete-services-policy" {
  api_name            = azurerm_api_management_api_operation.appointmentservice-delete-services.api_name
  api_management_name = azurerm_api_management_api_operation.appointmentservice-delete-services.api_management_name
  resource_group_name = azurerm_api_management_api_operation.appointmentservice-delete-services.resource_group_name
  operation_id        = azurerm_api_management_api_operation.appointmentservice-delete-services.operation_id

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
        <set-header name="X-User-Name" exists-action="override">
           <value>@(context.Request.Headers["Authorization"].First().Split(' ')[1].AsJwt()?.Claims["name"].FirstOrDefault())</value>
        </set-header>
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
data "azurerm_application_insights" "appointmentservice-insights" {
  name                = "appointment-insights"
  resource_group_name = "apnmt_applications"
}