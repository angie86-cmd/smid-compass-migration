# Resource Group: the deployment boundary for every DEV resource in this
# workload. Scoping RBAC, budgets, and lifecycle to this single group
# keeps DEV cleanly separable from a future PROD resource group without
# any resource-level tagging conventions to enforce.
resource "azurerm_resource_group" "smid_compass_dev" {
  name     = "rg-${local.project}-${local.environment}"
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace: a migration improvement, not a source-parity
# item. It is a new instance introduced for this nonprofit DEV
# environment as the central observability workspace (agent execution
# logs, failures, latency) — it is not a clone of the source tenant's own
# separate Log Analytics workspace (see source/inventory/source-environment.json).
# PerGB2018 is the standard pay-as-you-go SKU.
resource "azurerm_log_analytics_workspace" "smid_compass_dev" {
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.smid_compass_dev.name
  location            = azurerm_resource_group.smid_compass_dev.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = local.common_tags
}

# Application Insights: also a migration improvement (new instance, not a
# clone of the source tenant's own Application Insights). Provides
# application-level telemetry — requests, failures, dependencies, traces,
# performance — and is connected to the Log Analytics Workspace above
# (workspace-based mode, the current supported configuration) so both
# feed the same centralized observability store.
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

  # kind and sku_name are source parity: the source Foundry resource is
  # also kind = "AIServices" on the S0 tier (source/azure/foundry-resource.raw.json).
  kind     = "AIServices"
  sku_name = "S0"

  # A custom subdomain is required for Foundry's AI-services-style
  # endpoints (as opposed to the default regional endpoint) and must be
  # globally unique — hence the uniqueness suffix in
  # local.foundry_resource_name (see locals.tf). project_management_enabled
  # is what allows the Foundry project resource below to exist under this
  # account at all.
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

# Microsoft Foundry project: a child resource of the Foundry account
# above. Terraform infers the create/destroy dependency automatically
# through the cognitive_account_id reference — no explicit depends_on is
# needed. The identity block is required by this resource type in
# AzureRM 4.81.0 (not merely optional, unlike on azurerm_cognitive_account);
# this project's own managed identity is what the RBAC assignment further
# below grants least-privilege Foundry access to, rather than granting
# broader access at the parent account level.
resource "azurerm_cognitive_account_project" "smid_compass_dev" {
  name                 = local.foundry_project_name
  cognitive_account_id = azurerm_cognitive_account.smid_compass_dev.id
  location             = azurerm_cognitive_account.smid_compass_dev.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# SMID-Guardrails-Policy: source-parity content-safety (RAI) policy.
# Preserves source/guardrails/SMID-Guardrails-Policy.json exactly — see
# terraform/README.md for the full source -> Terraform field mapping,
# including the one field with no direct source equivalent (base_policy_name)
# and the one unverified value (the Jailbreak filter's severity_threshold).
# This is a required prerequisite for agent restoration: five of the six
# target agents reference this policy's ARM ID via their rai_config
# (see target/migration/agents/*.manifest.json) and cannot be created
# until it exists.
#
# Deliberately NOT associated with any agent here. Agent<->policy
# association happens later, at the Foundry application layer (agent
# manifests), not in Terraform — because OutOfScopeAgent's asymmetry (the
# one agent source did NOT associate with this policy) must be preserved
# by that later step, not decided by this infrastructure resource.
resource "azurerm_cognitive_account_rai_policy" "smid_guardrails" {
  name                 = "SMID-Guardrails-Policy"
  cognitive_account_id = azurerm_cognitive_account.smid_compass_dev.id

  # No source value maps to base_policy_name (source/guardrails/*.json is a
  # normalized summary, not a raw ARM export, and has no such field).
  # "Microsoft.Default" is used as the conventional base every custom RAI
  # policy builds on top of; the content_filter overrides below are what
  # actually encodes source behavior.
  base_policy_name = "Microsoft.Default"

  # Hate / SelfHarm / Sexual / Violence: source content_safety sets
  # level = "highest_blocking" with intervention_points = [user_input, output]
  # identically for all four categories. Terraform requires one
  # content_filter block per (category, source) pair; severity_threshold
  # = "High" is the deterministic mapping of "highest_blocking", and
  # source = "Prompt"/"Completion" maps to intervention_points
  # "user_input"/"output" respectively.
  content_filter {
    name               = "Hate"
    source             = "Prompt"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "Hate"
    source             = "Completion"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "SelfHarm"
    source             = "Prompt"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "SelfHarm"
    source             = "Completion"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "Sexual"
    source             = "Prompt"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "Sexual"
    source             = "Completion"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "Violence"
    source             = "Prompt"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }
  content_filter {
    name               = "Violence"
    source             = "Completion"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "High"
  }

  # Jailbreak: source jailbreak block covers only intervention_point =
  # user_input (no "output" entry, unlike the four categories above), so
  # only a single Prompt-side filter is defined here — no Completion-side
  # counterpart, matching source exactly.
  #
  # UNVERIFIED (flagged, not silently guessed): jailbreak/prompt-injection
  # detection in Azure OpenAI content filters is normally binary rather
  # than severity-graded, so there's no direct equivalent of source's
  # "highest_blocking" wording for this category. severity_threshold =
  # "Low" is used here to catch all detections (the most inclusive
  # threshold), but this specific value was not confirmed against a live
  # policy or authoritative schema this session. Verify before apply.
  content_filter {
    name               = "Jailbreak"
    source             = "Prompt"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
  }

  tags = local.common_tags
}

# Current authenticated principal (subscription Owner, but that is a
# management-plane role; Foundry data-plane/development access such as
# agent import still requires this explicit assignment). Data source is
# also used below for the current subscription context.
data "azurerm_client_config" "current" {}

# Model deployment: gpt-4.1-mini. Preserves source parity exactly
# (source/azure/deployments/gpt-4.1-mini.raw.json): OpenAI format,
# version 2025-04-14, GlobalStandard SKU, capacity 50,
# Microsoft.DefaultV2 RAI policy, OnceNewDefaultVersionAvailable upgrade
# option. Capacity is intentionally not optimized during migration; that
# is a Modernization v2 decision.
resource "azurerm_cognitive_deployment" "gpt_4_1_mini" {
  name                 = "gpt-4.1-mini"
  cognitive_account_id = azurerm_cognitive_account.smid_compass_dev.id

  model {
    format  = "OpenAI"
    name    = "gpt-4.1-mini"
    version = "2025-04-14"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 50
  }

  rai_policy_name        = "Microsoft.DefaultV2"
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

# Model deployment: text-embedding-3-small. Preserves source parity
# exactly (source/azure/deployments/text-embedding-3-small.raw.json).
resource "azurerm_cognitive_deployment" "text_embedding_3_small" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = azurerm_cognitive_account.smid_compass_dev.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 120
  }

  rai_policy_name        = "Microsoft.DefaultV2"
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

# Minimum Foundry RBAC for the next application-layer migration step
# (agent import, knowledge upload). "Foundry User" is referenced by its
# stable role definition ID rather than its display name, since Microsoft
# Foundry role names are currently undergoing a rename rollout. This is
# deliberately narrower than Owner/Contributor/Foundry Owner: the signed-in
# user already has subscription Owner for management operations, so this
# assignment is only for Foundry data-plane/development access.
resource "azurerm_role_assignment" "foundry_user_current" {
  scope              = azurerm_cognitive_account.smid_compass_dev.id
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  principal_id       = data.azurerm_client_config.current.object_id
}

# Same "Foundry User" role for the Foundry project's own system-assigned
# managed identity, so the project can access the parent Foundry resource
# during the next migration step. principal_type is set explicitly
# because this principal is a managed identity (a ServicePrincipal in
# Microsoft Entra ID), and skip_service_principal_aad_check avoids a race
# with Entra ID replication, since this identity is created earlier in
# the same apply as this role assignment. No additional role is granted
# to the Foundry resource's own managed identity; none is required yet.
resource "azurerm_role_assignment" "foundry_user_project_identity" {
  scope                            = azurerm_cognitive_account.smid_compass_dev.id
  role_definition_id               = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  principal_id                     = azurerm_cognitive_account_project.smid_compass_dev.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# DEV Cost Management budget for rg-smid-compass-dev, scoped to actual
# (not forecasted) cost. This provides cost monitoring and email
# notifications only — it does NOT stop resources or impose a hard
# spending cap. monthly_budget_amount and budget_start_date have no
# defaults and must be supplied (e.g. via dev.tfvars) before
# `terraform plan`. Notifications use direct email rather than an Action
# Group; the automatically created "Application Insights Smart Detection"
# Action Group is unrelated to cost governance and is not reused here.
resource "azurerm_consumption_budget_resource_group" "smid_compass_dev" {
  name              = local.budget_name
  resource_group_id = azurerm_resource_group.smid_compass_dev.id

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 50
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 80
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }
}