resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "azurerm_api_management" "apim" {
  name                = "apnmt-apim-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Apnmt"
  publisher_email     = "apnmt@apnmt.io"

  sku_name = "Standard_1"
}