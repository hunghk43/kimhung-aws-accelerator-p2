# Remote Backend Configuration
# Chạy sau khi đã tạo S3 bucket + DynamoDB bằng Terraform

terraform {
  backend "s3" {
    bucket         = "accelerator-terraform-state"   # đổi thành bucket name thực tế
    key            = "w8/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
