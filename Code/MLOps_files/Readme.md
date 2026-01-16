# AWS MLOps

This project demonstrates how to operationalize a Gaussian Process Time Series Model on AWS using industry-standard MLOps principles. By deploying the model in a staging environment first, organizations can validate its performance before moving to production.   

> **Note:** A basic understanding of AWS MLOps for Gaussian Process Time Series Modeling is recommended before starting this project.

---

---

## Tech Stack

- **Language:** Python  
- **Libraries:** Flask, numpy, pandas, boto3, seaborn, scipy, matplotlib  
- **Services:** Flask, Docker, AWS ECR, AWS CodePipeline, AWS CodeBuild, AWS Lightsail, AWS SNS  
- **Tool:** Terraform  

---

## Steps

### 1. Infrastructure Provisioning & Local Development
- Provision all AWS resources using Terraform for both staging and production.
- Ensure structured, automated, and reproducible setup.

### 2. Source Control & CI/CD Triggering
- Store code and deployment scripts in GitHub.
- Each commit triggers AWS CodePipeline, packaging source code into build artifacts.

### 3. Staging Environment
- **AWS CodeBuild (Staging):** Builds application artifacts and Docker image for staging.  
- **Amazon ECR (Staging Repository):** Stores versioned Docker images.  
- **Lightsail Staging Container Service:** Deploys Docker image for testing.  
- **Manual Approval via SNS:** Notifies approver to test and approve deployment.

### 4. Production Environment
- **AWS CodeBuild (Production):** Reuses tested Docker image from staging.  
- **Amazon ECR (Production Repository):** Stores approved Docker image.  
- **Lightsail Production Container Service:** Deploys approved image, providing a public endpoint.

### 5. User Request Flow
- Users send POST requests to Flask API on production Lightsail container.  
- Flask app fetches data from S3, processes via Gaussian Process Time Series model, and returns predictions.

### 6. CI/CD Automation & Monitoring
- Every code commit triggers staging pipeline; approved builds promote to production automatically.  
- Logs and container health monitored via CloudWatch.

---

## Key Takeaways

- Learn Terraform-based AWS provisioning for ML applications.  
- Hands-on integration of Terraform with CI/CD pipelines.  
- Understand deployment of Dockerized ML applications on AWS Lightsail.  
- Experience automated staging and production promotion workflows.  
- Practical knowledge of S3 integration with Flask APIs.  
- Learn reproducibility and safe promotion best practices.

> **Note:** AWS services may incur charges. Terminate resources after project completion to avoid unnecessary costs.

---


## Provisioning AWS Services Using Terraform

All AWS services required for this project were also provisioned using Terraform. The **main Terraform scripts (`main.tf`)** manage the creation and configuration of:

- AWS ECR repositories  
- AWS CodeBuild projects  
- AWS CodePipeline pipelines  
- AWS Lightsail container services (Staging and Production)
- AWS SNS topics  

This ensures **automated, consistent, and reproducible infrastructure** without manual setup in the AWS console.

---

## Terraform Commands

### Initialize Terraform
Initializes the working directory containing Terraform configuration files.

```terraform init```

## Validate Test

```terraform validate```

# Dry run Test
Shows what actions Terraform will perform without applying them.

```terraform plan -var-file="secret.tfvars"```


# Provision all services using Terraform

```terraform apply -var-file="secrets.tfvars" --auto-approve```



## Destroy All Terraform Resources

```terraform destroy -var-file="secrets.tfvars" --auto-approve```



## Testing the Deployment
After deployment, test the production Flask API using:

curl -X POST "<Lightsail-container-URL>"