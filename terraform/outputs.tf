# Outputs expose only non-sensitive infrastructure identifiers (names and
# ARM resource IDs) needed for validation, later RBAC work, automation,
# and operational troubleshooting. No keys, tokens, connection strings,
# or other credentials are exposed anywhere in this file.

output "resource_group_name" {
  description = "Name of the SMID Compass DEV resource group."
  value       = azurerm_resource_group.smid_compass_dev.name
}

# --- Observability outputs -------------------------------------------

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

# --- Foundry resource/project outputs ---------------------------------

output "foundry_resource_name" {
  description = "Name of the SMID Compass DEV Microsoft Foundry resource (Cognitive Services account)."
  value       = azurerm_cognitive_account.smid_compass_dev.name
}

output "foundry_resource_id" {
  description = "ARM resource ID of the SMID Compass DEV Microsoft Foundry resource."
  value       = azurerm_cognitive_account.smid_compass_dev.id
}

output "foundry_resource_principal_id" {
  description = "Object ID of the SMID Compass DEV Microsoft Foundry resource's system-assigned managed identity."
  value       = azurerm_cognitive_account.smid_compass_dev.identity[0].principal_id
}

output "foundry_project_name" {
  description = "Name of the SMID Compass DEV Microsoft Foundry project."
  value       = azurerm_cognitive_account_project.smid_compass_dev.name
}

output "foundry_project_id" {
  description = "ARM resource ID of the SMID Compass DEV Microsoft Foundry project."
  value       = azurerm_cognitive_account_project.smid_compass_dev.id
}

output "foundry_project_principal_id" {
  description = "Object ID of the SMID Compass DEV Microsoft Foundry project's system-assigned managed identity."
  value       = azurerm_cognitive_account_project.smid_compass_dev.identity[0].principal_id
}

output "guardrails_policy_id" {
  description = "ARM resource ID of the SMID-Guardrails-Policy RAI policy. Used as rai_config.rai_policy_name when restoring the five agents that reference this policy."
  value       = azurerm_cognitive_account_rai_policy.smid_guardrails.id
}

# --- Model deployment outputs ------------------------------------------

output "gpt_4_1_mini_deployment_name" {
  description = "Name of the gpt-4.1-mini model deployment on the SMID Compass DEV Foundry resource."
  value       = azurerm_cognitive_deployment.gpt_4_1_mini.name
}

output "gpt_4_1_mini_deployment_id" {
  description = "ARM resource ID of the gpt-4.1-mini model deployment."
  value       = azurerm_cognitive_deployment.gpt_4_1_mini.id
}

output "text_embedding_3_small_deployment_name" {
  description = "Name of the text-embedding-3-small model deployment on the SMID Compass DEV Foundry resource."
  value       = azurerm_cognitive_deployment.text_embedding_3_small.name
}

output "text_embedding_3_small_deployment_id" {
  description = "ARM resource ID of the text-embedding-3-small model deployment."
  value       = azurerm_cognitive_deployment.text_embedding_3_small.id
}

# --- Budget output ------------------------------------------------------

output "dev_budget_name" {
  description = "Name of the SMID Compass DEV Cost Management budget."
  value       = azurerm_consumption_budget_resource_group.smid_compass_dev.name
}