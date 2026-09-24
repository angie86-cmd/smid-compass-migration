# Outputs expose non-sensitive identifiers used for backend configuration,
# operational verification, and RBAC troubleshooting. No storage keys or
# connection strings are output; data-plane access uses Microsoft Entra ID.

output "resource_group_name" {
  description = "Name of the resource group holding the Terraform state storage account."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Name of the storage account used as the Terraform remote state backend."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the blob container used to store Terraform state files."
  value       = azurerm_storage_container.tfstate.name
}

output "storage_container_id" {
  description = "ARM resource ID of the tfstate blob container."
  value       = azurerm_storage_container.tfstate.id
}

output "current_principal_object_id" {
  description = "Object ID of the principal that ran this bootstrap configuration."
  value       = data.azurerm_client_config.current.object_id
}
