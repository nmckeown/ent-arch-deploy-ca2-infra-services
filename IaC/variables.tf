variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "North Europe"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "eadca2aksrg"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
  default     = "EADCA2AKS"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the default node pool"
  default     = 2
}

variable "vm_size" {
  type        = string
  description = "Size of the VMs in the node pool"
  default     = "Standard_B2s"
}

variable "ssh_public_key" {
  type        = string
  description = "Path to the SSH public key file"
  default     = ".ssh/id_rsa.pub"
}

variable "allowed_ssh_ip" {
  type        = string
  description = "IP address allowed for SSH access"
  default     = "86.45.172.213"
}