terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

# CA-AI-001: Require compliant device for Copilot access
resource "azuread_conditional_access_policy" "copilot_compliant_device" {
  display_name = "CA-AI-001: Require compliant device for Copilot access"
  state         = "enabled"

  conditions {
    client_app_types    = ["all"]
    sign_in_risk_levels  = []
    user_risk_levels     = []

    applications {
      included_applications = [var.copilot_app_id]
    }

    users {
      included_groups = [var.copilot_licensed_users_group_id]
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["compliantDevice"]
  }
}

# CA-AI-002: Require MFA and compliant device for Order Management Portal access
resource "azuread_conditional_access_policy" "order_mgmt_mfa_compliant_device" {
  display_name = "CA-AI-002: Require MFA and compliant device for Order Management Portal"
  state         = "enabled"

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
    sign_in_frequency               = 4
    sign_in_frequency_period         = "hours"
    sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
  }
}

# CA-AI-003: Block legacy authentication for AI application service principals
resource "azuread_conditional_access_policy" "ai_apps_block_legacy_auth" {
  display_name = "CA-AI-003: Block legacy authentication for AI application service principals"
  state         = "enabled"

  conditions {
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = [
        var.copilot_app_id,
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
  state         = "enabled"

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