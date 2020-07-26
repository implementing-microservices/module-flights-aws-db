provider "aws" {
  region = var.aws_region
}

# Policy attachment to allow creation and editing of RDS resource objects
resource "aws_iam_group_policy_attachment" "RDS-access-attach" {
  group      = var.tf_group_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
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

  ingress {
    description = "All traffic from managed EKS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.eks_security_group_id]
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
  
  username             = var.mysql_user
  password             = var.mysql_password
  parameter_group_name = "default.mysql5.7"
  
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.db-security-group.id]
}

# Redis Setup
#resource "aws_iam_group_policy_attachment" "Redis-access-attach" {
#  group      = var.tf_group_name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
#}

#resource "aws_subnet" "redis-subnet-a" {
#  vpc_id            = aws_vpc.db-vpc.id
#  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[2]
#  availability_zone = data.aws_availability_zones.available.names[0]#
#
#  tags = {
#    "Name" = "${var.env_name}-redis-subnet-a"
#  }
#}

#resource "aws_subnet" "redis-subnet-b" {
#  vpc_id            = aws_vpc.db-vpc.id
#  availability_zone = data.aws_availability_zones.available.names[1]
##  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[3]

#  tags = {
#    "Name" = "${var.env_name}-redis-subnet-b"
#  }
#}

#resource "aws_elasticache_subnet_group" "redis-subnet-group" {
#  name       = "${var.env_name}-redis-subnet-group"
#  subnet_ids = ["${aws_subnet.redis-subnet-a.id}", "${aws_subnet.redis-subnet-b.id}"]
#}

#resource "aws_elasticache_cluster" "ms_redis" {
#  cluster_id           = "ms-reservations-redis"
#  engine               = "redis"
#  node_type            = "cache.m4.large"
#  num_cache_nodes      = 1
#  parameter_group_name = "default.redis3.2"
#  engine_version       = "3.2.10"
#  port                 = 6379
#  subnet_group_name    = aws_elasticache_subnet_group.redis-subnet-group.name
#}