pipeline{
    
    agent {
        node {
            label 'AGENT-1'
        }
    }

    parameters {
        string(name: 'version', defaultValue: '1.0.1', description: 'Which version to deploy')
    }

    stages{

       
        stage('Deployment') {
            steps{
                echo 'Deploying to Server'
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