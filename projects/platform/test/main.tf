data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}
/* ----------------------------------- VPC ---------------------------------- */
module "vpc" {
  source                                          = "git::https://github.com/Khaled-SRE/terraform-modules.git//Network/VPC?ref=v1.0.0"
  vpc_cidr                                        = var.vpc_cidr
  vpc_name                                        = var.vpc_name
  private_subnet_cidrs                            = var.private_subnet_cidrs
  public_subnet_cidrs                             = var.public_subnet_cidrs
  availability_zones                              = var.availability_zones
}

/* -------------------------------------------------------------------------- */
/*                               Security Groups                              */
/* -------------------------------------------------------------------------- */

/* --------------------------------- Alb SG --------------------------------- */
module "sg_alb" {
  source              = "git::https://github.com/Khaled-SRE/terraform-modules.git//Security_Group?ref=v1.0.0"
  security_group_name = var.alb_sg_name
  vpc_id              = module.vpc.vpc_id
  description         = "Security group for ALB"
  ingress_rules       = var.ALB_ingress_rules
  egress_rules        = var.ALB_egress_rules
  ingress_rules_with_source_security_group_ids = [
    {
      source_security_group_id = module.eks.eks_security_group_id
      description              = "all trafic from alb sg "
      from_port                = 0
      to_port                  = 0
      protocol                 = "All"
    }
  ]
}

/* --------------------------------- EKS SG --------------------------------- */
module "sg_eks" {
  source              = "git::https://github.com/Khaled-SRE/terraform-modules.git//Security_Group?ref=v1.0.0"
  security_group_name = var.eks_sg_name
  vpc_id              = module.vpc.vpc_id
  description         = "Security group for EKS"
  ingress_rules       = var.eks_ingress_rules
  egress_rules        = var.eks_egress_rules
  ingress_rules_with_source_security_group_ids = [
    {
      source_security_group_id = module.sg_alb.security_group_id
      description              = "all trafic from alb sg "
      from_port                = 0
      to_port                  = 0
      protocol                 = "All"
    }
  ]
}

/* ----------------------------------- EKS ---------------------------------- */
module "eks" {
  source                               = "git::https://github.com/Khaled-SRE/terraform-modules.git//EKS?ref=v1.0.0"
  env                                  = var.env
  infrastructure_region                = var.region
  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  eks_role_name                        = var.eks_role_name
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  subnets_id_list = concat(
    [for subnet in module.vpc.private_subnet_ids : subnet]
  )
  esk_security_group_ids = [module.sg_eks.security_group_id]
}

/* ------------------------------ EKS-NodeGroup ----------------------------- */
module "eks-nodegroup" {
  source                    = "git::https://github.com/Khaled-SRE/terraform-modules.git//EKS_Nodegroup?ref=v1.0.0"
  env                       = var.env
  cluster_name              = var.cluster_name
  eks_cluster_arn           = module.eks.eks_cluster_arn
  node_group_name           = var.node_group_name
  node_group_version        = var.cluster_version
  node_group_min_size       = var.node_group_min_size
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_group_capacity_type  = var.node_group_capacity_type
  node_group_disk_size      = var.node_group_disk_size
  node_group_instance_types = var.node_group_instance_types
  use_taint                 = var.use_taint
  node_group_subnets        = [for subnet in module.vpc.private_subnet_ids : subnet]
  node_group_role           = var.node_group_name
  node_group_ami_type       = var.node_group_ami_type
  eks_nodes_role_name       = var.eks_nodes_role_name
}

/* ------------------------------- Route 53 ------------------------------ */
module "route53_hostedzone" {
  source       = "git::https://github.com/Khaled-SRE/terraform-modules.git//Route53?ref=v1.0.0"
  domain       = var.domain
  cluster_name = var.cluster_name
}

/* ------------------------------- ECR ------------------------------ */
module "microservices_product" {
  source = "git::https://github.com/Khaled-SRE/terraform-modules.git//ECR?ref=v1.0.0"
  ecr_name = "microservices-product"
  tags = {
    Environment = "test"
    Component   = "microservices-product"
  }
}

