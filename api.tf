resource "azurerm_api_management" "apim" {
  name                = "apnmt-apim"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Apnmt"
  publisher_email     = "apnmt@apnmt.io"

  sku_name = "Developer_1"
}