# Outputs expose selected infrastructure values after deployment.
# They make important resource identifiers easy to reuse in later
# Terraform work, automation, validation, and operational checks.

output "resource_group_name" {
  description = "Name of the SMID Compass DEV resource group."
  value       = azurerm_resource_group.smid_compass_dev.name
}

output "log_analytics_workspace_name" {
  description = "Name of the SMID Compass DEV Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.smid_compass_dev.name
}

output "log_analytics_workspace_id" {
  description = "ARM resource ID of the SMID Compass DEV Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.smid_compass_dev.id
}

output "application_insights_name" {
  description = "Name of the SMID Compass DEV Application Insights resource."
  value       = azurerm_application_insights.smid_compass_dev.name
}

output "application_insights_id" {
  description = "ARM resource ID of the SMID Compass DEV Application Insights resource."
  value       = azurerm_application_insights.smid_compass_dev.id
}