/* -------------------------------------------------------------------------- */
env    = "test"
region = "eu-west-1"

/* ------------------------------ VPC Variables ----------------------------- */
vpc_cidr             = "10.0.0.0/16"
vpc_name             = "eks-test-vpc"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]  
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

/* ------------------------------ EKS Variables ----------------------------- */
cluster_name                         = "platform-test-eks"
cluster_version                      = "1.33"
profile_name                         = "platform-test"
eks_role_name                        = "eks-role-test"
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = false
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

/* ------------------------- EKS-NodeGroup Variables ------------------------ */
node_group_name           = "platform-test-eks-node-group"
eks_nodes_role_name       = "eks-node-group-role"
node_group_min_size       = 1
node_group_desired_size   = 1
node_group_max_size       = 2
node_group_ami_type       = "AL2_x86_64"
node_group_capacity_type  = "ON_DEMAND"
node_group_disk_size      = 50
node_group_instance_types = ["t3.large"]

/* --------------------------- EKS-Addon Variables -------------------------- */
ingress_group_name       = "platform-test-eks"
argocd_domain_name       = "argocd.platform-test.com"
ACM_zone_type            = "public"

/* -------------------------------- Route 53 -------------------------------- */
domain        = "platform-test.com"

/* -------------------------------------------------------------------------- */
/*                               Security Group                               */
/* -------------------------------------------------------------------------- */

/* --------------------------------- ALB_SG --------------------------------- */
alb_sg_name        = "alb-sg"
alb_sg_description = "Security group for public ALB"
ALB_ingress_rules = [
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
  },
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from internet (will be redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
  }
]
ALB_egress_rules = [{
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic for external service connections"
  from_port   = 0
  to_port     = 65535
  protocol    = "All"
}]

/* --------------------------------- WAF Configuration --------------------------------- */
waf_name        = "platform-test-eks-alb-protection"
waf_description = "WAF protection for EKS ALB Ingress"

waf_rules = [
  {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    statement = {
      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_overrides = [
          {
            name = "NoUserAgent_HEADER"  # Example: Allow requests without User-Agent
          }
        ]
      }
    }
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name               = "CommonRuleSet"
      sampled_requests_enabled  = true
    }
  },
  {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    statement = {
      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name               = "KnownBadInputs"
      sampled_requests_enabled  = true
    }
  },
  {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3
    statement = {
      managed_rule_group_statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name               = "AmazonIpReputationList"
      sampled_requests_enabled  = true
    }
  }
]

# WAF Monitoring Configuration
waf_log_retention_days           = 90
waf_enable_blocked_requests_alarm = true
waf_blocked_requests_threshold    = 50

# SNS Topic Configuration
sns_topic_name = "platform-test-eks-waf-alerts"

/* --------------------------------- EKS_SG --------------------------------- */
eks_sg_name        = "eks-sg"
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
  }
]
eks_egress_rules = [{
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic for external service connections"
  from_port   = 0
  to_port     = 65535
  protocol    = "All"
}]
