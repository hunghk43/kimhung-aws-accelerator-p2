# CDO Mentor Web — AWS Accelerator W8 Lab

**Live:** https://d3b56maeq7bcmh.cloudfront.net/

> Web demo tối giản phục vụ bài tập Terraform AWS của mentor Minh — W8 Cloud/DevOps Accelerator.

---

## Kiến trúc

```
User
 │
 ▼
CloudFront (CDN + HTTPS)
 │
 ▼
S3 Static Website  ←── HTML / CSS / JS
 │
 ▼
EC2 (Node.js API) ── Public Subnet
 │
 ▼
RDS MySQL ── Private Subnet
```

## Tech Stack

| Layer | Service |
|---|---|
| CDN | AWS CloudFront |
| Static assets | AWS S3 |
| App server | EC2 + Node.js |
| Database | RDS MySQL |
| IaC | Terraform (S3 backend + DynamoDB lock) |

## Mục tiêu lab

- EC2 chạy trong public subnet, RDS MySQL trong private subnet
- Security group chỉ mở đúng port cần thiết
- S3 bucket cho static assets
- Terraform state lưu ở S3 + DynamoDB locking
- CloudFront phân phối nội dung qua HTTPS

## Chạy local

```bash
npm install
npm run dev
```

Mở `http://127.0.0.1:8000`

## Biến môi trường (khi deploy lên EC2)

| Biến | Mô tả |
|---|---|
| `MYSQL_HOST` | RDS endpoint |
| `MYSQL_USER` | DB username |
| `MYSQL_PASSWORD` | DB password |
| `MYSQL_DATABASE` | Tên database |
| `MYSQL_PORT` | Cổng MySQL (mặc định 3306) |
| `S3_BUCKET_NAME` | Tên S3 bucket static assets |
| `APP_NAME` | Tên hiển thị trên giao diện |
| `PORT` | Cổng app trên EC2 |

## Terraform roadmap

1. VPC module — public + private subnets
2. Security groups — EC2 và RDS
3. EC2 trong public subnet — deploy Node app
4. RDS MySQL trong private subnet
5. S3 backend + DynamoDB state lock
6. Inject env vars qua EC2 user data hoặc SSM Parameter Store
7. CloudFront distribution trỏ vào S3/EC2

