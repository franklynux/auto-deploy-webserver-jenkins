pipeline {
    agent any

    environment {
        EC2_IP = '3.86.157.149'
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

                    // Debug: Show current images before build
                    sh '''
                        echo "Current Docker images before build:"
                        docker images
                    '''

                    echo "Building Docker Image: ${DOCKER_IMAGE}"

                    // Build the image with basic command
                    def buildStatus = sh(script: """
                        # Remove any existing image with the same tag
                        docker rmi ${DOCKER_IMAGE} || true

                        # Build new image
                        docker build -t ${DOCKER_IMAGE} . --no-cache
                    """, returnStatus: true)

                    // Check build status
                    if (buildStatus != 0) {
                        error "Docker image build failed with status: ${buildStatus}"
                    }

                    // Verify the image exists
                    def verifyCmd = """
                        echo "Verifying image build..."
                        docker images | grep ${DOCKER_IMAGE.split(':')[0]} | grep ${DOCKER_IMAGE.split(':')[1]} || {
                            echo "Failed to find newly built image"
                            exit 1
                        }
                    """

                    def verifyStatus = sh(script: verifyCmd, returnStatus: true)

                    if (verifyStatus != 0) {
                        error """
                            Failed to verify Docker image build!
                            Expected image: ${DOCKER_IMAGE}
                            Current images:
                            \$(docker images)
                        """
                    }

                    echo "Docker image built and verified successfully"

                    // Show final image list
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
                    sshagent([EC2_INSTANCE_KEY]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                                docker pull ${DOCKER_IMAGE} || { echo "Failed to pull latest image!"; exit 1; }
                                docker stop e-commerce-web || true
                                docker rm e-commerce-web || true
                                docker run -d --name e-commerce-web -p 80:80 ${DOCKER_IMAGE} || { echo "Failed to start container!"; exit 1; }
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
