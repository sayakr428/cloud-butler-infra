locals {
  bp = try(jsondecode(var.blueprint_json), {})

  # common tags
  tags = {
    Project   = var.project
    ManagedBy = "n8n"
  }

  # --- EC2 controls (defensive & free-tier friendly) ---
  # blueprint: { "ec2":[{ "count": 1, "type": "t3.micro" }] }
  _ec2_count_raw = try(local.bp.ec2[0].count, 0)
  ec2_count      = max(0, min(tonumber(local._ec2_count_raw), 5))  # clamp 0..5 just to be safe

  ec2_type = try(local.bp.ec2[0].type, "t3.micro") # fallback fits free tier in many regions

  # --- S3 list -> map (name => obj) ---
  # blueprint: { "s3":[{ "name": "my-bucket-123" }, ...] }
  s3_list = try(local.bp.s3, [])
  s3_map  = {
    for b in local.s3_list :
    b.name => b
    if try(b.name, "") != ""
  }
}

# -------- EC2 (uses latest Ubuntu 22.04) --------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*22.04-amd64-server-*"]
  }
}

resource "aws_instance" "ec2" {
  count         = local.ec2_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.ec2_type
  tags          = merge(local.tags, { Name = "${var.project}-ec2-${count.index}" })
}

# -------- S3 (private by default) --------
resource "aws_s3_bucket" "buckets" {
  for_each = local.s3_map
  bucket   = each.key
  tags     = local.tags
}

# strong default privacy
resource "aws_s3_bucket_public_access_block" "this" {
  for_each                = aws_s3_bucket.buckets
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = aws_s3_bucket.buckets
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# -------- Summary output --------
output "summary" {
  value = {
    ec2_count = length(aws_instance.ec2)
    s3_names  = [for _, b in aws_s3_bucket.buckets : b.bucket]
    project   = var.project
    region    = var.aws_region
  }
}
