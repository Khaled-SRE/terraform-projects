# EKS Platform Infrastructure

This repository contains Terraform configurations for deploying a secure and scalable EKS platform with integrated security features.

## Architecture Overview

The infrastructure includes:
- EKS Cluster with managed node groups
- ALB Ingress Controller for load balancing
- WAF protection for the ALB
- Route53 for DNS management
- ACM for SSL/TLS certificates
- ArgoCD for GitOps deployments
- External DNS for automatic DNS management

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.10
- kubectl
- helm
- AWS IAM role with necessary permissions
- S3 bucket for Terraform state

## Required AWS Permissions

The IAM role should have permissions for:
- EKS cluster management
- VPC and networking
- IAM role and policy management
- WAF and Shield
- Route53
- ACM
- S3
- CloudWatch

## Infrastructure Components

### Network Layer
- VPC with public and private subnets
- Security groups for ALB and EKS
- NAT Gateways for private subnet internet access

### EKS Cluster
- Managed node groups
- ALB Ingress Controller
- ArgoCD for GitOps
- External DNS

### Security
- WAF protection for ALB
- Security groups with least privilege
- HTTPS enforcement
- CloudWatch monitoring and alerts

## Configuration

### Environment Variables
Create a `test.tfvars` file with your configuration:

```hcl
env    = "test"
region = "eu-west-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
vpc_name             = "eks-test-vpc"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
cluster_name    = "platform-test-eks"
cluster_version = "1.33"

# WAF Configuration
waf_name        = "platform-test-eks-alb-protection"
waf_description = "WAF protection for EKS ALB Ingress"
```

### WAF Rules
The WAF configuration includes:
- AWS Managed Rules Common Rule Set
- Known Bad Inputs Rule Set
- Amazon IP Reputation List
- Custom rule overrides as needed

## Deployment

1. Initialize Terraform:
```bash
terraform init
```

2. Review the planned changes:
```bash
terraform plan -var-file=test.tfvars
```

3. Apply the configuration:
```bash
terraform apply -var-file=test.tfvars
```

## Monitoring and Alerts

- CloudWatch metrics for WAF
- SNS topics for security alerts
- Blocked requests monitoring
- Custom metrics for specific rules

## Security Features

1. Network Security:
   - Private subnets for EKS nodes
   - Security groups with least privilege
   - NAT Gateways for controlled internet access

2. Application Security:
   - WAF protection against common web exploits
   - HTTPS enforcement
   - IP reputation filtering

3. Monitoring and Alerting:
   - CloudWatch metrics
   - SNS notifications
   - Custom dashboards

## Maintenance

### Updating WAF Rules
1. Modify the `waf_rules` in `test.tfvars`
2. Apply changes:
```bash
terraform apply -var-file=test.tfvars
```

### Scaling the Cluster
1. Update node group configuration in `test.tfvars`
2. Apply changes:
```bash
terraform apply -var-file=test.tfvars
```

## Troubleshooting

### Common Issues

1. ALB Creation:
   - Ensure ALB Ingress Controller is properly installed
   - Check IAM permissions
   - Verify security group configurations

2. WAF Association:
   - Verify ALB exists before WAF creation
   - Check WAF rule configurations
   - Review CloudWatch metrics

3. DNS Issues:
   - Verify Route53 configuration
   - Check External DNS addon
   - Review DNS records


