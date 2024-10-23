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
                    echo "Building Docker Image: ${DOCKER_IMAGE}"
                    
                    // Check Docker system status
                    sh 'docker info'
                    
                    def buildStatus = sh(script: "docker build -t ${DOCKER_IMAGE} . --no-cache", returnStatus: true)
                    
                    // Check if the build was successful
                    if (buildStatus != 0) {
                        error 'Docker image build failed!'
                    }
                    
                    // Verify the image creation and show all images
                    sh 'docker images'
                    def imageCheck = sh(script: "docker images | grep ${DOCKER_IMAGE}", returnStatus: true)
                    if (imageCheck != 0) {
                        error 'Docker image was not found after build!'
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing Docker Image to Docker Hub"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            # Debug steps
                            echo "Attempting to login to Docker Hub as $DOCKER_USER"
                            echo "Current Docker images:"
                            docker images
                            
                            # Login to Docker Hub with error checking
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin || {
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
                            
                            # Verify push success by trying to pull
                            echo "Verifying push by pulling image"
                            docker pull ${DOCKER_IMAGE} || {
                                echo "Failed to verify pushed image!"
                                exit 1
                            }
                        '''
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Deploying to EC2 Instance: ${EC2_IP}"
                    def deployCmd = """
                        docker pull ${DOCKER_IMAGE} || {
                            echo "Failed to pull latest image!"
                            exit 1
                        }
                        docker stop e-commerce-web || true
                        docker rm e-commerce-web || true
                        docker run -d --name e-commerce-web -p 80:80 ${DOCKER_IMAGE} || {
                            echo "Failed to start container!"
                            exit 1
                        }
                        echo "Container started successfully"
                    """
                    sshagent([EC2_INSTANCE_KEY]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '${deployCmd}'
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
                    docker info
                    echo "Remaining Docker images:"
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
                    echo "Docker system status at failure:"
                    docker info
                    echo "Docker images at failure:"
                    docker images
                '''
            }
        }
    }
}