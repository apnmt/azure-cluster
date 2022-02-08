resource "azurerm_servicebus_namespace" "namespace" {
  name                = "apnmt-servicebus"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_topic" "appointment-changed" {
  name                = "appointment-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "service-changed" {
  name                = "service-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "closing-time-changed" {
  name                = "closing-time-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "opening-hour-changed" {
  name                = "opening-hour-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "working-hour-changed" {
  name                = "working-hour-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "organization-activation-changed" {
  name                = "organization-activation-changed"
  namespace_id        = azurerm_servicebus_namespace.namespace.id
  enable_partitioning = true
}

