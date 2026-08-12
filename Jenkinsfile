pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        GITLEAKS = 'C:\\Tools\\gitleaks\\gitleaks.exe'
        DEPENDENCY_CHECK = 'C:\\Tools\\dependency-check\\bin\\dependency-check.bat'
        TRIVY = 'C:\\Tools\\trivy\\trivy.exe'

        JAVA_HOME = 'C:\\Users\\risha\\AppData\\Local\\Programs\\Eclipse Adoptium\\jdk-21.0.12.8-hotspot'
        PATH = "${JAVA_HOME}\\bin;${env.PATH}"
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

        stage('OWASP Dependency-Check') {
            steps {
                bat '''
                    "%DEPENDENCY_CHECK%" ^
                    --project "DevSecOps Task Manager" ^
                    --scan "." ^
                    --format HTML ^
                    --out "dependency-check-report" ^
                    --disableYarnAudit ^
                    --failOnCVSS 7
                '''
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
                        withCredentials([
                            string(
                                credentialsId: 'sonarqube-token',
                                variable: 'SONAR_TOKEN'
                            )
                        ]) {
                            bat "\"${scannerHome}\\bin\\sonar-scanner.bat\" -Dsonar.token=%SONAR_TOKEN%"
                        }
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

        stage('Docker Build') {
            steps {
                bat 'docker build -t devsecops-backend:ci ./api'
            }
        }

        stage('Trivy Verify') {
            steps {
                bat '"%TRIVY%" --version'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                bat '''
                    "%TRIVY%" image ^
                    --severity HIGH,CRITICAL ^
                    devsecops-backend:ci
                '''
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
            echo ' OWASP Dependency-Check: PASSED'
            echo ' SonarQube: PASSED'
            echo ' Quality Gate: PASSED'
            echo ' Docker Build: PASSED'
            echo ' Trivy: PASSED'
            echo '========================================'
        }

        failure {
            echo '========================================'
            echo ' Jenkins CI Pipeline Failed!'
            echo ' Check the Console Output.'
            echo '========================================'
        }

        always {
            archiveArtifacts(
                artifacts: 'dependency-check-report/dependency-check-report.html',
                allowEmptyArchive: true,
                fingerprint: true
            )

            echo 'Pipeline execution completed.'
        }
    }
}