resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "apnmt-workspace"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}