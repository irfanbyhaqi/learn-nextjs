pipeline {
    agent any
    stages {
        stage('Build') {
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