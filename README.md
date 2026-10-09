## Building CRUD Spring Boot REST API with Lambda + API Gateway + DynamoDB

In this project, I'll be exploring how to deploy entire CRUD Spring Boot applications using AWS Lambda + API Gateway +
DynamoDB.

### AWS Serverless Java Container

***

The **AWS Serverless Java Container** makes it easier to run Java applications written with frameworks such as Spring,
Spring Boot, or JAX-RS/Jersey in Lambda.

The container provides adapter logic to minimize code changes. Incoming events are translated to the **Servlet
specification** so that frameworks work as before.

![AWS Serverless Java Container adapter.png](AWS%20Serverless%20Java%20Container%20adapter.png)

### DynamoDB for serverless state

***

Lambda functions are stateless. DynamoDB provides fast, scalable, serverless-compatible storage without connection pool
management.

### Architecture overview

***

Here is the architecture diagram related to the scenario we are going to address.

![crud-lambda-dynamodb.png](crud-lambda-dynamodb.png)

### Technology Stack

***

* Application: Java 21, Spring Boot 4, Maven
* AWS Cloud: AWS Lambda, API Gateway, IAM, DynamoDB
* Infrastructure as Code: Terraform
* CI/CD Automation: GitHub Actions

### Prerequisites

***

* AWS Account
* Terraform CLI (~> 1.14)
* Java 21
* Apache Maven

### Implementation

***

* Provisioning infrastructure with Terraform modules
* Creating CRUD REST API with Spring Boot application

After apply, grab the API URL:

```bash
terraform output api_invoke_url
```

![1-Outputs.png](Screenshot%20verification/1-Outputs.png)

### Deployment Workflow

***

The infrastructure must be created before the application can be deployed.

* **Deploy Infrastructure**: Make a commit and push to the `terraform/` directory on the master branch. The
  infrastructure pipeline (`deploy_infra.yaml`) will trigger and provision the necessary AWS resources.
* **Deploy Application**: Push a change to the Java application source code in `src/` to the master branch. The
  application pipeline (`deploy_app.yaml`) will trigger, build the JAR, and deploy it to the Lambda function created
  in the previous step.

### Verification and Testing the Lambda Function on AWS

***

**Test REST endpoints API Gateway using Postman**

Requests go to `<invoke_url>/{any-path}`, which routes through API Gateway's Lambda proxy integration to the Spring Boot
app via `StreamLambdaHandler`.

`$ GET <invoke_url>/hi`

| Method | Path                                     | Description                                 |
|--------|------------------------------------------|---------------------------------------------|
| GET    | `<invoke_url>/health`                    | Health Check Endpoint                       |
| POST   | `<invoke_url>/users`                     | Create a new user                           |
| GET    | `<invoke_url>/users/{userId}`            | Get a user by ID                            |
| GET    | `<invoke_url>/users/by-email?email=`     | Find a user by email (GSI)                  |
| PUT    | `<invoke_url>/users`                     | Update a user                               |
| GET    | `<invoke_url>/users/by-name?name=`       | Find by name containing                     |
| GET    | `<invoke_url>/users/by-status?status=`   | Find by status (GSI)                        |
| GET    | `<invoke_url>/users?status=&size=&page=` | Query user by status with page (`Pageable`) |
| GET    | `<invoke_url>/users?size=&page=`         | Get all users with page (`Pageable`)        |
| DELETE | `<invoke_url>/users/{userId}`            | Delete a user                               |

### Summary

***

In this project, we built and deployed a CRUD Spring Boot REST API on a fully serverless stack on AWS:

* **Infrastructure as Code**: provisioned AWS Lambda, API Gateway, IAM, and DynamoDB using Terraform modules.
* **Spring Boot on Lambda**: used the AWS Serverless Java Container to run a Spring Boot 4 (Java 21) application in
  Lambda through `StreamLambdaHandler`, with no changes to the standard servlet-based programming model.
* **Serverless persistence**: used DynamoDB as a scalable, stateless-friendly data store with no connection pool
  management, including lookups through Global Secondary Indexes (by email and by status) and paginated queries
  with `Pageable`.
* **API Gateway integration**: exposed the application through a Lambda proxy integration, so any path is routed to
  the Spring Boot app.
* **CI/CD automation**: set up separate GitHub Actions pipelines, `deploy_infra.yaml` for the `terraform/` directory
  and `deploy_app.yaml` for the application code in `src/`, with infrastructure deployed first.
* **Verification**: tested the health check and user CRUD endpoints (create, get, update, delete, and search by
  email, name, and status) against the deployed API using Postman.
