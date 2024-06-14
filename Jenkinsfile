pipeline{
    
    agent {
        node {
            label 'AGENT-1'
        }
    }

    // options {
    //     ansiColor('xterm')
    // }

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

        stage('Plan') {
            steps{
                sh """
                    cd terraform
                    terraform plan -var="app_version=${params.version}"
                """
            }
        }

         stage('Approve') {
            input {
                message "Should we continue?"
                ok "Yes, we should."
                submitter "Rashid"
            }
             steps{
                echo "Approval Done"
            }
        }

         stage('Apply') {
            steps{
                sh """
                    cd terraform
                    terraform apply -auto-approve -var="app_version=${params.version}"
                """
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