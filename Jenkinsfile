pipeline{
    
    agent {
        node {
            label 'AGENT-1'
        }
    }

    options {
        ansiColor('xterm')
    }

    parameters {
        string(name: 'version', defaultValue: '1.0.1', description: 'Which version to deploy')
    }

    stages{

       
        stage('Deployment') {
            steps{
                echo 'Deploying...'
                echo "version from param : ${params.version}"
            }
        }

        stage('Init') {
            steps{
                sh """
                    cd terraform
                    terraform init -reconfigure
                """
            }
        }

        stage('Deployment') {
            steps{
                sh """
                    cd terraform
                    terraform plan -var="app_version=${params.version}"
                """
            }
            }
        }
    }

    post{
        always{
            echo 'Cleaning Up Workspace'
            deleteDir()
        }
    }






}