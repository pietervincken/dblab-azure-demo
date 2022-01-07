locals{

    name="dblabdemo"
    location="West Europe"

}

data "azurerm_subscription" "this" {
}

data "azurerm_client_config" "this" {
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = local.location
}

resource "azurerm_key_vault" "this" {
  name                = "kv${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_subscription.this.tenant_id
  location            = azurerm_resource_group.this.location
}


resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_key_vault.this.tenant_id
  object_id    = data.azurerm_client_config.this.object_id
  secret_permissions = [
    "Delete", "Get", "List", "Set", "Purge"
  ]
}

resource "random_password" "password" {
  length      = 16
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
}

resource "random_string" "username" {
  length      = 16
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
}

resource "azurerm_key_vault_secret" "username" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "password"
  value        = random_password.password.result
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_key_vault_secret" "password" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "username"
  value        = random_string.username.result
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_postgresql_server" "this" {
  name                = "postgresql-${local.name}-1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = random_string.username.result
  administrator_login_password = random_password.password.result
  version                      = "11"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "this" {
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource ""