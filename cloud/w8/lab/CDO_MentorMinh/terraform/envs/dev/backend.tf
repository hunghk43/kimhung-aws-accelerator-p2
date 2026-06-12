terraform {
  backend "s3" {
    bucket         = "mentor-web-demo-tfstate-013187861815"  # output của bước bootstrap
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "mentor-web-demo-tf-locks"        # output của bước bootstrap
    encrypt        = true
  }
}
