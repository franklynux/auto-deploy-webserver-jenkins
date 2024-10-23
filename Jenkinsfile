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
                        echo "Docker system status:"
                        docker info
                    '''
                    
                    echo "Building Docker Image: ${DOCKER_IMAGE}"
                    
                    // Build the image with detailed output
                    def buildStatus = sh(script: """
                        docker build -t ${DOCKER_IMAGE} . --no-cache --progress=plain || {
                            echo "Build failed with status: \$?"
                            exit 1
                        }
                    """, returnStatus: true)
                    
                    // Check build status
                    if (buildStatus != 0) {
                        error "Docker image build failed with status: ${buildStatus}"
                    }
                    
                    // Debug: Show images after build
                    sh '''
                        echo "Docker images after build:"
                        docker images
                        echo "Specifically searching for our image:"
                        docker images | grep franklynux/e-commerce-web || true
                    '''
                    
                    // Modified image verification
                    def imageExists = sh(script: """
                        if docker image inspect ${DOCKER_IMAGE} >/dev/null 2>&1; then
                            echo "Image found successfully"
                            exit 0
                        else
                            echo "Image not found"
                            exit 1
                        fi
                    """, returnStatus: true)
                    
                    if (imageExists != 0) {
                        error """
                            Docker image was not found after build!
                            Expected image: ${DOCKER_IMAGE}
                            Current images:
                            \$(docker images)
                        """
                    }
                    
                    echo "Docker image built and verified successfully"
                }
            }
        }

        // ... rest of the pipeline stages remain the same ...
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