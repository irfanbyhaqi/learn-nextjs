pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            reuseNode true
            args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_VERSION = "1.0.$BUILD_NUMBER"
        AWS_DEFAULT_REGION = 'ap-southeast-2'
        APP_NAME = 'nextjs-docker'
        AWS_DOCKER_REGISTRY = '339712697129.dkr.ecr.ap-southeast-2.amazonaws.com'
    }

    stages {
        stage('Testing') {
            steps {
                sh '''
                    npm install
                    npm test
                '''
            }
        }
        stage('Install Docker CLI') {
            steps {
                sh '''
                    apk add --no-cache docker-cli
                '''
            }
        }
        stage('Build AWS CLI Image'){
            steps {
                sh '''
                    docker build . -t aws-cli -f ci/Dockerfile-aws-cli
                '''
            }
        }
        stage('Build APP image') {
            steps {
                sh '''
                   docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$APP_VERSION .
                '''
            }
        }

        stage('Deploy to ECR') {
            agent {
                docker {
                    image 'aws-cli'
                    reuseNode true
                    args "-v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_DOCKER_REGISTRY
                        docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$APP_VERSION
                    '''
                }
            }
        }

        stage('Deploy to ECS') {
            agent {
                docker {
                    image 'aws-cli'
                    reuseNode true
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    dir('bash'){
                        sh "chmod +x create-ecs-service.sh"
                        sh "./create-ecs-service.sh -i $AWS_DOCKER_REGISTRY/$APP_NAME:$APP_VERSION"
                    }
                }
            }
        }
    }
}