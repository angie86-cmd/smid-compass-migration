# Resource Group for the SMID Compass nonprofit DEV environment.
resource "azurerm_resource_group" "smid_compass_dev" {
  name     = "rg-${local.project}-${local.environment}"
  location = var.location

  tags = local.common_tags
}