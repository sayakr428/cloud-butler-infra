output "summary" {
  value = {
    region    = var.aws_region
    project   = var.project
    ec2_count = local.ec2_count
    s3_names  = keys(aws_s3_bucket.buckets)
  }
}
