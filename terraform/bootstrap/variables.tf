variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Save My Identity nonprofit tenant. Not a credential; identifies which tenant the provider targets."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the Save My Identity nonprofit tenant. Not a credential; identifies which subscription the provider targets."
}

variable "location" {
  type        = string
  description = "Azure region for the Terraform state backend."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group holding the Terraform state storage account."
  default     = "rg-smid-tfstate"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account used as the Terraform remote state backend."
  default     = "stsmidtfstatea5bc33"
}

variable "container_name" {
  type        = string
  description = "Name of the blob container used to store Terraform state files."
  default     = "tfstate"
}
