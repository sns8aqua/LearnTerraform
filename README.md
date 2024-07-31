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

Here's your content converted into a GitHub README format with appropriate Markdown syntax:

```markdown
# Terraform Documentation

## Lifecycle Rules

There are certain scenarios where we don't want Terraform to delete the infrastructure when we apply changes. In these cases, we can use lifecycle rules:

```hcl
lifecycle {
    create_before_destroy = true
}

lifecycle {
    prevent_destroy = true
}
```

### Key Lifecycle Arguments

- **`create_before_destroy`**: Ensures that a new resource is created before the old one is destroyed.
- **`prevent_destroy`**: Prevents the resource from being destroyed.
- **`ignore_changes`**: Specifies attributes to ignore when determining if a resource needs updating.

---

## Terraform Data Sources

Data sources are used to read a text file or fetch content from an existing resource. They are declared using the `data` block.

Terraform data sources allow you to fetch data from external sources or existing resources in your infrastructure, which can be used to configure other resources.

### Step 1: Define the Data Source

Use a data source to fetch the VPC ID of an existing VPC.

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["my-vpc"]
  }
}
```

### Step 2: Use the Data Source in a Resource

Next, create a subnet within the fetched VPC using the data source.

```hcl
resource "aws_subnet" "example" {
  vpc_id            = data.aws_vpc.selected.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "example-subnet"
  }
}
```

---

## Terraform Meta Arguments

### Key Meta Arguments

1. **`count`**
   - This creates the resource with the specified number.

   ```hcl
   resource "local_file" "pet" {
       filename = var.filename[count.index] # Set the file name using index in the list below
       count    = length(var.filename)
   }

   variable "filename" {
       default = [
           "root/pet.txt",
           "root/dog.txt",
           "root/duck.txt"
       ]
   }
   ```

   **Note:** The problem with `count` is that it will recreate the resources if variables are modified, which is not ideal. That's why we need `for_each`.

2. **`for_each`**
   - More usable than `count`.

   ```hcl
   resource "local_file" "pet" {
       filename = each.value
       for_each = toset(var.filename)
   }

   variable "filename" {
       type    = set(string)  # Important to ensure uniqueness
       default = [
           "root/pet.txt",
           "root/dog.txt",
           "root/duck.txt"
       ]
   }
   ```

3. **`depends_on`**
4. **`provider`**
5. **`lifecycle`**

---

## Version Constraints

Provider plugins vary from one to another. The provider documentation in the registry specifies the version, starting with `terraform`.

```hcl
terraform {  # Remember the constraint is set to terraform here
    required_providers {
        local = {
            source  = "hashicorp/local"
            version = "1.4.0"
        }
    }
}
```

---

## Remote State

- Understanding local state files vs remote state files is crucial.
- It is not advisable to store state files in a repository. Why? A developer writes a Terraform script in an S3 bucket and proceeds to apply it, which creates a state file locally and in the repo.
- State files store sensitive information, such as IP addresses, databases, and passwords.

<aside>
💡 **State locking** is a very important feature, and Git does not store state locking. 
Store it in AWS S3, Consul, GCP Storage, or Terraform Cloud.
</aside>

---

## Remote State Locking

To enable remote state locking, you need an S3 bucket and state locking.
```

### Summary

This README provides a structured overview of key Terraform concepts, including lifecycle rules, data sources, meta arguments, version constraints, and remote state management. Feel free to modify any part to better fit your project's specific needs!

---

This guide provides a quick overview of Terraform basics, including configurations, variables, resource attributes, dependencies, state management, and key commands. For more detailed information, refer to the [Terraform documentation](https://www.terraform.io/docs).
