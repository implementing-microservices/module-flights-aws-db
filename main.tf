provider "aws" {
  region = var.aws_region
}

# Lookup the EKS cluster that we created for the Microservices
data "aws_eks_cluster" "microservice-cluster" {
  name = "${var.eks_id}"
}

# The RDS subnet group that points to the subnets we've declared above
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.env_name}-rds-subnet-group"
  subnet_ids = ["${var.subnet_a_id}", "${var.subnet_b_id}"]
}

# Create a security group to allow traffic from the EKS cluster
resource "aws_security_group" "db-security-group" {
  name = "${var.env_name}-allow-eks-db"
  description = "Allow traffic from EKS managed workloads"
  vpc_id = var.vpc_id

  ingress {
    description = "All traffic from managed EKS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = data.aws_eks_cluster.microservice-cluster.vpc_config.0.security_group_ids
  }
}

# Our RDS database instance
resource "aws_db_instance" "mysql-db" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  name              = var.mysql_database
  identifier = "microservices-mysql"
  
  username             = var.mysql_user
  password             = var.mysql_password
  parameter_group_name = "default.mysql5.7"

  skip_final_snapshot  = true
  
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.db-security-group.id]
}

# Elasticache subnet group
resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name       = "${var.env_name}-elasticache-subnet-group"
  subnet_ids = ["${var.subnet_a_id}", "${var.subnet_b_id}"]
}

resource "aws_elasticache_cluster" "redis-db" {
  cluster_id           = "microservices-redis"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.redis-subnet-group.name
  security_group_ids   = [aws_security_group.db-security-group.id]
}