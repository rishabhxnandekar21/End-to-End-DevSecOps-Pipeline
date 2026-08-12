pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
    GITLEAKS = 'C:\\Tools\\gitleaks\\gitleaks.exe'
    DEPENDENCY_CHECK = 'C:\\Tools\\dependency-check\\bin\\dependency-check.bat'
}

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

        stage('GitLeaks Scan') {
            steps {
                bat '"%GITLEAKS%" dir . --verbose'
            }
        }

        stage('Dependency-Check Verify') {
            steps {
                bat '"%DEPENDENCY_CHECK%" --version'
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

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        bat "\"${scannerHome}\\bin\\sonar-scanner.bat\""
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {

        success {
            archiveArtifacts(
                artifacts: 'client/dist/**',
                fingerprint: true
            )

            echo '========================================'
            echo ' Jenkins CI Pipeline Successful!'
            echo ' GitLeaks: PASSED'
            echo ' SonarQube: PASSED'
            echo ' Quality Gate: PASSED'
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