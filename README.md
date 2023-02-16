## Pre-requisites Software Installation
- AWS CLI installation : `https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html`
- Terraform Installation: `https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli`

## Configuring AWS CLI
- Configure AWS CLI with profiles `aws configure --profile profileName`
- Add access_key and secret key,  region , output format
  
## Teraform
- Initialize Terraform by `terraform init`
- Create a plan by  `terraform plan -var-file=fileName`
- Apply Terraform `terraform apply -var-file=fileName` 
- To Destroy the created resources `terraform destroy -var-file=fileName`