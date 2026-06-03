# W8 Day 3 — Terraform Advanced

## 1. State Management

### State là gì?
`terraform.tfstate` — file JSON lưu mapping giữa Terraform config và resource thực tế trên cloud.

```
Terraform code  →  Plan  →  Apply  →  tfstate (ghi lại những gì đã tạo)
```

Lần apply tiếp theo, Terraform so sánh code với state để biết cần thêm/sửa/xóa gì.

### Vấn đề với local state (làm việc nhóm)
- Dev A apply → state lưu trên máy A
- Dev B apply → state trên máy B khác → conflict, duplicate resource
- Không có lock → 2 người apply cùng lúc → corrupt state

### Remote Backend: S3 + DynamoDB

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "w8/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true

    # DynamoDB table để lock state khi đang apply
    dynamodb_table = "terraform-state-lock"
  }
}
```

**S3** — lưu state file, versioning để rollback
**DynamoDB** — lock khi 1 người đang apply, ngăn người khác apply đồng thời

### Tạo S3 bucket + DynamoDB cho state backend

```hcl
# Tạo S3 bucket lưu state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table để lock
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## 2. Terraform Modules

### Module là gì?
Tập hợp các resource được đóng gói, tái sử dụng được — giống function trong lập trình.

```
modules/
  vpc/
    main.tf       # tạo VPC, subnet, IGW
    variables.tf  # input: cidr, az list...
    outputs.tf    # output: vpc_id, subnet_ids
  ec2/
    main.tf
    variables.tf
    outputs.tf
```

### Dùng module
```hcl
module "vpc" {
  source = "./modules/vpc"   # local module

  cidr_block = "10.0.0.0/16"
  azs        = ["ap-southeast-1a", "ap-southeast-1b"]
}

module "vpc_public" {
  source  = "terraform-aws-modules/vpc/aws"  # registry module
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Dùng output của module
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_id
}
```

### Module từ Terraform Registry
```hcl
# VPC module phổ biến nhất
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
}
```

---

## 3. Best Practices

### Cấu trúc thư mục production
```
infrastructure/
  environments/
    dev/
      main.tf
      variables.tf
      terraform.tfvars    # dev-specific values
      backend.tf          # remote state config
    staging/
    prod/
  modules/
    vpc/
    eks/
    rds/
```

### Naming convention
```hcl
# Resource: <provider>_<type>_<name>
resource "aws_s3_bucket" "app_logs" {}
resource "aws_security_group" "web_sg" {}

# Variable: snake_case
variable "instance_type" {}
variable "vpc_cidr_block" {}

# Tag mọi resource
locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Owner       = "team-cloud"
  }
}
```

### Các nguyên tắc quan trọng
1. **Không commit** `.tfstate`, `.tfvars` chứa secrets
2. **Pin version** provider: `version = "~> 5.0"` không dùng `version = "latest"`
3. **`terraform plan`** trước mọi `apply`
4. **Dùng workspace** hoặc separate state cho mỗi environment
5. **Review plan output** kỹ trước khi apply — chú ý dấu `-` (destroy)

---

## 4. ADR — Architecture Decision Record

Tài liệu ghi lại **quyết định kiến trúc quan trọng** — tại sao chọn giải pháp A thay vì B.

### Format chuẩn
```markdown
# ADR-001: Sử dụng S3 + DynamoDB làm Terraform remote backend

## Status
Accepted

## Context
Team có 3 người cùng dùng Terraform. Local state gây conflict khi nhiều
người apply cùng lúc.

## Decision
Dùng S3 để lưu state + DynamoDB để lock.

## Consequences
+ Tránh conflict state giữa các thành viên
+ State được version, có thể rollback
+ Cần tạo S3 bucket + DynamoDB trước khi dùng
- Thêm chi phí AWS (nhỏ)
```



