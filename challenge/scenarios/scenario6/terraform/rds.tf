#Security Group
resource "aws_security_group" "sc6-rds-security-group" {
  name        = "sc6-rds-psql"
  description = "${var.scenario-name} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.sc6-vpc.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      "10.10.10.0/24",
      "10.10.20.0/24",
      "10.10.30.0/24",
      "10.10.40.0/24"
    ]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.cg_whitelist
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}
# RDS Subnet Group

resource "aws_db_subnet_group" "sc6-rds-subnet-group" {
  name = "sc6-rds-subnet-group"
  subnet_ids = [
    aws_subnet.sc6-private-subnet-1.id,
    aws_subnet.sc6-private-subnet-2.id
  ]
  description = "${var.scenario-name} Subnet Group"
}
resource "aws_db_subnet_group" "sc6-rds-testing-subnet-group" {
  name = "sc6-rds-testing-subnet-group"
  subnet_ids = [
    aws_subnet.sc6-public-subnet-1.id,
    aws_subnet.sc6-public-subnet-2.id
  ]
  description = "${var.scenario-name} Subnet Group ONLY for Testing with Public Subnets"
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "sc6-psql-rds" {
  identifier           = "sc6-rds-instance"
  engine               = "postgres"
  engine_version       = "16.2"
  port                 = "5432"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.sc6-rds-subnet-group.id
  multi_az             = false
  username             = var.rds-username
  password             = var.rds-password
  publicly_accessible  = false
  vpc_security_group_ids = [
    aws_security_group.sc6-rds-security-group.id
  ]
  storage_type        = "gp2"
  allocated_storage   = 20
  db_name             = var.rds-database-name
  apply_immediately   = true
  skip_final_snapshot = true

  tags = {
    Name     = "sc6-rds-instance"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}