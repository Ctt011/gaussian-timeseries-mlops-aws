# AWS LightSail Deployment with Approval

This guide explains how to deploy a Flask application to AWS LightSail using container services, including staging and production environments, with optional cleanup.

---


## Step 1: Create Container Services

Create the staging and production container services:

```aws lightsail create-container-service --service-name flask-service-staging --power small --scale 1 --region us-east-1```

```aws lightsail create-container-service --service-name flask-service-prod --power small --scale 1 --region us-east-1```


## Step 2: Configure Private Registry Access (ECR)

Allow the production container service to pull images from a private ECR repository:

```aws lightsail update-container-service --service-name flask-service-prod --private-registry-access ecrImagePullerRole={isActive=true} --region us-east-1```


```aws lightsail get-container-services --service-name flask-service-prod --region us-east-1```


## Explanation:

Grants permission for LightSail to pull Docker images from your private ECR.

After running, the service state will show "PENDING". Wait a few minutes until it becomes "ACTIVE".




## IAM Policy for Lightsail to Pull from ECR

This policy allows AWS LightSail to pull Docker images from a private ECR repository.


{
  "Statement": [
    {
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Principal": {
        "AWS": [
          ""
        ]
      },
      "Effect": "Allow",
      "Sid": "AllowLightsailPull"
    }
  ],
  "Version": "2012-10-17"
}




## Step 3: Check Deployment Status

Verify that your staging and production services are running:

# Check staging service
aws lightsail get-container-services --service-name flask-service-staging

# Check production service
aws lightsail get-container-services --service-name flask-service-prod




## Step 4: Cleanup (Optional)

Remove the container services when no longer needed:

# Delete staging service
aws lightsail delete-container-service --service-name flask-service-staging

# Delete production service
aws lightsail delete-container-service --service-name flask-service-prod


Explanation:

Frees up resources and stops billing for the container services.

Use this after testing or deployment is complete.



```Lightsail access```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "lightsail:*",
            "Resource": "*"
        }
    ]
}