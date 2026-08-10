pipeline {
    agent any

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                bat 'git --version'
                bat 'node -v'
                bat 'npm -v'
                bat 'docker --version'
                bat 'docker compose version'
            }
        }

        stage('Backend Dependencies') {
            steps {
                dir('api') {
                    bat 'npm install'
                }
            }
        }

        stage('Frontend Dependencies') {
            steps {
                dir('client') {
                    bat 'npm install'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('client') {
                    bat 'npm run build'
                }
            }
        }

        stage('Backend Validation') {
            steps {
                dir('api') {
                    bat 'node --check server.js'
                }
            }
        }
    }

    post {

        success {
            archiveArtifacts artifacts: 'client/dist/**',
                             fingerprint: true

            echo '========================================'
            echo ' Jenkins CI Pipeline Successful!'
            echo '========================================'
        }

        failure {
            echo '========================================'
            echo ' Jenkins CI Pipeline Failed!'
            echo ' Check the Console Output.'
            echo '========================================'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}