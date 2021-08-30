## About this Repository

At Gretel, we use Terraform to provision our AWS EKS Kubernetes clusters, as well as manage some of our
third party deployments (FluentBit included) through Helm.

This repository is an example of using Terraform to:
1. Create an EKS cluster.
2. Use Helm to launch a dummy application.
3. Use Helm to launch FluentBit to log the dummy application instances.

Things you should be familiar with to understand this repository:
- Kubernetes
- Terraform
- AWS, and EKS in particular.
- Helm
- FluentBit

### Running the Code

You need a few things set up before you can run the contents of the repository.

- [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Configure AWS CLI credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).
   - This assumes you have an AWS account and can interact with EKS.

Once those two are set up, and you have the repository cloned, you simply:

      $ cd terraform

      $ terraform init

>   Initializing provider plugins...
>   - Finding terraform-aws-modules/http versions matching ">= 2.4.1"...
>   - Finding hashicorp/aws versions matching ">= 3.53.0"...
>   - Finding hashicorp/kubernetes versions matching ">= 2.4.1"...  
>   ...

    $ terraform apply

Confirm you want to create the resources (by typing 'yes'):

    $ Do you want to perform these actions?
    ...
    Enter a value: yes

The creation of the EKS cluster and OIDC provider will each take some time on the AWS
side of things, so don't worry if you see the following for a while (10 minutes or more):

> modeule.cluster.module.aws.aws_eks_cluster.cluster: Still creating... [5m50s elapsed]  
> modeule.cluster.module.aws.aws_eks_cluster.cluster: Still creating... [6m0s elapsed]  
> modeule.cluster.module.aws.aws_eks_cluster.cluster: Still creating... [6m10s elapsed]  
> ...

### Connecting to your Cluster
Once everything is finished being created, you can see your cluster through kubectl by updating your kubeconfig:

    aws eks update-kubeconfig \
		--region ${REGION} \
		--name ${CLUSTER_NAME} \
		--role-arn arn:aws:iam::${AWS_PROJECT_ID}:role/${CLUSTER_NAME}-admin

### Notes

By Default this repository will create a single node Kubernetes cluster with machine type **t3.medium**. To change this,
see the inputs in:

        cluster/aws/main.tf

### What is Terraform?

[Terraform](https://www.terraform.io/docs/cloud/index.html) is an ‘infrastructure as code’ tool created by HashiCorp,
and it gives you a common way to talk to a huge variety of tools and services. It works like this:

1. Third party Providers develop Resource (Infrastructure elements which can be created and destroyed) and Data
   (Information providers which make information available) types, which are essentially plugins for Terraform.
2. Every type of Resource and Data has a set of inputs it consumes, and outputs it makes available.
3. You load and use these types in your own Terraform file, filling in some of the inputs and utilizing some of the
   outputs.
4. When you run Terraform against your files (terraform apply), it creates the Resources specified, or removes
   Resources no longer specified, dynamically loading any Data needed while doing so.

#### Using Terraform with AWS

Terraform calls AWS’s resources which create a cluster in EKS. Then Terraform fetches the information for the cluster
created, and uses that to create the Daemonset in the newly created cluster using Helm.

Now that we understand a little about what we will accomplish at a high level, let’s dive into the code needed to create
our EKS cluster.

First, utilizing Terraform requires that it has access to some persistence, so when we first create our Terraform file,
we will need to specify a backend where it can store this state. You can use your local machine for this by specifying a
local backend, but for production you will want to use a real remote persistence service, like Amazon S3.

    terraform {
        required_version = ">= 1.0.0"
        required_providers {
            aws        = ">= 3.47.0"
            kubernetes = ">= 2.3.2"
        }
        backend "local" {
            path = "terraform.tfstate"
        }
    }

Getting a usable EKS cluster set up through Terraform requires the use of many AWS Resource types. I suggest you dive
into the documentation on 
[AWS's Terraform Provider page](https://registry.terraform.io/providers/hashicorp/aws/latest/docs). This repository can
be a good jump off point for knowing what to look at!

### What is Helm?

[Helm](https://helm.sh/) bills itself as the ‘Package manager for Kubernetes’. Helm applications use
[Charts](https://helm.sh/docs/topics/charts/), which are essentially templated Kubernetes YAML files. They are nicely
annotated so that you know which fields you may want to change, and which have reasonable defaults.

#### Setting up Helm With Terraform in AWS

You will need to add it to your Terraform configuration as a provider, and connect it to your Kubernetes cluster.
Here we assume you’ve already configured your Kubernetes cluster using AWS’s EKS service.

    provider "helm" {
        kubernetes {
            host                   = data.aws_eks_cluster.<your-cluster-name>.endpoint
            cluster_ca_certificate = base64decode(data.aws_eks_cluster.<your-cluster-name>.certificate_authority[0].data)
            exec {
            api_version = "client.authentication.k8s.io/v1alpha1"
            command     = "aws"
            args = [
                "eks",
                "get-token",
                "--cluster-name",
                data.aws_eks_cluster.myCluster.id,
                "--role-arn",
                module.my-cluster.cluster_admin_role
            ]
            }
        }
    }

This will make Helm available for subsequent chart deployments within Terraform files.
