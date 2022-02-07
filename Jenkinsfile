pipeline {
    agent any
    environment {
    
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    tools {
        terraform 'TF'
    }
    stages {
        stage('Init') {
            steps {
                sh 'ls'
                sh 'terraform init -no-color'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan -no-color'
            }
        }
        stage('Validate Apply') {
            input {
                message "Do you want to Apply this plan?"
                ok "Apply"
            }
            steps {
                echo 'Apply Accepted'
            }
        }

        stage('Apply') {
            steps {
                sh 'terraform apply -auto-approve -no-color'
            }
        }
        
        stage('Inventory') {
          steps {
                sh '''printf \\
                    "\\n$(terraform output -json instance_ips | jq -r \'.[]\')" \\
                    >> aws_hosts'''
            }
        }
        stage('EC2 Wait') {
            steps {
                sh '''aws ec2 wait instance-status-ok \\
                      --instance-ids $(terraform output -json instance_ids | jq -r \'.[]\') \\
                      --region us-west-1'''
            }
        }
        
         stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible Approved'
            }
        }

        stage('Ansible') {
            steps {
                ansiblePlaybook(credentialsId: 'aws-ubuntu', inventory: 'aws_hosts', playbook: 'playbooks/windows.yml')
            }
        }
        
        stage('Validate Destroy') {
            input {
                message "Do you want to destroy?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
            }
        }

        stage('Destroy') {
            steps {
                sh 'terraform destroy -auto-approve -no-color'
            }
        }
    }
    
   post {
        success {
            echo 'Success!'
        }
        failure {
            sh 'terraform destroy -auto-approve -no-color'
        }
   aborted {
            sh 'terraform destroy -auto-approve -no-color'
        }

}
}
