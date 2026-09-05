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

        DOCKER_USERNAME = 'rishabhxnandekar'
        BACKEND_IMAGE = 'rishabhxnandekar/devsecops-backend'
        FRONTEND_IMAGE = 'rishabhxnandekar/devsecops-frontend'
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
                bat '''
                    echo ========================================
                    echo Building Backend Docker Image
                    echo ========================================

                    docker build ^
                        -t %BACKEND_IMAGE%:v1-build-%BUILD_NUMBER% ^
                        -t %BACKEND_IMAGE%:latest ^
                        ./api

                    echo.
                    echo ========================================
                    echo Building Frontend Docker Image
                    echo ========================================

                    docker build ^
                        -t %FRONTEND_IMAGE%:v1-build-%BUILD_NUMBER% ^
                        -t %FRONTEND_IMAGE%:latest ^
                        ./client

                    echo.
                    echo Docker images built successfully.
                '''
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
                    echo ========================================
                    echo Scanning Backend Image
                    echo ========================================

                    "%TRIVY%" image ^
                    --severity HIGH,CRITICAL ^
                    %BACKEND_IMAGE%:v1-build-%BUILD_NUMBER%

                    echo.
                    echo ========================================
                    echo Scanning Frontend Image
                    echo ========================================

                    "%TRIVY%" image ^
                    --severity HIGH,CRITICAL ^
                    %FRONTEND_IMAGE%:v1-build-%BUILD_NUMBER%
                '''
            }
        }

        stage('Docker Hub Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-test-new',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    bat '''
                        echo ========================================
                        echo Configuring Docker Hub Authentication
                        echo ========================================

                        if not exist "%WORKSPACE%\\.docker" mkdir "%WORKSPACE%\\.docker"

                        powershell -NoProfile -Command "$auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($env:DOCKER_USER + ':' + $env:DOCKER_PASSWORD)); $config = @{auths=@{'https://index.docker.io/v1/'=@{auth=$auth}}} | ConvertTo-Json -Depth 5; [IO.File]::WriteAllText('%WORKSPACE%\\.docker\\config.json', $config)"

                        set "DOCKER_CONFIG=%WORKSPACE%\\.docker"

                        echo.
                        echo ========================================
                        echo Pushing Backend Image
                        echo ========================================

                        docker push %BACKEND_IMAGE%:v1-build-%BUILD_NUMBER%
                        docker push %BACKEND_IMAGE%:latest

                        echo.
                        echo ========================================
                        echo Pushing Frontend Image
                        echo ========================================

                        docker push %FRONTEND_IMAGE%:v1-build-%BUILD_NUMBER%
                        docker push %FRONTEND_IMAGE%:latest

                        echo.
                        echo Docker images pushed successfully.
                    '''
                }
            }
        }

        stage('GitOps Manifest Update') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-push',
                        usernameVariable: 'GITHUB_USER',
                        passwordVariable: 'GITHUB_TOKEN'
                    )
                ]) {
                    bat '''
                        echo ========================================
                        echo Updating Kubernetes Image Tags
                        echo ========================================

                        powershell -NoProfile -Command ^
                        "(Get-Content 'k8s-manifests\\backend.yaml') -replace 'devsecops-backend:v1-build-[0-9]+', 'devsecops-backend:v1-build-%BUILD_NUMBER%' | Set-Content 'k8s-manifests\\backend.yaml'"

                        powershell -NoProfile -Command ^
                        "(Get-Content 'k8s-manifests\\frontend.yaml') -replace 'devsecops-frontend:v1-build-[0-9]+', 'devsecops-frontend:v1-build-%BUILD_NUMBER%' | Set-Content 'k8s-manifests\\frontend.yaml'"

                        echo.
                        echo ========================================
                        echo Updated Kubernetes Images
                        echo ========================================

                        findstr /C:"image:" k8s-manifests\\backend.yaml
                        findstr /C:"image:" k8s-manifests\\frontend.yaml

                        echo.
                        echo ========================================
                        echo Configuring Git
                        echo ========================================

                        git config user.name "jenkins-ci"
                        git config user.email "jenkins-ci@localhost"

                        echo.
                        echo ========================================
                        echo Git Status
                        echo ========================================

                        git status --short

                        echo.
                        echo ========================================
                        echo Committing GitOps Changes
                        echo ========================================

                        git add k8s-manifests\\backend.yaml
                        git add k8s-manifests\\frontend.yaml

                        git diff --cached --quiet

                        if %ERRORLEVEL% EQU 0 (
                            echo No Kubernetes manifest changes detected.
                            exit /b 0
                        )

                        git commit -m "Update Kubernetes images to v1-build-%BUILD_NUMBER%"

                        echo.
                        echo ========================================
                        echo Pushing GitOps Changes
                        echo ========================================

                        git remote set-url origin https://%GITHUB_USER%:%GITHUB_TOKEN%@github.com/rishabhxnandekar21/End-to-End-DevSecOps-Pipeline.git

                        git push origin HEAD:main

                        echo.
                        echo ========================================
                        echo GitOps Manifest Update Successful
                        echo ========================================
                    '''
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
            echo ' Jenkins CI/CD Pipeline Successful!'
            echo ' GitLeaks: PASSED'
            echo ' OWASP Dependency-Check: PASSED'
            echo ' SonarQube: PASSED'
            echo ' Quality Gate: PASSED'
            echo ' Frontend Build: PASSED'
            echo ' Backend Validation: PASSED'
            echo ' Docker Build: PASSED'
            echo ' Trivy: PASSED'
            echo ' Docker Hub Push: PASSED'
            echo ' GitOps Manifest Update: PASSED'
            echo ' Argo CD: AUTOMATED SYNC'
            echo '========================================'
        }

        failure {
            echo '========================================'
            echo ' Jenkins CI/CD Pipeline Failed!'
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