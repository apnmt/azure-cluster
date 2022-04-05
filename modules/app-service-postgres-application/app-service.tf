# Create app service plan
resource "azurerm_app_service_plan" "plan" {
  name                = "apnmt-${var.application_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group
  kind = "Linux"
  reserved            = true
  sku {
    tier = var.tier
    size = var.tier_size
  }
  per_site_scaling = true
}
# Create the app service
resource "azurerm_app_service" "appservice" {
  name                = "apnmt-${var.application_name}"
  location            = var.location
  resource_group_name = var.resource_group
  app_service_plan_id = azurerm_app_service_plan.plan.id
  site_config {
    java_version           = "11"
    java_container         = "JAVA"
    java_container_version = "11"
    linux_fx_version       = "JAVA|11-java11"
    app_command_line       = "java -javaagent:/home/site/wwwroot/applicationinsights-agent.jar -jar /home/site/wwwroot/${var.application_name}.jar --server.port=80"
    health_check_path      = "/management/health/liveness"
    number_of_workers      = var.max_size
    scm_type               = "LocalGit"

    dynamic "ip_restriction" {
      for_each = var.apim_ip_addresses
      content {
        ip_address = "${ip_restriction.value}/24"
      }
    }
  }
  app_settings = merge({
    SPRING_DATASOURCE_URL      = "jdbc:postgresql://${azurerm_postgresql_server.postgresql-server.fqdn}:5432/${azurerm_postgresql_database.postgresql-db.name}?user=${azurerm_postgresql_server.postgresql-server.administrator_login}@${azurerm_postgresql_server.postgresql-server.name}&password=${azurerm_postgresql_server.postgresql-server.administrator_login_password}&sslmode=require&stringtype=unspecified"
    SPRING_DATASOURCE_USERNAME = azurerm_postgresql_server.postgresql-server.administrator_login
    SPRING_DATASOURCE_PASSWORD = azurerm_postgresql_server.postgresql-server.administrator_login_password
  }, var.environment_variables)
}

# deploy the application from blob storage
resource "null_resource" "deploy-application" {
  provisioner "local-exec" {
    command = <<EOF
    curl -X POST -u '${azurerm_app_service.appservice.site_credential.0.username}:${azurerm_app_service.appservice.site_credential.0.password}' "https://${azurerm_app_service.appservice.name}.scm.azurewebsites.net/api/publish?type=zip" -d '{"packageUri": "https://apnmt.blob.core.windows.net/apnmt-applications/${var.application_name}.zip?sp=r&st=2022-02-07T15:48:47Z&se=2022-07-29T22:48:47Z&spr=https&sv=2020-08-04&sr=c&sig=taNF7%2Bebo9LLaWVpv%2B5M1s4KD4nBgqFCGhuMKl3rS6I%3D"}' -H "Content-Type: application/json"
    EOF
  }
}

# Configure auto scaling
resource "azurerm_monitor_autoscale_setting" "autoscale_setting" {
  name                = "apnmt-${var.application_name}-autoscale-setting"
  resource_group_name = var.resource_group
  location            = var.location
  target_resource_id  = azurerm_app_service_plan.plan.id
  profile {
    name = "default"
    capacity {
      default = var.min_size
      minimum = var.min_size
      maximum = var.max_size
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.cpu_greater_threshold
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.cpu_less_threshold
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}