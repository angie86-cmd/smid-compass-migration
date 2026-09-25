# Configuration interface for the SMID Compass DEV root module. Grouped
# conceptually below: Azure target context, environment/project naming,
# and cost governance. Values are supplied via dev.tfvars (git-ignored;
# see dev.tfvars.example), never hard-coded here.

# --- Azure target context ---------------------------------------------
# Identifies which Azure tenant/subscription/region this configuration
# targets. These are identifiers, not credentials, and have no defaults
# for tenant_id/subscription_id so a plan can never silently fall back to
# the wrong tenant.

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Save My Identity nonprofit tenant. Not a credential; identifies which tenant the provider targets. No default: must be supplied explicitly."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the Save My Identity nonprofit tenant. Not a credential; identifies which subscription the provider targets. No default: must be supplied explicitly."
}

variable "location" {
  type        = string
  description = "Azure region for SMID Compass DEV resources. Configuration value; defaults to the approved DEV region (swedencentral) and normally does not need to be overridden."
  default     = "swedencentral"
}

# --- Environment / project naming ---------------------------------------
# Drive the deterministic resource naming in locals.tf (e.g.
# rg-<project>-<environment>). Both have defaults appropriate for this
# DEV workload and typically only change when reusing this configuration
# for another environment (e.g. prod) or project.

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod). Configuration value used for resource naming/tagging."
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Short project identifier used for resource naming and tagging. Configuration value; kept as \"smid-compass\" for source-name parity with the private tenant's Foundry project."
  default     = "smid-compass"
}

# --- Cost governance ------------------------------------------------------
# Configure the DEV budget/alerts in main.tf. These are migration
# improvements with no source-tenant equivalent, so none of them can be
# derived from frozen source data — they require manual, per-environment
# input and review before every plan.

variable "monthly_budget_amount" {
  type        = number
  description = "Monthly DEV cost budget amount in the Azure billing currency. No default is intentional: Terraform must not invent or assume an approved budget figure. Requires manual review before every `terraform plan`."
}

variable "budget_start_date" {
  type        = string
  description = "Budget start date, in the format YYYY-MM-DDTHH:mm:ssZ. Azure Cost Management requires this to be the first day of the budget period. No default is intentional: the budget lifecycle is environment-specific and must be supplied manually rather than assumed."
}

variable "budget_alert_email" {
  type        = string
  description = "Email address that receives DEV budget threshold notifications. Configuration value; defaults to the nonprofit cloud administrator address."
  default     = "cloud_smid@savemyidentityorg.onmicrosoft.com"
}
