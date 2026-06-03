# W8 Day 1 — Terraform IaC Basics

## 1. IaC Overview

### IaC là gì?
Infrastructure as Code (IaC) là cách quản lý và provision hạ tầng thông qua **code** thay vì thao tác thủ công trên console/CLI.

### Tại sao cần IaC?
| Vấn đề thủ công | Giải pháp IaC |
|---|---|
| Click console → dễ sai, không reproducible | Code → version control, review được |
| Không biết ai tạo gì, khi nào | Git history → audit trail đầy đủ |
| Scale lên 10 env → làm lại 10 lần | Reuse module, chạy 1 lần |
| Drift giữa dev/staging/prod | Declarative → state luôn đồng bộ |

### Các loại IaC tools
- **Declarative** (mô tả trạng thái mong muốn): Terraform, CloudFormation, Pulumi
- **Imperative** (mô tả các bước thực hiện): Ansible, Chef, Puppet

Terraform thuộc loại **declarative** — bạn nói "tôi muốn 3 EC2", Terraform tự tính toán cần làm gì để đạt được đó.

### Terraform vs CloudFormation
| | Terraform | CloudFormation |
|---|---|---|
| Provider | Multi-cloud (AWS, GCP, Azure...) | AWS only |
| Language | HCL | JSON/YAML |
| State | Local file / Remote backend | Managed by AWS |
| Community | Rất lớn, nhiều module | Nhỏ hơn |

---

## 2. HCL Syntax

HCL = HashiCorp Configuration Language. Cú pháp đơn giản, dễ đọc hơn JSON/YAML.

### Cấu trúc block cơ bản
```hcl
<block_type> "<resource_type>" "<local_name>" {
  argument = value
}
```

### Các thành phần chính

#### Provider — khai báo cloud provider
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
```

#### Resource — tài nguyên cần tạo
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server"
    Env  = "dev"
  }
}
```

#### Variable — tham số đầu vào
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Dùng variable
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

#### Output — giá trị đầu ra
```hcl
output "instance_ip" {
  description = "Public IP của EC2"
  value       = aws_instance.web.public_ip
}
```

#### Local — biến nội bộ (tính toán trung gian)
```hcl
locals {
  env    = "dev"
  prefix = "myapp-${local.env}"
}
```

#### Data Source — đọc resource đã tồn tại (không tạo mới)
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}
```

### Kiểu dữ liệu
```hcl
# String
name = "my-app"

# Number
port = 8080

# Bool
enabled = true

# List
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

# Map
tags = {
  Env     = "dev"
  Project = "accelerator"
}

# Object
ingress_rule = {
  port     = 443
  protocol = "tcp"
}
```

### Expressions hay dùng
```hcl
# String interpolation
name = "server-${var.env}-${count.index}"

# Conditional
instance_type = var.env == "prod" ? "t3.medium" : "t2.micro"

# For expression
upper_names = [for name in var.names : upper(name)]

# Count (tạo nhiều resource)
resource "aws_instance" "web" {
  count         = 3
  instance_type = "t2.micro"
}

# For_each (tạo từ map/set)
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs", "assets", "backups"])
  bucket   = "myapp-${each.key}"
}
```

---

## 3. Terraform Workflow

```
Write code → terraform init → terraform plan → terraform apply → terraform destroy
```

### `terraform init`
- Tải provider plugins về `.terraform/`
- Khởi tạo backend (nơi lưu state)
- Chạy **1 lần đầu** hoặc khi thêm provider/module mới

```bash
terraform init
```

### `terraform plan`
- So sánh code với state hiện tại
- Hiển thị những gì sẽ được **tạo (+)**, **sửa (~)**, **xóa (-)**
- Không thay đổi gì thực tế — chỉ preview
- Nên chạy **trước mỗi apply**

```bash
terraform plan
terraform plan -out=tfplan   # lưu plan ra file để apply sau
```

### `terraform apply`
- Thực thi những thay đổi từ plan
- Mặc định hỏi confirm `yes`
- Cập nhật state file sau khi xong

```bash
terraform apply
terraform apply tfplan        # apply từ file plan đã lưu
terraform apply -auto-approve # bỏ qua confirm (dùng trong CI/CD)
```

### `terraform destroy`
- Xóa **toàn bộ** resource được quản lý bởi state
- Hỏi confirm trước khi xóa
- Dùng để teardown môi trường dev/test

```bash
terraform destroy
terraform destroy -auto-approve
```

### Các lệnh hữu ích khác
```bash
terraform fmt          # format code theo chuẩn
terraform validate     # kiểm tra syntax
terraform show         # xem state hiện tại
terraform state list   # liệt kê resource trong state
terraform output       # xem output values
```

---

## 4. State File

`terraform.tfstate` — file JSON lưu trạng thái thực tế của infrastructure.

**Quan trọng:**
- Không commit `terraform.tfstate` lên git (chứa sensitive data)
- Dùng **remote backend** (S3 + DynamoDB) cho team — học ở Day 3
- Nếu state bị mất → Terraform không biết resource nào đang tồn tại

`.gitignore` cần có:
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars        # nếu chứa secrets
```

---

