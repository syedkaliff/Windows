data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
} 

data "aws_ami" "windows" {
     most_recent = true     
filter {
       name   = "name"
       values = ["Windows_Server-2019-English-Full-Base-*"]  
  }     
filter {
       name   = "virtualization-type"
       values = ["hvm"]  
  }     
owners = ["801119661308"] # Canonical
}

resource "random_id" "mtc_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}
/*
data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_key_pair" "mtc_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}
*/
resource "aws_instance" "mtc_main" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.windows.id
  key_name               = "windows"
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet[count.index].id
  # user_data = templatefile("./main-userdata.tpl", {new_hostname = "mtc-main-${random_id.mtc_node_id[count.index].dec}"})
 user_data = <<EOF
<powershell>
$admin = [adsi]("WinNT://./administrator, user")
$admin.PSBase.Invoke("SetPassword", "myTempPassword123!")
Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
</powershell>
EOF
  root_block_device {
    volume_size = var.main_vol_size
  }
  tags = {
    Name = "mtc-main-${random_id.mtc_node_id[count.index].dec}"
  }

  /*
  provisioner "local-exec" {
   # command = "printf '\n${self.public_ip} ansible_user=ubuntu' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-1"
    command = <<-EOT
    printf '%s\n' 2a '${self.public_ip} . x | ex aws_hosts 
    # printf '%s\n' 2a '${self.public_ip} ansible_user=administrator' . x | ex aws_hosts 
    # aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-1
    EOT
         
  } 
  */

   provisioner "local-exec" {
    command = printf '%s\n' 2a '${self.public_ip} ansible_user=administrator' . x | ex aws_hosts 
     #"printf '\n${self.public_ip}' >> aws_hosts"
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  } 
}

# resource "null_resource" "grafana_update" {
#   count = var.main_instance_count
#   provisioner "remote-exec" {
#     inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I updated Grafana' >> upgrade.log"]

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("/home/ubuntu/.ssh/mtckey")
#       host        = aws_instance.mtc_main[count.index].public_ip
#     }
#   }
# }

#resource "null_resource" "grafana_install" {
#  depends_on = [aws_instance.mtc_main]
 # provisioner "local-exec" {
#    command = "ansible-playbook -i aws_hosts --key-file /home/syed/.ssh/windows.pem /var/lib/jenkins/workspace/aws-new/playbooks/windows.yml"
#  }
#}

output "grafana_access" {
  value = { for i in aws_instance.mtc_main[*] : i.tags.Name => "${i.public_ip}:3000" }
}

output "instance_ips" {
  value = [for i in aws_instance.mtc_main[*]: i.public_ip]
}

output "instance_ids" {
  value = [for i in aws_instance.mtc_main[*]: i.id]
}
