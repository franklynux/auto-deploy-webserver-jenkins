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
        
        stage('Basic Tests') {
            steps {
                script {
                    echo "Running basic file checks"
                    sh '''
                        echo "Current directory contents:"
                        ls -la
                        
                        # Check if websetup.sh exists and is executable
                        if [ -f "websetup.sh" ]; then
                            echo "✅ websetup.sh exists"
                            chmod +x websetup.sh
                            echo "✅ Made websetup.sh executable"
                        else
                            echo "❌ websetup.sh is missing"
                            exit 1
                        fi
                        
                        # Check if Dockerfile exists
                        if [ -f "Dockerfile" ]; then
                            echo "✅ Dockerfile exists"
                            echo "Dockerfile contents:"
                            cat Dockerfile
                        else
                            echo "❌ Dockerfile is missing"
                            exit 1
                        fi
                        
                        echo "All basic checks passed successfully! ✅"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker Image: ${DOCKER_IMAGE}"
                    sh """
                        docker build -t ${DOCKER_IMAGE} . --no-cache
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Pushing Docker Image to Docker Hub"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push ${DOCKER_IMAGE}
                            docker rmi ${DOCKER_IMAGE}
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
                        docker pull ${DOCKER_IMAGE}
                        docker stop e-commerce-web || true
                        docker rm e-commerce-web || true
                        docker run -d --name e-commerce-web -p 80:80 ${DOCKER_IMAGE}
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
            }
        }
    }
}