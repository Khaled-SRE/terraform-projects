/* -------------------------------------------------------------------------- */
env    = "test"
region = "eu-west-1"
/* ------------------------------ VPC Variables ----------------------------- */
vpc_cidr             = "10.0.0.0/16"
vpc_name             = "eks-testt-vpc"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]  
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

/* ------------------------------ EKS Variables ----------------------------- */
cluster_name                         = "platform-test-eks"
cluster_version                      = "1.32"
eks_role_name                        = "eks-role-testt"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

/* ------------------------- EKS-NodeGroup Variables ------------------------ */
node_group_name           = "platform-testt-eks-node-group"
eks_nodes_role_name       = "eks-node-group-rolee"
node_group_min_size       = 1
node_group_desired_size   = 1
node_group_max_size       = 2
node_group_ami_type       = "AL2_x86_64"
node_group_capacity_type  = "ON_DEMAND"
node_group_disk_size      = 50
node_group_instance_types = ["t3.large"]

/* --------------------------- EKS-Addon Variables -------------------------- */
ingress_group_name       = "platform-test-eks"
argocd_domain_name       = "argocd.platform-online.shop"
certificate_arn          = "arn:aws:acm:eu-west-1:767397883134:certificate/c8fdbfe8-a678-4055-8e4e-a48183f105af"
ACM_zone_type            = "public"

/* -------------------------------- Route 53 -------------------------------- */
domain        = "platform-online.shop"

/* -------------------------------------------------------------------------- */
/*                               Security Group                               */
/* -------------------------------------------------------------------------- */

/* --------------------------------- ALB_SG --------------------------------- */
alb_sg_name        = "alb-sgg"
alb_sg_description = "Security group for public ALB"
ALB_ingress_rules = [
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  },
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
]
ALB_egress_rules = [{
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic for external service connections"
  from_port   = 0
  to_port     = 65535
  protocol    = "All"
}]
/* --------------------------------- EKS_SG --------------------------------- */
eks_sg_name        = "eks-sgg"
eks_sg_description = "security group for eks cluster"
eks_ingress_rules = [
  {
    cidr_blocks = ["10.0.0.0/16"]
    description = "all from vpc "
    from_port   = 0
    to_port     = 0
    protocol    = "All"
  },
  {
    cidr_blocks = ["10.0.0.0/8"]
    description = "all from vpn cidr "
    from_port   = 0
    to_port     = 0
    protocol    = "All"
  },
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS access from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
  }
]
eks_egress_rules = [{
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic for external service connections"
  from_port   = 0
  to_port     = 65535
  protocol    = "All"
}]

