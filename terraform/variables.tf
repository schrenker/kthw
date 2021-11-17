variable "controller_name" {
  description = "Name for kubernetes controller nodes"
  type        = string
  default     = "KController"
}


variable "worker_name" {
  description = "Name for kubernetes worker nodes"
  type        = string
  default     = "KWorker"
}
