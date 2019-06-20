# Resource Tags
variable "created_by" {
  description = "User who created the resource"
  type        = "string"
}

variable "description" {
  description = "Resource description"
  type        = "string"
  default     = "k8s-cluster"
}

variable "owner" {
  description = "User responsible for management of resource"
  type        = "string"
}

# Cluster specific inputs

variable "cluster_key_pair" {
  description = "Key Pair to access the K8s Cluster Nodes"
  type        = "string"
}

variable "instance_type" {
  description = "Instance Type for K8s Cluster Nodes"
  type        = "string"
  default     = "t2.medium"
}

variable "node_count" {
  description = "Number of worker nodes to be provisioned for the K8s cluster"
  type        = "string"
  default     = "2"
}

variable "cluster_vpc" {
  description = "K8s Cluster VPC"
  type        = "string"
  default     = "vpc-03e762f750919d1d2"
}
