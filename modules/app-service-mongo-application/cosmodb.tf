resource "azurerm_cosmosdb_account" "account" {
  name                = "${var.application_name}-cosmos-db"
  location            = "northeurope"
  resource_group_name = var.resource_group
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  # app service ips cannot be used because of cycle dependency
  ip_range_filter = "0.0.0.0"

  enable_free_tier = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "DisableRateLimitingResponses"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "northeurope"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "database" {
  name                = "${var.application_name}-cosmos-mongo-db"
  resource_group_name = var.resource_group
  account_name        = azurerm_cosmosdb_account.account.name
  throughput          = 8000
}