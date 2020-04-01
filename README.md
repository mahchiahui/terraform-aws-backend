# Terraform AWS Backend
Establishing Terraform backend on AWS resources

## Usage

Before launching the Terraform backend, first fill up the variables in set_env.sh and run it.

```bash
source set_env.sh
```

Launch the Terraform backend with the following command

```bash
make create-backend
```

Destroy the Terraform backend with the following command

```bash
make destroy-backend
```