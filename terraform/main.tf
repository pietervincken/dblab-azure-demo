terraform {
  required_providers {
    azurerm = "~> 3.34.0"
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {

  name     = "dblabdemo"
  location = "West Europe"

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
  length    = 16
  special   = false
  min_lower = 1
  min_upper = 1
}

resource "random_string" "token" {
  length      = 16
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "password" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "password"
  value        = random_password.password.result
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_key_vault_secret" "username" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "username"
  value        = random_string.username.result
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_key_vault_secret" "token" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "token"
  value        = random_string.token.result
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_key_vault_secret" "private_key" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "private"
  value        = tls_private_key.this.private_key_pem
  depends_on = [
    azurerm_key_vault_access_policy.this
  ]
}

resource "azurerm_key_vault_secret" "public_key" {
  key_vault_id = azurerm_key_vault.this.id
  name         = "public"
  value        = tls_private_key.this.public_key_pem
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
  collation           = "en-US" #"en_US.utf8"
}

resource "azurerm_postgresql_firewall_rule" "firewall_postgres" {
  name                = "pgfr-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_D4as_v5"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.this.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "disk_1" {
  name                 = "disk-${local.name}-1-disk"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_1" {
  managed_disk_id    = azurerm_managed_disk.disk_1.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "disk_2" {
  name                 = "disk-${local.name}-2-disk"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_2" {
  managed_disk_id    = azurerm_managed_disk.disk_2.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = "20"
  caching            = "ReadWrite"
}
