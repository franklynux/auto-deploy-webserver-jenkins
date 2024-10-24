pipeline {
    agent any

    environment {
        EC2_IP = '54.90.182.231'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "franklynux/e-commerce-web:${BUILD_NUMBER}"
        EC2_INSTANCE_KEY = credentials('ec2-ssh-key')
    }

    stages {
        stage('Fetch Code') {
            steps {
                script {
                    echo "Pulling source code from Git"
                    git branch: 'main', url: 'https://github.com/franklynux/auto-deploy-webserver-jenkins.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Starting Docker Image Build Stage"

                    // Show current Docker images before the build
                    sh '''
                        echo "Current Docker images before build:"
                        docker images
                    '''

                    echo "Building Docker Image: ${DOCKER_IMAGE}"
                    def buildStatus = sh(script: """
                        docker rmi ${DOCKER_IMAGE} || true
                        docker build -t ${DOCKER_IMAGE} . --no-cache
                    """, returnStatus: true)

                    if (buildStatus != 0) {
                        error "Docker image build failed with status: ${buildStatus}"
                    }

                    // Get image name and tag
                    def imageName = DOCKER_IMAGE.tokenize(':')[0]
                    def imageTag = DOCKER_IMAGE.tokenize(':')[1]

                    // Verify the newly built image
                    sh """
                        docker images | grep ${imageName} | grep ${imageTag} || {
                            echo "Failed to find newly built image"
                            exit 1
                        }
                    """
                    echo "Docker image built and verified successfully"

                    // Show final image list after build
                    sh '''
                        echo "Docker images after successful build:"
                        docker images
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing Docker Image to Docker Hub"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo "Logging into Docker Hub..."
                            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin || {
                                echo "Docker Hub login failed!"
                                exit 1
                            }

                            echo "Pushing image: ${DOCKER_IMAGE}"
                            docker push ${DOCKER_IMAGE} || {
                                echo "Docker push failed!"
                                exit 1
                            }

                            echo "Cleaning up local image"
                            docker rmi ${DOCKER_IMAGE} || echo "Warning: Failed to remove local image"
                        """
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Deploying to EC2 Instance: ${EC2_IP}"
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                                # Check if Docker is installed, if not, install it
                                if ! [ -x "\$(command -v docker)" ]; then
                                    echo "Docker not found, installing Docker..."
                                    sudo apt update
                                    sudo apt install -y docker.io
                                    sudo systemctl start docker
                                    sudo systemctl enable docker
                                    sudo usermod -aG docker ubuntu
                                    echo "Docker installed successfully"
                                else
                                    echo "Docker already installed"
                                fi

                                # Use sudo for Docker commands to avoid permission issues
                                sudo docker pull ${DOCKER_IMAGE} || { echo "Failed to pull latest image!"; exit 1; }
                                sudo docker stop e-commerce-web || true
                                sudo docker rm e-commerce-web || true
                                sudo docker run -d --name e-commerce-web -p 80:80 ${DOCKER_IMAGE} || { echo "Failed to start container!"; exit 1; }
                            '
                        """
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
                sh '''
                    echo "Final Docker system status:"
                    docker images
                '''
            }
        }
        success {
            script {
                echo 'Pipeline completed successfully! ✅'
            }
        }
        failure {
            script {
                echo 'Pipeline failed. Check the logs for details. ❌'
                sh '''
                    echo "Docker images at failure:"
                    docker images
                '''
            }
        }
    }
}
