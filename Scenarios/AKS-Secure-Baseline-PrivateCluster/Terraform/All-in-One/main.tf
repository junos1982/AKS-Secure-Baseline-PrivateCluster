locals {
  base_name     = lower(var.prefix)
  aks_name      = format("%s-aks", local.base_name)
  vnet_name     = format("%s-vnet", local.base_name)
  subnet_name   = format("%s-aks-subnet", local.base_name)
  identity_name = format("%s-mi", local.base_name)
  log_analytics = format("%s-law", local.base_name)
  dns_zone_name = format("privatelink.%s.azmk8s.io", var.location)
  tags = merge({
    "environment" = var.environment,
    "createdBy"   = "terraform"
  }, var.additional_tags)
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = local.log_analytics
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_virtual_network" "aks" {
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.subnet_address_prefix]

  private_endpoint_network_policies_enabled     = true
  private_link_service_network_policies_enabled = true
}

resource "azurerm_private_dns_zone" "aks" {
  name                = local.dns_zone_name
  resource_group_name = azurerm_resource_group.aks.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = format("%s-vnet-link", local.base_name)
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  resource_group_name   = azurerm_resource_group.aks.name
  virtual_network_id    = azurerm_virtual_network.aks.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = local.identity_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                        = "system"
    vm_size                     = var.agent_vm_size
    node_count                  = var.agent_count
    vnet_subnet_id              = azurerm_subnet.aks.id
    os_disk_size_gb             = var.agent_os_disk_size_gb
    only_critical_addons_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = "loadBalancer"
  }

  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks.id
  azure_policy_enabled    = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = local.tags

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  depends_on = [
    azurerm_role_assignment.aks_subnet_network_contributor,
    azurerm_private_dns_zone_virtual_network_link.aks
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  mode                  = "User"
  vnet_subnet_id        = azurerm_subnet.aks.id
  os_disk_size_gb       = var.user_node_os_disk_size_gb
  max_pods              = var.user_node_max_pods
  orchestrator_version  = var.kubernetes_version
  tags                  = local.tags
}

output "resource_group_name" {
  description = "Name of the resource group that hosts the AKS baseline"
  value       = azurerm_resource_group.aks.name
}

output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  description = "Raw kubeconfig for the created cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
