#Security Group
resource "aws_security_group" "sc5-rds-security-group" {
  name        = "sc5-rds-psql"
  description = "${var.scenario-name} Security Group for PostgreSQL RDS Instance"
  vpc_id      = aws_vpc.sc5-vpc.id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.10.0/24",
      "10.0.20.0/24",
      "10.0.30.0/24",
      "10.0.40.0/24"
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name     = "sc5-rds-psql"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
#RDS Subnet Group
resource "aws_db_subnet_group" "sc5-rds-subnet-group" {
  name = "sc5-rds-subnet-group"
  subnet_ids = [
    aws_subnet.sc5-private-subnet-1.id,
    aws_subnet.sc5-private-subnet-2.id
  ]
  description = "${var.scenario-name} Subnet Group"
  tags = {
    Name     = "${var.scenario-name}-rds-subnet-group"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}
#RDS PostgreSQL Instance
resource "aws_db_instance" "sc5-psql-rds" {
  identifier           = "sc5-rds-instance"
  engine               = "postgres"
  engine_version       = "16.2"
  port                 = "5432"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.sc5-rds-subnet-group.id
  multi_az             = false
  username             = var.rds-username
  password             = var.rds-password
  publicly_accessible  = false
  vpc_security_group_ids = [
    aws_security_group.sc5-rds-security-group.id
  ]
  storage_type        = "gp3"
  allocated_storage   = 20
  db_name             = var.rds-database-name
  apply_immediately   = true
  skip_final_snapshot = true

  tags = {
    Name     = "sc5-rds-instance"
    Stack    = var.stack-name
    Scenario = var.scenario-name
  }
}