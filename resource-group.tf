resource "azurerm_resource_group" "rg" {
  name     = "apnmt_resource_group"
  location = var.location
}