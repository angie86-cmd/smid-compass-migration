# Resource Group for the SMID Compass nonprofit DEV environment.
resource "azurerm_resource_group" "smid_compass_dev" {
  name     = "rg-${local.project}-${local.environment}"
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace for DEV observability (agent execution logs,
# failures, latency). PerGB2018 is the standard pay-as-you-go SKU.
resource "azurerm_log_analytics_workspace" "smid_compass_dev" {
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.smid_compass_dev.name
  location            = azurerm_resource_group.smid_compass_dev.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = local.common_tags
}

# Application Insights for DEV, connected to the Log Analytics Workspace
# above (workspace-based mode, the current supported configuration).
resource "azurerm_application_insights" "smid_compass_dev" {
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.smid_compass_dev.name
  location            = azurerm_resource_group.smid_compass_dev.location

  application_type = "web"
  workspace_id     = azurerm_log_analytics_workspace.smid_compass_dev.id

  tags = local.common_tags
}

# Microsoft Foundry resource (Cognitive Services account, kind = AIServices)
# for the SMID Compass nonprofit DEV environment. This is the parent AI
# Services resource; model deployments, RBAC, connections, agents, and
# knowledge/vector stores are intentionally not part of this configuration
# yet and are introduced in later steps.
resource "azurerm_cognitive_account" "smid_compass_dev" {
  name                = local.foundry_resource_name
  resource_group_name = azurerm_resource_group.smid_compass_dev.name
  location            = azurerm_resource_group.smid_compass_dev.location

  kind     = "AIServices"
  sku_name = "S0"

  custom_subdomain_name      = local.foundry_resource_name
  project_management_enabled = true

  # Source parity (source/azure/foundry-resource.raw.json):
  # publicNetworkAccess = "Enabled" and disableLocalAuth = false (i.e.
  # local/key-based authentication is allowed). Preserved as-is here;
  # tightening network exposure or disabling local auth would be a
  # security modernization decision, deferred to Modernization v2, not
  # this parity-focused migration step.
  public_network_access_enabled = true
  local_auth_enabled            = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Microsoft Foundry project under the Foundry resource above. The identity
# block is required by this resource in AzureRM 4.81.0 (not merely
# optional, unlike on azurerm_cognitive_account).
resource "azurerm_cognitive_account_project" "smid_compass_dev" {
  name                 = local.foundry_project_name
  cognitive_account_id = azurerm_cognitive_account.smid_compass_dev.id
  location             = azurerm_cognitive_account.smid_compass_dev.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}