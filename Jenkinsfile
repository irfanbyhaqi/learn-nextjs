pipeline {
    agent any
    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:alpine'
                    reuseNode true
                    args '-u root'
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version
                '''
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}