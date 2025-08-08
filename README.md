# Glue S3 Hosted Dependencies

## Motivating the Problem

The default Glue job deployment exposes traffic to the public internet and installs Python packages via the
public [pypi.org](https://pypi.org/). Let's start making this more secure:

### Opting for AWS-Backbone Traffic

Let's route network traffic via the AWS backbone instead of the public internet. We'll create a Glue Connection of type
NETWORK. Per [this documentation](https://docs.aws.amazon.com/glue/latest/dg/start-connecting.html), executing a Glue
job with a Glue Connection causes an elastic network interface to be created on your VPC. A few things to keep in mind:

1. An ENI is created for each job execution and torn down shortly thereafter. This makes network debugging and
   troubleshooting a bit more painful.
2. The private IP address assigned to the ENI is chosen from the private subnet's IP address range. This makes it hard
   to create networking rules that target AWS Glue.

### Resilience

Each Glue Connection can only target a single subnet, but Glue Jobs can be registered with multiple Glue Connections.
We'll create a Glue Connection per private subnet and assign all of the subnets to the Glue Job. The Glue Job will
attempt to use a Glue Connection. If it isn't healthy, it will move on to the next available Glue Connection until it
exhausts available Glue Connections.

### Python Packages

Now that we're routing traffic to a private subnet, we're unable to access the public PyPi
repository. [This documentation](https://docs.aws.amazon.com/glue/latest/dg/setup-vpc-for-pypi.html) proposes a few
approaches:

#### Internet Gateway

The first proposal is to allow public internet traffic via an Internet Gateway. Good luck getting your network or
security team to agree to allowing public internet access from your private subnets. Good one, AWS.

#### AWS Codeartifact

The third suggestion is [AWS CodeArtifact](https://aws.amazon.com/codeartifact/). Let's talk about why that's a bad
idea:

1. It's only available in specific regions.
2. You can't grant the Glue user access to your Codeartifact repository via IAM. Instead, you need to generate a token
   prior to each Glue job execution and pass it into the job via a job parameter.:
   `"--python-modules-installer-option": "--no-cache-dir --verbose --index-url https://###############:your-code-artifactory... --trusted-host your-code-artifactory..."`
3. The token that you passed into the job parameter is now displayed in plain text to any user with sufficient
   permissions to view the job execution. While the security risks posed are small, security-minded enterprises will
   balk at the idea.

#### S3-Hosted Dependencies

The [second suggestion](https://docs.aws.amazon.com/glue/latest/dg/setup-vpc-for-pypi.html#setup-vpc-for-pypi-s3-bucket)
is to set up a PyPi mirror on S3 and reference the private mirror using the `--python-modules-installer-option` job
parameter. The example code is both incomplete and out of date. The `s3pypi` library referenced has a very different API
now and seems to assume that the S3 Bucket is publicly available.

Referencing S3-hosted dependencies is the right approach, but the documentation is lacking. This repo aims to solve
that.

## Setup

### Installations

You'll need a few dependencies to make this work:

- [Python 3.10](https://www.python.org/downloads/)
- [PDM](https://pdm-project.org/en/latest/#installation)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Docker Desktop](https://docs.docker.com/desktop/)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Configuration

#### AWS CLI

Authenticate your AWS CLI. I like to
use [aws sso login](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)  (e.g.
`aws sso login --profile <profile name>`)

#### Terraform

1. Initialize the providers:
   ```bash
   terraform init
   ```

2. (Optional) Make sure everything is formatted nicely
   ```bash
   terraform fmt
   ```

3. (Optional) Validate the template
   ```bash
   terraform validate
   ```

4. (Optional) View the template plan
   ```bash
   terraform plan -var-file="env/dev.tfvars"
   ```

5. Apply the template for the first time. This will create an S3 bucket and SSM parameter that we'll reference in the
   Docker image. Alternatively, you could use an existing S3 bucket and SSM parameter and avoid this initial deployment.
   You would just need to ensure that the Glue execution role has access to the S3 bucket hosting the whl files
   ```bash
   terraform apply -var-file="env/dev.tfvars"
   ```

6. Build the Docker image. The `aws_region`, `s3_bucket`, and `ssm_parameter_name` parameters should come from your
   terraform template. The Docker image will build whl files in the Glue execution environment and store them in a
   common directory.

   ```bash
   docker build --rm \
   --build-arg aws_region=<Region in which the Terraform template is deployed> \
   --build-arg s3_bucket=<S3 Bucket name from Terraform template> \
   --build-arg tgt_dir=whl_files \
   --build-arg src_dir=./wheels \
   --build-arg ssm_parameter_name=<SSM Parameter name from Terraform template> \
   --progress=plain \
   -t \
   upload_whls_to_s3 .
   ```

7. Run the Docker image. This command mounts your `~/.aws` directory to the Dockerfile to authenticate the image with
   AWS. Running the Docker image will upload the whl files generated by the build to S3 and store the list of S3 URIs
   in the SSM parameter.

   ```bash
   docker run --rm \
   -v ~/.aws:/home/glue_user/.aws \
   -e AWS_PROFILE=<your AWS Profile name> \
   -e DISABLE_SSL=true \
   upload_whls_to_s3
   ```

8. Apply the template again. The Glue job will be updated with an `--additional-python-modules` job parameter containing S3 URIs for all the whl files.

   ```bash
   terraform apply -var-file="env/dev.tfvars"
   ```

9. Run the Glue job to ensure that the imported `--additional-python-modules` libraries are accessible.
