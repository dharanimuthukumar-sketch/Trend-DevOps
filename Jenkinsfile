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
                    // Connects using the secure credentials ID string stored inside your Jenkins dashboard
                    docker.withRegistry('https://docker.io', 'dockerhub-credentials-id') {
                        trendImage.push()
                        trendImage.push("latest")
                    }
                }
            }
        }
        
        stage('Kubernetes Infrastructure Sync') {
            steps {
                script {
                    // Dynamically swap the DOCKERHUB_USERNAME placeholder inside your manifest file
                    sh "sed -i 's|namodharani/trend-app:latest|${DOCKER_HUB_REGISTRY}:${BUILD_NUMBER}|g' k8s/deployment.yaml"
                    
                    // Point kubectl to talk to your live AWS EKS cluster plane
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                    
                    // Synchronize and apply your resource states onto Kubernetes node pods
                    sh "kubectl apply -f k8s/deployment.yaml"
                    sh "kubectl apply -f k8s/service.yaml"
                }
            }
        }
    }
}
