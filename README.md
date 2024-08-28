### Using Agents for Amazon Bedrock to Interactively Generate Infrastructure as Code

---
https://aws.amazon.com/blogs/machine-learning/using-agents-for-amazon-bedrock-to-interactively-generate-infrastructure-as-code/

Architecture Diagram:

<img width="1475" alt="Screenshot 2024-08-28 at 4 24 47 PM" src="https://github.com/user-attachments/assets/8f79ea42-e022-41e7-9a22-fd932331d9d8">

#### Uploaded image to the S3 bucket for IaC Generation(Ex):
The S3 bucket is named: architecture-diagram-bucket-1 and the object is named: vpc-example-private-subnets.png
![vpc-example-private-subnets](https://github.com/user-attachments/assets/94e9fdc6-5d69-4f3e-8d19-35b445a8c64a)

We can now interact with the Amazon Bedrock Agent to generate our infrastructure as code.

<img width="321" alt="iac agent 1" src="https://github.com/user-attachments/assets/0f397129-92c4-438b-a823-b5a1dfc0bc73">
<img width="330" alt="iac agent 2" src="https://github.com/user-attachments/assets/b967bc70-b7b8-44aa-935c-4a88aafec807">
<img width="315" alt="iac agent 3" src="https://github.com/user-attachments/assets/ce062be3-8fe5-44d9-846c-2fa01a048f5e">
<img width="319" alt="iac agent 4" src="https://github.com/user-attachments/assets/dfde0a34-aeab-419d-be8f-0115fffd4886">
<img width="320" alt="iac agent 5" src="https://github.com/user-attachments/assets/c26c67a8-e0a0-44ea-b210-689e8136d7c4">


#### Solution Overview
- The user utilizes the bedrock agent chat console to input the name of their S3 Bucket and the Object (key) name where the architecture diagram is stored.  
- After receiving these details, the Bedrock Agent forwards them to an action group that triggers an AWS Lambda function. This function retrieves the architecture diagram from the specified S3 bucket, analyzes it, and produces a summary of the diagram. It also generates questions regarding any missing components, dependencies, or parameter values that are needed to create IaC for AWS services. This detailed response is then sent back to the Bedrock Agent.
- The Bedrock Agent displays the generated questions to the user and records their responses. After addressing all the questions, the agent provides a comprehensive summary of the analyzed infrastructure component configuration for user review. Users then have the opportunity to approve this configuration or suggest any necessary adjustments. Once the details are finalized, this information is passed to another action group, which activates an AWS Lambda function to proceed with the process.
- The Lambda function processes the user's finalized inputs, utilizes a knowledge base with modules that adhere to company standards as a baseline, and generates the necessary Infrastructure as Code (IaC). Once generated, the IaC is automatically pushed to a designated GitHub repository.

#### Analysis Query Generation Lambda (Triggered by action groups)
- **Description**: Analyses the input architecture diagram and generates questions for missing components/dependencies.
- **Dependencies**: Python 3.x, Resource based policy (Principal: bedrock.amazonaws.com, Action: lambda:InvokeFunction)
- **Logical Flow**:
  1. Receives an event with S3 bucket and Object name.
  2. Fetch diagram from S3.
  3. Analyses the diagram.
  4. Creates a summary of the services present in diagram and also questions regarding missing components/dependencies.
  5. Returns the information back to Bedrock agent.
 
- **Logical Flow**:
  1. Receives an event with S3 bucket, Object name, Final approved changes.
  2. Fetch diagram from S3.
  3. Analyses the diagram.
  4. Retrieves modules from provided Knowledge base.
  5. Creates IaC and publishes it to GitHub respository.
  6. Returns success message with GitHub URLs or error information.

#### Knowledge Base (KB)
- **Description**: A structured repository containing AWS service and Terraform module information.
- **Structure**: JSON format categorizing services and modules.
- **Configure Knowledge Base**: Configuring a Knowledge Base (KB) enables your Bedrock agents to access a repository of information for AWS Terraform modules. Follow these steps to set up your KB:
  1. Access the Amazon Bedrock Console: Log in and go directly to the 'Knowledge Base' section. This is your starting point for creating a new KB.
  2. Name Your Knowledge Base: Choose a clear and descriptive name that reflects the purpose of your KB, such as "AWS Terraform Modules"
  3. Select an IAM Role: Assign a pre-configured IAM role with the necessary permissions. 
  4. Define the Data Source: Upload a JSON file to an S3 bucket with encryption enabled for security. This file should contain a structured list of AWS services and Terraform modules. For the JSON structure, use the example provided in this repository
  5. Choose the Default Embeddings Model: For most use cases, the Amazon Bedrock Titan G1 Embeddings - Text model will suffice. It's pre-configured and ready to use, simplifying the process.
  6. Opt for the Managed Vector Store: Allow Amazon Bedrock to create and manage the vector store for you in Amazon OpenSearch Service.
  7. Review and Finalize: Double-check all entered information for accuracy. Pay special attention to the S3 bucket URI and IAM role details.


