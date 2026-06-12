resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "s3_assets" {
  name = "${var.name_prefix}-ec2-s3-assets"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStaticAssets"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  key_name                    = var.key_name
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    app_name          = var.app_name
    app_port          = var.app_port
    mysql_host        = var.mysql_host
    mysql_port        = var.mysql_port
    mysql_database    = var.mysql_database
    mysql_user        = var.mysql_user
    mysql_password    = var.mysql_password
    s3_bucket_name    = var.s3_bucket_name
    source_bundle_url = var.source_bundle_url != null ? var.source_bundle_url : ""
    service_name      = var.service_name
  })

  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web"
    Role = "ec2-web"
  })
}