module "microservices_user" {
  source = "git::https://github.com/Khaled-SRE/terraform-modules.git//ECR?ref=v1.0.0"
  ecr_name = "microservices-user"
  tags = {
    Environment = "test"
    Component   = "microservices-user"
  }
}

/* ------------------------------- ACM ------------------------------ */
/*
module "acm" {
  source                = "git::https://github.com/Khaled-SRE/terraform-modules.git//ACM?ref=v1.0.0"
  acm_domain_name       = var.domain
  hosted_zone_id        = module.route53_hostedzone.zone_id
}
*/
/* ------------------------------- EKS-Addons ------------------------------- */

/* ---------------------- ALB Ingress Addon -----------------------*/
module "alb_ingress_addon" {
  source                              = "git::https://github.com/Khaled-SRE/terraform-modules.git//EKS_Addons/ALB_Ingress?ref=v1.0.0"
  eks_alb_role_arn                    = module.eks.eks_alb_role_arn  
  cluster_name                        = var.cluster_name
  addon_depends_on_nodegroup_no_taint = module.eks-nodegroup.node_group_without_taint_arn
  depends_on                          = [module.eks-nodegroup]
}

/* ------------------------ Argocd Add-on ----------------------- */

module "argo_cd_addon" {
  source                     = "git::https://github.com/Khaled-SRE/terraform-modules.git//EKS_Addons/Argo_Cd?ref=v1.0.0"
  ingress_group_name         = var.ingress_group_name
  argocd_domain_name         = var.argocd_domain_name
  certificate_arn            = var.certificate_arn
  subnet_ids                 = [module.vpc.public_subnet_ids[0], module.vpc.public_subnet_ids[1], module.vpc.public_subnet_ids[2]]
  security_group_ids         = [module.sg_alb.security_group_id, module.sg_eks.security_group_id]
  depends_on                 = [module.eks-nodegroup, module.alb_ingress_addon, module.route53_hostedzone]
}

/* --------------------- External DNS Add-on -------------------- */
module "external_dns_addon" {
  source       = "git::https://github.com/Khaled-SRE/terraform-modules.git//EKS_Addons/External_DNS?ref=v1.0.0"
  cluster_name = var.cluster_name
  domain       = var.domain
  zone_name    = var.ACM_zone_type
  depends_on   = [module.alb_ingress_addon]
}
/* ------------------------------- WAF ------------------------------ */

data "aws_lb" "ingress_alb" {
  tags = {
    "elbv2.k8s.aws/cluster"      = var.cluster_name
    "ingress.k8s.aws/resource"   = "LoadBalancer"
    "ingress.k8s.aws/stack"      = var.cluster_name
  }

  depends_on = [module.alb_ingress_addon, module.argo_cd_addon]
}

# Add a time delay to ensure ALB is fully created
resource "time_sleep" "wait_for_alb" {
  depends_on = [data.aws_lb.ingress_alb]
  create_duration = "30s"
}


module "waf" {
  source = "git::https://github.com/Khaled-SRE/terraform-modules.git//WAF?ref=v1.0.0"

  waf_name        = var.waf_name
  waf_description = var.waf_description
  alb_arn         = data.aws_lb.ingress_alb.arn
  waf_rules       = var.waf_rules

  # Monitoring configuration
  log_retention_days           = var.waf_log_retention_days
  enable_blocked_requests_alarm = var.waf_enable_blocked_requests_alarm
  blocked_requests_threshold    = var.waf_blocked_requests_threshold
  alarm_actions                = [aws_sns_topic.security_alerts.arn]

  depends_on = [time_sleep.wait_for_alb]

  tags = {
    Environment = var.env
    Project     = var.cluster_name
    ManagedBy   = "terraform"
  }
}

# SNS Topic for WAF alerts
resource "aws_sns_topic" "security_alerts" {
  name = var.sns_topic_name
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })

  depends_on = [aws_sns_topic.security_alerts]
}
