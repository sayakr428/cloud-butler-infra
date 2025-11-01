locals {
  bp   = try(jsondecode(var.blueprint_json), {})
  tags = {
    Project   = var.project
    ManagedBy = "n8n"
  }

  ec2_count = try(local.bp.ec2[0].count, 0)
  ec2_type  = try(local.bp.ec2[0].type, "t3.micro")
  # S3 list of objects: [{name="bucket-1"}, {name="bucket-2"}]
  s3_list   = try(local.bp.s3, [])
  s3_map    = { for b in local.s3_list : b.name => b if try(b.name, "") != "" }
}

# ---- EC2 (Free Tier) ----
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
  instance_type = local.ec2_type  # keep t3.micro/t2.micro for Free Tier
  tags          = local.tags
}

# ---- S3 ----
resource "aws_s3_bucket" "buckets" {
  for_each = local.s3_map
  bucket   = each.key
  tags     = local.tags
}
