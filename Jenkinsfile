pipeline {
    agent any
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