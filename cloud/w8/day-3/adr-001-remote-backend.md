# ADR-001: Sử dụng S3 + DynamoDB làm Terraform Remote Backend

## Status
Accepted

## Context
Team Cloud Accelerator có nhiều người cùng dùng Terraform.
Local state (`terraform.tfstate`) gây conflict khi nhiều người apply đồng thời,
không có audit trail, và dễ mất dữ liệu.

## Decision
Dùng **AWS S3** để lưu state file + **DynamoDB** để lock state khi đang apply.

## Consequences

**Tích cực:**
- Tránh conflict state giữa các thành viên trong team
- S3 versioning cho phép rollback state về version trước
- DynamoDB lock ngăn 2 người apply cùng lúc
- State được encrypt at rest (AES256)
- Audit trail qua S3 access logs

**Tiêu cực:**
- Cần tạo S3 bucket + DynamoDB trước khi dùng (bootstrap step)
- Thêm chi phí AWS nhỏ (~$0 cho DynamoDB PAY_PER_REQUEST ít dùng)
- Cần AWS credentials có quyền S3 + DynamoDB
