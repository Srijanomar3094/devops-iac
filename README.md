# Prefect Worker on AWS ECS Fargate

This Terraform configuration deploys a Prefect worker on AWS ECS using Fargate launch type. The setup includes a VPC, ECS cluster, IAM roles, and necessary networking components, connected to a Prefect Cloud work pool.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version >= 1.2.0)
- Prefect Cloud account and API key
- Python 3.8+ with virtual environment

## Infrastructure Components

- VPC with CIDR 10.0.0.0/16
- 3 public and 3 private subnets across multiple availability zones
- NAT gateway for private subnet outbound traffic
- ECS cluster with Fargate launch type
- IAM roles and policies
- CloudWatch log group
- AWS Secrets Manager for Prefect API key
- Service discovery with private DNS namespace

## Setup Instructions

1. Create and activate a Python virtual environment:
   ```bash
   python3 -m venv devopsenv
   source devopsenv/bin/activate
   ```

2. Install required packages:
   ```bash
   pip install terraform-local awscli prefect
   ```

3. Configure AWS credentials:
   ```bash
   aws configure
   ```

4. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   aws_region = "us-east-1"
   prefect_api_key = "your-api-key"
   prefect_account_id = "your-account-id"
   prefect_workspace_id = "your-workspace-id"
   prefect_account_url = "your-account-url"
   ```

5. Initialize Terraform:
   ```bash
   terraform init
   ```

6. Review the planned changes:
   ```bash
   terraform plan
   ```

7. Apply the configuration:
   ```bash
   terraform apply
   ```

## Verification Steps

1. Check the ECS cluster in AWS Console:
   - Navigate to ECS service
   - Verify cluster creation
   - Check running tasks

2. Verify Prefect Cloud work pool:
   - Log in to Prefect Cloud
   - Navigate to Work Pools
   - Verify "ecs-work-pool" is active

3. Check CloudWatch logs:
   - Navigate to CloudWatch service
   - Check logs in "/ecs/prefect-worker" group

## Cleanup Instructions

To destroy all created resources:

```bash
terraform destroy
```

## Security Considerations

- The Prefect API key is stored in AWS Secrets Manager
- Worker runs in private subnets
- Security groups restrict network access
- IAM roles follow principle of least privilege

## Monitoring and Maintenance

- CloudWatch Container Insights enabled
- Log retention set to 30 days
- Resource tagging for cost tracking

## Troubleshooting

1. If worker fails to start:
   - Check CloudWatch logs
   - Verify Prefect API key in Secrets Manager
   - Check VPC and security group configurations

2. If networking issues occur:
   - Verify NAT gateway status
   - Check security group rules
   - Validate VPC endpoints if used

## Additional Resources

- [Prefect Documentation](https://docs.prefect.io/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
