locals {
  bucket_prefix   = var.bucket_prefix
  tag_header      = var.tag_header
  private_subnets = var.private_subnets
  efs_sg_id       = var.efs_sg_id

  bucket_types = toset(["website", "logs"])

  website_pages = {
    "index.html" = "<h1>CI/CD learning infrastructure</h1><p>std09 Terraform modules</p>"
    "error.html" = "<h1>404 - Page not found</h1>"
  }
}
