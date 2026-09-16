pipeline {
    agent any
    
    environment {
        // Replace with your exact DockerHub username credentials
        DOCKER_HUB_REGISTRY = "namodharani/trend-app"
        AWS_REGION          = "us-east-1"
        EKS_CLUSTER_NAME    = "trend-cluster"
    }
    
    stages {
        stage('Pull Codebase') {
            steps {
                // Wipe the workspace clean before pulling code to prevent cache contamination
                cleanWs()
                checkout scm
            }
        }
        
        stage('Docker Image Build') {
            steps {
                script {
                    // Compile the container layout target defined in your custom Dockerfile
                    trendImage = docker.build("${DOCKER_HUB_REGISTRY}:${BUILD_NUMBER}")
                }
            }
        }
        
                       stage('DockerHub Registry Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials-id', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        // 1. Authenticate natively via the Docker CLI
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        
                        // 2. Map the local image to the explicit latest tag format (This was missing!)
                        sh "docker tag ${DOCKER_HUB_REGISTRY}:${BUILD_NUMBER} ${DOCKER_HUB_REGISTRY}:latest"
                        
                        // 3. Push both the versioned and latest tag assets up to Docker Hub
                        sh "docker push ${DOCKER_HUB_REGISTRY}:${BUILD_NUMBER}"
                        sh "docker push ${DOCKER_HUB_REGISTRY}:latest"
                    }
                }
            }
        }


        
               stage('Kubernetes Infrastructure Sync') {
            steps {
                script {
                    // Update deployment manifest dynamically to match the current build tag number
                    sh "sed -i 's|DOCKERHUB_USERNAME/trend-app:latest|${DOCKER_HUB_REGISTRY}:${BUILD_NUMBER}|g' k8s/deployment.yaml"

                    
                    // Point kubectl securely to your active AWS cluster
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                    
                    // Deploy your resources dynamically
                    sh "kubectl apply -f k8s/deployment.yaml"
                    sh "kubectl apply -f k8s/service.yaml"
                }
            }
        }
    }
}
