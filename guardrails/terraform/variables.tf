variable "order_mgmt_portal_app_id" {
  description = "Object ID of the Order Management Portal app registration in Entra ID"
  type        = string
}

variable "order_mgmt_agent_users_group_id" {
  description = "Object ID of the 'Order Management - Agent Users' Entra ID group"
  type        = string
}

variable "rag_backend_service_principal_id" {
  description = "Object ID of the RAG Customer Service backend service principal"
  type        = string
}

variable "agent_orchestrator_admin_app_id" {
  description = "Object ID of the agent orchestrator admin configuration application"
  type        = string
}

variable "workflow_admins_group_id" {
  description = "Object ID of the PIM-eligible 'Order Management - Workflow Admins' role-assignable group"
  type        = string
}