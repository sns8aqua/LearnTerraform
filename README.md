# Terraform Quickstart Guide

## What is Terraform?
Terraform is an open-source infrastructure as code (IaC) tool that allows you to define and provision data center infrastructure using a declarative configuration language, HCL (Hashicorp Configuration Language). Terraform configurations are written in files with a `.tf` extension and emphasize **idempotency**, meaning applying the same configuration multiple times will produce the same result without changing the existing infrastructure.

## Variables
### Command Line Precedence
The command line `-var` option takes precedence over any variables defined in the variables file.

### Variable Types
- **String, Number, Boolean**
- **List**: Zero-indexed collections
    ```hcl
    variable "prefix" {
        default = ["Mr", "Mrs", "Sir"]
        type    = list
    }
    
    resource "random_pet" "my_pet" {
        prefix = var.prefix[0]
    }
    ```
- **Map**: Key-value pairs
    ```hcl
    variable "ami" {
        type = map
        default = {
            "ami1" = "AsdfasdFASDF"
            "ami2" = "!23213213!"
        }
    }
    
    resource "ami" {
        ami = var.ami["ami1"]
    }
    ```

### Data Structures
| Feature           | List            | Tuple             | Object                         |
|-------------------|-----------------|-------------------|--------------------------------|
| Element Types     | Homogeneous     | Heterogeneous     | Heterogeneous                  |
| Ordered/Unordered | Ordered         | Ordered           | Unordered                      |
| Access Method     | By index        | By index          | By key                         |
| Common Use Cases  | Similar items   | Different types   | Grouping related attributes    |

### Objects
Combines multiple data types efficiently.

## Resource Attributes
Resources can depend on each other. Use outputs from one resource to configure another.

```hcl
resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main_gateway"
    }
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }
}
```

## Resource Dependencies
Terraform typically manages resource dependencies implicitly. Explicit dependencies can be defined using `depends_on`.

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name"
  acl    = "private"
}

resource "aws_iam_policy" "example_policy" {
  name   = "example_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::my-unique-bucket-name/*"]
      }
    ]
  })
  depends_on = [aws_s3_bucket.example]
}
```

## Output Command
To print output variables, use the `output` block.

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket-123456"
  acl    = "private"
}

output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.example.arn
}
```

## Terraform State
Terraform maintains a state file (`tfstate`) to track infrastructure changes. This state file acts as a blueprint for the current configuration.

### Collaboration
State files can be stored remotely (e.g., AWS S3, Google Cloud Storage) to allow team collaboration and ensure consistency.

### Performance
Refers to the state file for infrastructure tracking. Sensitive data should be securely stored.

## Terraform Commands
| Command           | Usage                                                                 |
|-------------------|-----------------------------------------------------------------------|
| terraform init    | Initializes a new or existing Terraform configuration.                |
| terraform plan    | Creates an execution plan to achieve the desired state.               |
| terraform apply   | Applies the changes required to reach the desired state.              |
| terraform destroy | Destroys all Terraform-managed infrastructure.                        |
| terraform validate| Validates configuration files for syntax and consistency.             |
| terraform fmt     | Formats configuration files to a canonical style.                     |
| terraform show    | Displays information about the state or execution plan.               |
| terraform output  | Reads and outputs values of output variables.                         |
| terraform state   | Inspects and modifies the state file.                                 |
| terraform import  | Imports existing resources into the state.                            |
| terraform taint   | Marks a resource for recreation on the next `apply`.                  |
| terraform untaint | Removes the "tainted" state from a resource.                          |
| terraform refresh | Updates the state file with the real-world status of resources.       |
| terraform graph   | Generates a visual representation of the dependency graph.            |
| terraform workspace| Manages multiple workspaces for separate state files in environments.|

### Visualizing with `terraform graph`
- Install Graphviz: `brew install graphviz`
- Generate and view the graph: `terraform graph | dot -Tsvg > graph.svg`

Open `graph.svg` in a browser to see the visualization.

---

This guide provides a quick overview of Terraform basics, including configurations, variables, resource attributes, dependencies, state management, and key commands. For more detailed information, refer to the [Terraform documentation](https://www.terraform.io/docs).
