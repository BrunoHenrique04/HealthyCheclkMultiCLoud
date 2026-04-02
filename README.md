# FIAP Multicloud (Sem Banco de Dados)

Implementação completa da arquitetura com:
- AWS EC2 + Security Group
- GCP Compute Engine + Firewall
- Route 53 com Health Check e Failover (PRIMARY AWS / SECONDARY GCP)
- Makefile para simulação de falha e recuperação
- Workflows GitHub Actions para deploy AWS e GCP

## Estrutura

```text
.
├── Makefile
├── terraform/
│   ├── aws/
│   │   ├── main.tf
│   │   ├── dns.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── gcp/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .github/workflows/
		├── awsCreate.yml
		└── googleCreate.yml
```

## Secrets (GitHub Actions)

Configure em `Settings > Secrets and variables > Actions`:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `GCP_SA_KEY`

Sem banco de dados, então `DB_PASSWORD` não é necessário.

## Deploy manual (CLI)

### 1) GCP

```bash
cd terraform/gcp
terraform init
terraform apply \
	-var="rm_number=562192" \
	-var="gcp_project_id=meu-projeto"
```

Anote o output `gcp_instance_external_ip`.

### 2) AWS + DNS failover

```bash
cd terraform/aws
terraform init
terraform apply \
	-var="rm_number=562192" \
	-var="hosted_zone_id=Z123456789ABC" \
	-var="gcp_site_ip=<IP_DO_GCP>"
```

Se quiser criar Key Pair para SSH na EC2, adicione também:

```bash
-var='aws_public_key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...'
```

## Operação de failover

```bash
make aws-down RM_NUMBER=562192
make aws-up   RM_NUMBER=562192
```

Também disponível para GCP:

```bash
make google-down RM_NUMBER=562192 GCP_PROJECT_ID=meu-projeto
make google-up   RM_NUMBER=562192 GCP_PROJECT_ID=meu-projeto
```
