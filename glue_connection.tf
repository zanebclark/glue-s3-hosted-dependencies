data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

resource "aws_security_group" "default" {
  name_prefix = "${var.environment}-glue-connection-security-group-default"
  description = "Glue Connection Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS Ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Self-Ingress for all ports."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "HTTPS Egress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description     = "S3 HTTPS Egress"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  egress {
    description = "HTTP Egress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Self-egress for all ports."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
}

resource "aws_glue_connection" "default" {
  for_each        = aws_subnet.private_subnets
  name            = "${var.environment}-glue-network-connection-${each.value.id}"
  description     = "Glue Job network connection for subnet: ${each.value.id}"
  connection_type = "NETWORK"

  connection_properties = {}

  physical_connection_requirements {
    availability_zone = each.value.availability_zone
    security_group_id_list = [
      aws_security_group.default.id,
    ]
    subnet_id = each.value.id
  }
}
