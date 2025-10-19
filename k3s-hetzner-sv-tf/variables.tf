variable "cloud_token" {
  sensitive = true
}

variable "server_name" {
  default     = "k3s-master"
}

variable "server_type" {
  default     = "cx23"
}

variable "server_location" {
  default   = "nbg1"
}

variable "server_image" {
  default   = "ubuntu-24.04"
}