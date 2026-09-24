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