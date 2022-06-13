variable "controller_name" {
  description = "Name for kubernetes controller nodes"
  type        = string
  default     = "controller"
}

variable "worker_name" {
  description = "Name for kubernetes worker nodes"
  type        = string
  default     = "worker"
}

variable "controller_vm" {
  description = "SKU for controller VMs"
  type        = string
  default     = "Standard_A1_v2"
}

variable "worker_vm" {
  description = "SKU for controller VMs"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "bastion_vm" {
  description = "SKU for bastion host"
  type        = string
  default     = "Standard_B1s"
}

variable "num_controllers" {
  description = "Number of control nodes to be spawned"
  type        = number
  default     = 3
}

variable "num_workers" {
  description = "Number of control nodes to be spawned"
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "Name for an admin user, available over SSH"
  type        = string
  default     = "azureuser"
}
