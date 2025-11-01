variable "project" {
  type    = string
  default = "cloud-butler"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

# n8n will pass a JSON string here like:
# {"ec2":[{"count":1,"type":"t3.micro"}], "s3":[{"name":"chatops-cloud-butler-xyz"}], "vpc": null}
variable "blueprint_json" {
  type    = string
  default = "{}"
}
