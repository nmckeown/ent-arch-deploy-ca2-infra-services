provider "azurerm" {
  features {
    resource_group {
       prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Public IP
resource "azurerm_public_ip" "outbound_ip" {
  name                = "${var.aks_cluster_name}OutboundIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Log Analytics Workspace for Monitoring
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "${var.aks_cluster_name}Workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Create Network Security Group
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.aks_cluster_name}-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80","443","9000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = lower(var.aks_cluster_name)
  sku_tier            = "Premium"
  kubernetes_version  = "1.29.5"
  support_plan        = "AKSLongTermSupport"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"

    load_balancer_profile {
      outbound_ip_address_ids = [
        azurerm_public_ip.outbound_ip.id
      ]
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
  }

  tags = {
    environment = var.environment
  }
}

# network identity for load balancer
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

# storage for sharing tfstate file
terraform {
  backend "azurerm" {
    resource_group_name   = "eadca2rg"
    storage_account_name  = "mytfstateaccount"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}