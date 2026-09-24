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
  description = "Azure region for SMID Compass DEV resources."
  default     = "swedencentral"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod)."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Short project identifier used for resource naming and tagging."
  default     = "smid-compass"
}
