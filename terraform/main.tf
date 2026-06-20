terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ai_governance_lab" {
  name     = "rg-ai-governance-lab"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "ai_governance_sentinel" {
  name                = "law-ai-governance-sentinel"
  location            = azurerm_resource_group.ai_governance_lab.location
  resource_group_name = azurerm_resource_group.ai_governance_lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "ai_governance_sentinel_onboarding" {
  workspace_id = azurerm_log_analytics_workspace.ai_governance_sentinel.id
}

module "sentinel_analytics_rules" {
  source                = "./sentinel"
  sentinel_workspace_id = azurerm_log_analytics_workspace.ai_governance_sentinel.id

  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.ai_governance_sentinel_onboarding]
}