APP_NAME = kinesis_processor
APP_VERSION = 0.0.1

AWS_ECR_ACCOUNT_ID ?= 058264558303
AWS_ECR_REGION ?= eu-north-1
AWS_ECR_REPO = $(APP_NAME)

INFRA_DIR=../../

TAG ?= $(APP_VERSION)

.PHONY: docker/build docker/push docker/run docker/test repo/create infra/init infra/plan infra/apply infra/destroy

repo/create:
	aws ecr create-repository --repository-name $(APP_NAME) --region $(AWS_ECR_REGION)

docker/build:
	docker build --platform linux/amd64 -t $(APP_NAME):$(APP_VERSION) .

docker/push: docker/build
	aws ecr get-login-password --region $(AWS_ECR_REGION) | docker login --username AWS --password-stdin $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com
	docker tag $(APP_NAME):$(APP_VERSION) $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)
	docker push $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)

docker/run:
	docker run --platform linux/amd64 -p 9000:8080 $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)

docker/test:
	curl -XPOST 'http://localhost:9000/2015-03-31/functions/function/invocations' -d '{"Records": [{"kinesis": {"data": "eyJldmVudF91dWlkIjogIjhkMGNhYjNjLTM3ZjEtNGEwYy05ZDRhLWFkNzA2NWFhNTA4OCIsICJldmVudF9uYW1lIjogImxlc3NvbjpzdGFydGVkIiwgImNyZWF0ZWRfYXQiOiAxNzEwOTgwMjk4fQ=="}}]}'

infra/init:
	cd $(INFRA_DIR) && terraform init

infra/plan:
	cd $(INFRA_DIR) && terraform plan -var="env_name=$(TAG)"

infra/destroy:
	cd $(INFRA_DIR) && terraform destroy -var="env_name=$(TAG)"

infra/apply:
	cd $(INFRA_DIR) && terraform apply -var="env_name=$(TAG)"

deploy_all: docker/push infra/apply

deploy_fresh: repo/create docker/push infra/init infra/apply