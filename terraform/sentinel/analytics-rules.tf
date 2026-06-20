resource "azurerm_sentinel_alert_rule_scheduled" "shadow_ai_detection" {
  name                       = "shadow-ai-detection"
  log_analytics_workspace_id = var.sentinel_workspace_id
  display_name               = "Shadow AI Detection"
  severity                   = "Medium"
  query                      = file("${path.module}/../../sentinel/kql-shadow-ai-detection.kql")
  query_frequency            = "P1D"
  query_period               = "P7D"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  enabled                    = true

  tactics = ["Exfiltration"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled                 = true
      lookback_duration       = "P1D"
      reopen_closed_incidents = false
      entity_matching_method  = "Selected"
      group_by_entities       = ["Account"]
    }
  }
}

resource "azurerm_sentinel_alert_rule_scheduled" "anomalous_copilot_access" {
  name                       = "anomalous-copilot-data-access"
  log_analytics_workspace_id = var.sentinel_workspace_id
  display_name               = "Anomalous Copilot Data Access"
  severity                   = "Medium"
  query                      = file("${path.module}/../../sentinel/kql-anomalous-copilot-data-access.kql")
  query_frequency            = "P1D"
  query_period               = "P1D"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  enabled                    = true

  tactics = ["Collection", "Exfiltration"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled                 = true
      lookback_duration       = "P1D"
      reopen_closed_incidents = false
      entity_matching_method  = "Selected"
      group_by_entities       = ["Account"]
    }
  }
}