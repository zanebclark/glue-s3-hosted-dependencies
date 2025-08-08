# TODO: Remove file for deploy
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "private_subnets" {
  for_each          = { for idx, subnet in var.private_subnet_cidrs : idx => subnet }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key]
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid = "Access-to-specific-bucket-only"

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    actions = ["s3:*"]

    effect = "Allow"

    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "gateway_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.main.main_route_table_id]
  policy            = data.aws_iam_policy_document.s3_access.json
}

resource "aws_security_group" "batch" {
  name   = "aws-use1-dev-sg-batch-env-0001"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ecr-dkr-endpoint" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "ecr-api-endpoint" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "ecs-agent" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "ecs-telemetry" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}


resource "aws_vpc_endpoint" "batch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.batch"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}


resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}


resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}


resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "glue" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.glue"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.batch.id]
  subnet_ids          = values(aws_subnet.private_subnets)[*].id
}
