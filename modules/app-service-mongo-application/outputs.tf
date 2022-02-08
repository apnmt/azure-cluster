output "app_service_endpoint_url" {
  description = "App Service endpoint url"
  value       = azurerm_app_service.appservice.default_site_hostname
}