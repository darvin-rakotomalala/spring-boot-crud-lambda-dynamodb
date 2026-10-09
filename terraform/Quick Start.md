## Building CRUD Spring Boot REST API with Lambda + API Gateway + DynamoDB

In this project, I'll be exploring how to deploy entire CRUD Spring Boot applications using AWS Lambda + API Gateway +
DynamoDB with Terraform.

### Deploy

```bash
$ cd spring-boot-crud-lambda-dynamodb/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Test the function

**Test Function with API Gateway REST API**

Requests go to `<invoke_url>/{any-path}`, which routes through API Gateway's Lambda proxy integration to the Spring Boot
app via `StreamLambdaHandler`.

```
$ curl <invoke_url>/health
```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
