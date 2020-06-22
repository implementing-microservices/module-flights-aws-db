provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "db-vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    "Name" = "${var.env_name} db - vpc"
  }
}

resource "aws_iam_group_policy_attachment" "RDS-access-attach" {
  group      = var.tf_group_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_subnet" "rds-subnet-a" {
  vpc_id            = aws_vpc.db-vpc.id
  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "Name" = "${var.env_name}-rds-subnet-a"
  }
}

resource "aws_subnet" "rds-subnet-b" {
  vpc_id            = aws_vpc.db-vpc.id
  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "Name" = "${var.env_name}-rds-subnet-b"
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.env_name}-rds-subnet-group"
  subnet_ids = ["${aws_subnet.rds-subnet-a.id}", "${aws_subnet.rds-subnet-b.id}"]
}

resource "aws_db_instance" "ms-flights-db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "microservices_demo"
  username             = "microservices_demo"
  password             = "microservices_demo_pw"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
}

# Redis Setup
resource "aws_iam_group_policy_attachment" "Redis-access-attach" {
  group      = var.tf_group_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
}

resource "aws_subnet" "redis-subnet-a" {
  vpc_id            = aws_vpc.db-vpc.id
  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[2]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "Name" = "${var.env_name}-redis-subnet-a"
  }
}

resource "aws_subnet" "redis-subnet-b" {
  vpc_id            = aws_vpc.db-vpc.id
  cidr_block        = cidrsubnets(aws_vpc.db-vpc.cidr_block, 4, 4, 4, 4)[3]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "Name" = "${var.env_name}-redis-subnet-b"
  }
}

resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name       = "${var.env_name}-redis-subnet-group"
  subnet_ids = ["${aws_subnet.redis-subnet-a.id}", "${aws_subnet.redis-subnet-b.id}"]
}

resource "aws_elasticache_cluster" "ms_redis" {
  cluster_id           = "ms-reservations-redis"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis-subnet-group.name
}