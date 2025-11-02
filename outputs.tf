output "summary" {
  value = {
    ec2_count = length(aws_instance.ec2)
    s3_names  = [for _, b in aws_s3_bucket.buckets : b.bucket]
    project   = var.project
    region    = var.aws_region
  }
}
