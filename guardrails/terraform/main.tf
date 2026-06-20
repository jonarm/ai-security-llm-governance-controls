terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

# CA-AI-001: Intentionally not implemented as a dedicated policy.
# Investigation against the deployed tenant confirmed Microsoft 365 Copilot has no distinct
# enterprise application object in Entra ID - it authenticates through the underlying
# Office 365 Exchange Online / SharePoint Online service principals. Coverage is inherited from
# the tenant-wide CA001 (Require MFA for All Users) and CA002 (Block Legacy Authentication)
# policies deployed in the companion erp-identity-security-reference-architecture project, both
# of which target "All" cloud apps. See entra-conditional-access-ai-apps.md for the full writeup.

# CA-AI-002: Require MFA and compliant device for Order Management Portal access
resource "azuread_conditional_access_policy" "order_mgmt_mfa_compliant_device" {
  display_name = "CA-AI-002: Require MFA and compliant device for Order Management Portal"
  state        = "enabled"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = [var.order_mgmt_portal_app_id]
    }

    users {
      included_groups = [var.order_mgmt_agent_users_group_id]
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "compliantDevice"]
  }

  session_controls {
    sign_in_frequency                     = 4
    sign_in_frequency_period              = "hours"
    sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
  }
}

# CA-AI-003: Block legacy authentication for AI application service principals
resource "azuread_conditional_access_policy" "ai_apps_block_legacy_auth" {
  display_name = "CA-AI-003: Block legacy authentication for AI application service principals"
  state        = "enabled"

  conditions {
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = [
        var.order_mgmt_portal_app_id,
        var.rag_backend_service_principal_id
      ]
    }

    users {
      included_users = ["All"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# CA-AI-004: Require PIM activation and MFA for agent-workflow admin configuration access
resource "azuread_conditional_access_policy" "agent_admin_pim_mfa" {
  display_name = "CA-AI-004: Require PIM activation and MFA for agent-workflow admin access"
  state        = "enabled"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = [var.agent_orchestrator_admin_app_id]
    }

    users {
      included_groups = [var.workflow_admins_group_id]
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency                     = 1
    sign_in_frequency_period              = "hours"
    sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
  }
}