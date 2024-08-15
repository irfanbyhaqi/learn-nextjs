pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-southeast-2'
    }

    stages {
        stage('Testing') {
            agent {
                docker {
                    image 'node:alpine'
                    reuseNode true
                    args '-u root'
                }
            }
            steps {
                sh '''
                    npm install
                    npm test
                '''
            }
        }

        stage('Build image') {
            agent {
                docker {
                    image 'node:alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                   echo "Build image"
                '''
            }
        }

        stage('Deploy to ECR') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        aws s3 ls
                    '''
                }
            }
        }
    }
}