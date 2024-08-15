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

        stage('Build image') {
            steps {
                sh '''
                   docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$APP_VERSION .
                '''
            }
        }

        stage('Deploy to ECR') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username $AWS_ACCESS_KEY_ID --password-stdin $AWS_DOCKER_REGISTRY
                        docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$APP_VERSION
                    '''
                }
            }
        }
    }
}