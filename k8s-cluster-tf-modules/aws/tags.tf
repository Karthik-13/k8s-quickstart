locals {
  tags = {
    CreatedBy   = var.created_by
    Description = var.description
    Owner       = var.created_by
    ManagedBy   = "Terraform"
  }
}
