# Terraform — Final Project AWS

Khung Terraform cho bài final project AWS được chia làm 2 lớp:

1. `bootstrap/` — tạo S3 backend bucket và DynamoDB locking table.
2. `envs/dev/` — dựng VPC, security groups, EC2, RDS MySQL và S3 static assets bucket.

## Kiến trúc

```
Internet
   │
   ▼
[EC2 - public subnet]  ──────►  [RDS MySQL - private subnet]
   │                                      (port 3306, chỉ EC2 mới vào được)
   │
   ▼
[S3 - static assets]
   (EC2 có IAM role đọc bucket)
```

## Bước 0: Chuẩn bị bootstrap (chạy 1 lần duy nhất)

```bash
cd terraform/bootstrap

terraform init
terraform apply -var="state_bucket_name=mentor-web-demo-tfstate-<account_id>"
```

Ghi lại output `state_bucket_name` và `lock_table_name`.

## Bước 1: Cấu hình env dev

```bash
cd terraform/envs/dev

# 1. Điền tên bucket/table từ bước bootstrap vào backend.tf
#    Sửa 2 dòng: bucket và dynamodb_table

# 2. Tạo tfvars từ template
cp terraform.tfvars.example terraform.tfvars
# Mở terraform.tfvars và điền: admin_cidr, mysql_master_password, s3_assets_bucket_name
```

## Bước 2: Deploy hạ tầng

```bash
cd terraform/envs/dev

terraform init        # lần đầu hoặc sau khi thay đổi backend
terraform plan
terraform apply
```

Sau khi apply xong, lấy output:

```bash
terraform output ec2_public_ip    # IP truy cập web app
terraform output rds_endpoint     # endpoint RDS (nội bộ)
```

## Bước 3: Deploy app lên EC2

Có 2 cách:

**Cách 1 — source_bundle_url** (tự động qua user_data):
Upload file zip source code lên S3, truyền URL vào `source_bundle_url` trong `terraform.tfvars`.

**Cách 2 — upload thủ công** (đơn giản hơn khi học):
```bash
scp -i your-key.pem -r . ec2-user@<ec2_public_ip>:/opt/mentor-web-demo/
ssh -i your-key.pem ec2-user@<ec2_public_ip>
cd /opt/mentor-web-demo && npm install
sudo systemctl restart mentor-web-demo
```

## Biến bắt buộc cần điền trong terraform.tfvars

| Biến | Mô tả |
|------|-------|
| `admin_cidr` | IP của bạn để SSH, vd `1.2.3.4/32` |
| `mysql_master_password` | Password RDS, tối thiểu 8 ký tự |
| `s3_assets_bucket_name` | Tên bucket globally unique |

## Dọn dẹp

```bash
cd terraform/envs/dev && terraform destroy
cd terraform/bootstrap && terraform destroy -var="force_destroy_state_bucket=true" -var="state_bucket_name=<tên bucket>"
```

## Biến môi trường app (được user_data inject tự động)

- `APP_NAME`, `PORT`
- `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`
- `S3_BUCKET_NAME`
