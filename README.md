# Terraform Anbox Cloud Appliance

This is a terraform script to deploy anbox-cloud-appliance on aws.

### How to deploy

1. Initialize terraform in the directory using

```sh
terraform init
```

2. Inspect the plan using

```sh
terraform plan -out=tfplan
```

3. If everything looks fine. Run apply using

```sh
terraform apply tfplan
```

4. You can teardown the setup using

```sh
terraform destroy
```

