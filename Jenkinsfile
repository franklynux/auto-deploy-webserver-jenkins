pipeline {
    agent any

    environment {
        EC2_IP = '44.203.4.54'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "franklynux/e-commerce-web:${BUILD_NUMBER}"
        EC2_INSTANCE_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Fetch Code') {
            steps {
                script {
                    echo "Pulling source code from Git"
                    git branch: 'main', url: 'https://github.com/franklynux/Auto-Deploy-Ecommerce-Website.git'
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    echo "Installing Python dependencies"
                    sh '''
                        python3 -m pip install --upgrade pip
                        python3 -m pip install beautifulsoup4
                        # Add any other required packages here
                        python3 -m pip install requests
                    '''
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                script {
                    echo "Running Unit Tests"
                    sh 'python3 test_website.py'
                }
            }
            post {
                always {
                    script {
                        echo 'Post actions for Unit Tests stage'
                        // Uncomment and configure the following lines if applicable
                        
                        // junit 'test-results/*.xml'
                        
                        // publishHTML([
                        //     allowMissing: false,
                        //     alwaysLinkToLastBuild: true,
                        //     keepAll: true,
                        //     reportDir: 'coverage',
                        //     reportFiles: 'index.html',
                        //     reportName: 'Coverage Report',
                        //     reportTitles: 'Code Coverage'
                        // ])
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker Image: ${DOCKER_IMAGE}"
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing Docker Image to Docker Hub"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}"
                        sh "docker rmi ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Deploying to EC2 Instance: ${EC2_IP}"
                    def dockerCmd = """
                        docker pull ${DOCKER_IMAGE}
                        docker stop e-commerce-web || true
                        docker rm e-commerce-web || true
                        docker run -d --name e-commerce-web -p 80:80 ${DOCKER_IMAGE}
                    """
                    sshagent(['ec2-ssh-key']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '${dockerCmd}'"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Cleaning up workspace...'
                cleanWs()
                // Other post-build actions...
            }
        }
        success {
            script {
                echo 'Pipeline completed successfully!'
            }
        }
        failure {
            script {
                echo 'Pipeline failed. Check the logs for details.'
            }
        }
    }
}