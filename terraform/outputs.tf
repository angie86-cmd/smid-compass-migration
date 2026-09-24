# Outputs expose selected infrastructure values after deployment.
# They make important resource identifiers easy to reuse in later
# Terraform work, automation, validation, and operational checks.

output "resource_group_name" {
  description = "Name of the SMID Compass DEV resource group."
  value       = azurerm_resource_group.smid_compass_dev.name
}