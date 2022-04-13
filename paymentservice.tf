module "paymentservice-application" {
  source = "./modules/app-service-postgres-application"

  application_name      = "paymentservice"
  location              = var.location
  resource_group        = azurerm_resource_group.rg.name
  tier                  = "Standard"
  tier_size             = "S1"
  postgres_sku_name     = "GP_Gen5_8"
  apim_ip_addresses     = azurerm_api_management.apim.public_ip_addresses
  environment_variables = {
    SPRING_JMS_SERVICEBUS_CONNECTIONSTRING        = azurerm_servicebus_namespace.namespace.default_primary_connection_string
    SPRING_JMS_SERVICEBUS_PRICINGTIER             = lower(azurerm_servicebus_namespace.namespace.sku)
    AZURE_APPLICATIONSINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.paymentservice-insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING         = azurerm_application_insights.paymentservice-insights.connection_string
  }
}

#################
# API
#################
resource "azurerm_api_management_api" "payment-api" {
  name                = "payment-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Payment API"
  path                = "service/payment"
  protocols           = ["https"]
  service_url         = "https://${module.paymentservice-application.app_service_endpoint_url}"
}

resource "azurerm_api_management_api_operation" "paymentservice-post-stripe-events" {
  operation_id        = "stripe-events-post"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post stripe events"
  method              = "POST"
  url_template        = "/api/stripe/events"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "paymentservice-post-products" {
  operation_id        = "products-post"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Products"
  method              = "POST"
  url_template        = "/api/products"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-post-products-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-post-products.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-post-products.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-post-products.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-post-products.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-put-products" {
  operation_id        = "products-put"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put Products"
  method              = "PUT"
  url_template        = "/api/products/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-put-products-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-put-products.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-put-products.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-put-products.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-put-products.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-post-prices" {
  operation_id        = "prices-post"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Prices"
  method              = "POST"
  url_template        = "/api/prices"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-post-prices-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-post-prices.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-post-prices.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-post-prices.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-post-prices.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-put-prices" {
  operation_id        = "prices-put"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put Prices"
  method              = "PUT"
  url_template        = "/api/prices/{id}"
  template_parameter {
    name     = "id"
    required = true
    type     = "integer"
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-put-prices-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-put-prices.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-put-prices.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-put-prices.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-put-prices.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-get-customers" {
  operation_id        = "customers-get"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Customers"
  method              = "GET"
  url_template        = "/api/customers"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-get-customers-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-get-customers.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-get-customers.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-get-customers.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-get-customers.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-get-wildcard" {
  operation_id        = "wildcard-get"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get Wildcard"
  method              = "GET"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-get-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-get-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-get-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-get-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-get-wildcard.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-post-wildcard" {
  operation_id        = "wildcard-post"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Wildcard"
  method              = "POST"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-post-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-post-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-post-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-post-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-post-wildcard.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-put-wildcard" {
  operation_id        = "wildcard-put"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Put Wildcard"
  method              = "PUT"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-put-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-put-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-put-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-put-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-put-wildcard.operation_id

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

resource "azurerm_api_management_api_operation" "paymentservice-delete-wildcard" {
  operation_id        = "wildcard-delete"
  api_name            = azurerm_api_management_api.payment-api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Delete Wildcard"
  method              = "DELETE"
  url_template        = "/api/*"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "paymentservice-delete-wildcard-policy" {
  api_name            = azurerm_api_management_api_operation.paymentservice-delete-wildcard.api_name
  api_management_name = azurerm_api_management_api_operation.paymentservice-delete-wildcard.api_management_name
  resource_group_name = azurerm_api_management_api_operation.paymentservice-delete-wildcard.resource_group_name
  operation_id        = azurerm_api_management_api_operation.paymentservice-delete-wildcard.operation_id

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