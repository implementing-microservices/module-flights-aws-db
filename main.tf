provider "aws" {
  region = var.aws_region
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
}

resource "aws_elasticache_cluster" "ms_redis" {
  cluster_id           = "ms-reservations-redis"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
}