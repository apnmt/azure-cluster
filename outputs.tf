output "api_gateway_invoke_url" {
  description = "Url to invoke Api Gateway"
  value       = azurerm_api_management.apim.gateway_url
}