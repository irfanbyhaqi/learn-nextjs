#!/bin/bash

CLUSTER_NAME="nextjs-ecs-cluster"
STACK_NAME="nextjs-ecs-stack"
SERVICE_NAME="nextjs-ecs-service"
TASK_DEFINITION_NAME="nextjs-task-definition"
CONTAINER_NAME="nextjs-server"
TASK_ROLE_ARN="arn:aws:iam::339712697129:role/ecsTaskExecutionRole" # Ganti dengan ARN role IAM Anda

while getopts ":i:" opt; do
  case ${opt} in
    i ) CONTAINER_IMAGE=$OPTARG;;
    \? ) echo "Usage: cmd [-i] <image>"
        exit;;
  esac
done

if [ -z "$CONTAINER_IMAGE" ]; then
  echo "Image are required. use '-i <image>'"
  exit 1
fi


CLUSTER_EXIST=$(aws ecs describe-clusters --cluster $CLUSTER_NAME --query "clusters[?status=='ACTIVE'].clusterName" --output text)

if [ "$CLUSTER_EXIST" == "$CLUSTER_NAME" ] 
then
    echo "Cluster $CLUSTER_NAME already exists"

    sed -e "s|#CONTAINER_NAME#|$CONTAINER_NAME|g" \
        -e "s|#CONTAINER_IMAGE#|$CONTAINER_IMAGE|g" \
        -e "s|#TASK_DEFINITION_NAME#|$TASK_DEFINITION_NAME|g" \
        -e "s|#TASK_ROLE_ARN#|$TASK_ROLE_ARN|g" aws/task-defination.json > /tmp/task-defination.json

    LAST_REVISION=$(aws ecs register-task-definition \
    --cli-input-json file:///tmp/task-defination.json \
    | jq '.taskDefinition.revision')

    aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $TASK_DEFINITION_NAME:$LAST_REVISION
    
    echo "Service $SERVICE_NAME updated .."
    aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME
    echo "Service running"

else
    echo "Creating cluster $CLUSTER_NAME"

    sed "s|#CLUSTER_NAME#|$CLUSTER_NAME|g" aws/create-cluster.json > /tmp/create-cluster.json

    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file:///tmp/create-cluster.json \
        --capabilities CAPABILITY_NAMED_IAM

    echo "Menunggu hingga stack selesai dibuat..."
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

    echo "Cluster ECS '$CLUSTER_NAME' berhasil dibuat."

    #2. Membuat Task Definition
    echo "Membuat Task Definition '$TASK_DEFINITION_NAME'..."
    sed -e "s|#CONTAINER_NAME#|$CONTAINER_NAME|g" \
        -e "s|#CONTAINER_IMAGE#|$CONTAINER_IMAGE|g" \
        -e "s|#TASK_DEFINITION_NAME#|$TASK_DEFINITION_NAME|g" \
        -e "s|#TASK_ROLE_ARN#|$TASK_ROLE_ARN|g" aws/task-defination.json > /tmp/task-defination.json

    TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
    --cli-input-json file:///tmp/task-defination.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

    echo "Task Definition '$TASK_DEFINITION_NAME' berhasil dibuat dengan ARN: $TASK_DEFINITION_ARN"

    # 3. Membuat Service
    echo "Membuat Service '$SERVICE_NAME'..."
    aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_DEFINITION_ARN \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0133dddee9c12078b],securityGroups=[sg-022931bf0da8a404f],assignPublicIp=ENABLED}"

    echo "Service '$SERVICE_NAME' berhasil dibuat."
    echo "Service menunggu running"
    aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME
    echo "Service running"

fi

