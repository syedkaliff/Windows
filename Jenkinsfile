pipeline {
    agent any
   options { timestamps () }
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
             //   sh 'printf \'%s\\n\' 2a "$(terraform output -json instance_ips | jq -r \'.[]\') " . x | ex aws_hosts'
            //   sh 'terraform output -json instance_name | jq -r  \\.[] | sed \'s/.*/servername: &/\' >>playbooks/hostnames.yml'
              sh '''printf "$(terraform output -json hostnames | jq -r \'.\')" | tr -d \\"{}:\'\', |sed \'s/^[[:space:]]*//g\' >> /tmp/ansibleroles/hostfile'''
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
                ansiColor('xterm') {
                ansiblePlaybook(credentialsId: 'aws-ubuntu', inventory: 'hostfile', playbook: '/tmp/ansibleroles/master.yml', colorized: true )
            }
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
