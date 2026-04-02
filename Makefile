# =============================================================================
# FIAP Multicloud — Makefile de Controle
# =============================================================================
# Uso:
#   make aws-up       RM_NUMBER=562192
#   make aws-down     RM_NUMBER=562192
#   make google-up    RM_NUMBER=562192  GCP_PROJECT_ID=meu-projeto
#   make google-down  RM_NUMBER=562192  GCP_PROJECT_ID=meu-projeto
# =============================================================================

RM_NUMBER      ?= $(error Defina RM_NUMBER. Ex: make aws-up RM_NUMBER=562192)
AWS_REGION     ?= us-east-1
GCP_PROJECT_ID ?= $(error Defina GCP_PROJECT_ID)
GCP_ZONE       ?= us-east1-b

EC2_SG_NAME    = ec2-fiap-rm$(RM_NUMBER)
GCP_FIREWALL   = fiap-allow-http-rm$(RM_NUMBER)
GCP_INSTANCE   = fiap-site-rm$(RM_NUMBER)

.PHONY: help aws-up aws-down google-up google-down \
        aws-deploy aws-destroy gcp-deploy gcp-destroy \
        aws-status gcp-status

help:
	@echo ""
	@echo "  FIAP Multicloud — Comandos disponíveis"
	@echo ""
	@echo "  Controle de porta 80:"
	@echo "    make aws-up       RM_NUMBER=<rm>                         # libera HTTP na AWS"
	@echo "    make aws-down     RM_NUMBER=<rm>                         # bloqueia HTTP na AWS"
	@echo "    make google-up    RM_NUMBER=<rm> GCP_PROJECT_ID=<proj>   # libera HTTP no GCP"
	@echo "    make google-down  RM_NUMBER=<rm> GCP_PROJECT_ID=<proj>   # bloqueia HTTP no GCP"
	@echo ""
	@echo "  Deploy via Terraform:"
	@echo "    make gcp-deploy   RM_NUMBER=<rm> GCP_PROJECT_ID=<proj>"
	@echo "    make aws-deploy   RM_NUMBER=<rm> HOSTED_ZONE_ID=<id> GCP_SITE_IP=<ip>"
	@echo ""
	@echo "  Status:"
	@echo "    make aws-status   RM_NUMBER=<rm>"
	@echo "    make gcp-status   RM_NUMBER=<rm> GCP_PROJECT_ID=<proj>"
	@echo ""

aws-up:
	@echo "▶ [AWS=UP] Liberando porta 80 no Security Group $(EC2_SG_NAME)..."
	$(eval SG_ID := $(shell aws ec2 describe-security-groups \
		--region $(AWS_REGION) \
		--filters "Name=group-name,Values=$(EC2_SG_NAME)" \
		--query "SecurityGroups[0].GroupId" \
		--output text))
	@echo "  Security Group ID: $(SG_ID)"
	@aws ec2 authorize-security-group-ingress \
		--region $(AWS_REGION) \
		--group-id $(SG_ID) \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 2>/dev/null \
		&& echo "  ✅ Porta 80 LIBERADA — AWS volta como PRIMARY em ~30-60s" \
		|| echo "  ℹ️  Porta 80 já estava liberada"

aws-down:
	@echo "▶ [AWS=DOWN] Bloqueando porta 80 no Security Group $(EC2_SG_NAME)..."
	$(eval SG_ID := $(shell aws ec2 describe-security-groups \
		--region $(AWS_REGION) \
		--filters "Name=group-name,Values=$(EC2_SG_NAME)" \
		--query "SecurityGroups[0].GroupId" \
		--output text))
	@echo "  Security Group ID: $(SG_ID)"
	@aws ec2 revoke-security-group-ingress \
		--region $(AWS_REGION) \
		--group-id $(SG_ID) \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 2>/dev/null \
		&& echo "  🔴 Porta 80 BLOQUEADA — failover para GCP ativado em ~30-60s" \
		|| echo "  ℹ️  Porta 80 já estava bloqueada"

google-up:
	@echo "▶ [GOOGLE=UP] Habilitando regra de firewall $(GCP_FIREWALL)..."
	gcloud compute firewall-rules update $(GCP_FIREWALL) \
		--no-disabled \
		--project $(GCP_PROJECT_ID)
	@echo "  ✅ Porta 80 LIBERADA no GCP — servidor backup acessível"

google-down:
	@echo "▶ [GOOGLE=DOWN] Desabilitando regra de firewall $(GCP_FIREWALL)..."
	gcloud compute firewall-rules update $(GCP_FIREWALL) \
		--disabled \
		--project $(GCP_PROJECT_ID)
	@echo "  🔴 Porta 80 BLOQUEADA no GCP — servidor backup inacessível"

aws-status:
	@echo "▶ [AWS STATUS] Instância e Security Group..."
	@aws ec2 describe-instances \
		--region $(AWS_REGION) \
		--filters "Name=tag:Name,Values=fiap-site-aws-rm$(RM_NUMBER)" \
		--query "Reservations[0].Instances[0].{Estado:State.Name,IP:PublicIpAddress}" \
		--output table
	$(eval SG_ID := $(shell aws ec2 describe-security-groups \
		--region $(AWS_REGION) \
		--filters "Name=group-name,Values=$(EC2_SG_NAME)" \
		--query "SecurityGroups[0].GroupId" \
		--output text))
	@echo "  Regras HTTP no SG $(EC2_SG_NAME) [$(SG_ID)]:"
	@aws ec2 describe-security-groups \
		--region $(AWS_REGION) \
		--group-ids $(SG_ID) \
		--query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]" \
		--output table

gcp-status:
	@echo "▶ [GCP STATUS] Instância e Firewall..."
	@gcloud compute instances describe $(GCP_INSTANCE) \
		--zone $(GCP_ZONE) \
		--project $(GCP_PROJECT_ID) \
		--format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP)"
	@gcloud compute firewall-rules describe $(GCP_FIREWALL) \
		--project $(GCP_PROJECT_ID) \
		--format="table(name,disabled,allowed[0].ports[0])"

gcp-deploy:
	@echo "▶ Deploy GCP via Terraform..."
	cd terraform/gcp && terraform init
	cd terraform/gcp && terraform apply \
		-var="rm_number=$(RM_NUMBER)" \
		-var="gcp_project_id=$(GCP_PROJECT_ID)" \
		-auto-approve
	@echo "✅ GCP deploy concluído. Anote o valor de gcp_instance_external_ip acima."

aws-deploy:
	@echo "▶ Deploy AWS via Terraform..."
	cd terraform/aws && terraform init
	cd terraform/aws && terraform apply \
		-var="rm_number=$(RM_NUMBER)" \
		-var="hosted_zone_id=$(HOSTED_ZONE_ID)" \
		-var="gcp_site_ip=$(GCP_SITE_IP)" \
		-auto-approve
	@echo "✅ AWS deploy concluído."

aws-destroy:
	cd terraform/aws && terraform destroy \
		-var="rm_number=$(RM_NUMBER)" \
		-var="hosted_zone_id=$(HOSTED_ZONE_ID)" \
		-var="gcp_site_ip=$(GCP_SITE_IP)" \
		-auto-approve

gcp-destroy:
	cd terraform/gcp && terraform destroy \
		-var="rm_number=$(RM_NUMBER)" \
		-var="gcp_project_id=$(GCP_PROJECT_ID)" \
		-auto-approve
