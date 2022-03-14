resource "azurerm_postgresql_server" "postgresql-server" {
  name = "apnmt-${var.application_name}-postgresql"
  location = var.location
  resource_group_name = var.resource_group

  administrator_login          = var.application_name
  administrator_login_password = "Th1sIsAP@ssw0rd"

  sku_name = var.postgres_sku_name
  version  = "11"

  storage_mb        = "5120"
  auto_grow_enabled = true

  backup_retention_days            = 7
  geo_redundant_backup_enabled     = false
  public_network_access_enabled    = true
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

resource "azurerm_postgresql_database" "postgresql-db" {
  name                = var.application_name
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.postgresql-server.name
  charset             = "utf8"
  collation           = "English_United States.1252"
}

locals {
  sorted_ips = sort(azurerm_app_service.appservice.outbound_ip_address_list)
}

# enable access from all azure services
resource "azurerm_postgresql_firewall_rule" "firewall" {
  name                = "${var.application_name}-firewall"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.postgresql-server.name
  start_ip_address    = local.sorted_ips.0
  end_ip_address      = element(local.sorted_ips, length(local.sorted_ips)-1)
}