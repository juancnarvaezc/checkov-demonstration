variable "location" {
  description = "Region de Azure para todos los recursos (floci-az la ignora, pero azurerm la exige)."
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Tamano de la VM. Standard_B1s es el tamano elegible del tier gratuito de Azure."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Usuario administrador de la VM."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Contrasena de la VM (SOLO existe en el estado inseguro de la demo)."
  type        = string
  default     = "Checkov-Demo-2026!x"
  sensitive   = true
}

variable "admin_ssh_key" {
  description = "Clave publica SSH para el estado seguro de la demo (reemplaza a la contrasena)."
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7alzYqgdxu1Pys632FYb/gnF7qMWYTsvhACwp6/1lR checkov-demo-key"
}
