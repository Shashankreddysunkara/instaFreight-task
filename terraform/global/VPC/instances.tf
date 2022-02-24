data "aws_ami" "ubuntu" {
most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
 }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
   
#   owners = ["${data.aws_caller_identity.current.account_id}"] # Canonical

# data "aws_caller_identity" "current" {
# }
}


# Create the user-data for the Consul server
data "template_file" "consul_server" {
  count    = 3
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
    consul_version = var.consul_version
    config = <<EOF
     "node_name": "ops-consul-server-${count.index+1}",
     "server": true,
     "bootstrap_expect": 3,
     "ui": true,
     "bind_addr": "0.0.0.0",
     "client_addr": "0.0.0.0"
    EOF
  }
}

# Create the user-data for the Consul agent
data "template_cloudinit_config" "consul_server" {
  count    = 3
  part {
    content = file("${path.module}/templates/inst_node_exporter.sh.tpl")
  }
  
  part {
    content = file("${path.module}/templates/install_python.sh.tpl")
  }

  part {
    content = element(data.template_file.consul_server.*.rendered, count.index)

  }
}

data "template_file" "consul_jenkins_master" {
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
      consul_version = var.consul_version
      config = <<EOF
       "node_name": "ops-jenkins-master",
       "enable_script_checks": true,
       "client_addr": "0.0.0.0",
       "bind_addr": "0.0.0.0",
       "server": false
      EOF
  }
}

# Create the user-data for the Consul agent
data "template_cloudinit_config" "consul_jenkins_master" {
  part {
    content = data.template_file.consul_jenkins_master.rendered
  }
  part {
    content = file("${path.module}/templates/inst_node_exporter.sh.tpl")
  }
  part {
    content = file("${path.module}/templates/jenkins_master.sh.tpl")
  }
}


data "template_file" "consul_jenkins_node" {
  template = file("${path.module}/templates/consul_jenkins.sh.tpl")

  vars = {
      consul_version = var.consul_version
      config = <<EOF
       "node_name": "ops-jenkins-node",
       "enable_script_checks": true,
       "client_addr": "0.0.0.0",
       "bind_addr": "0.0.0.0",
       "server": false
      EOF
  }
}

# Create the user-data for the Consul agent
data "template_cloudinit_config" "consul_jenkins_node" {
  part {
    content = file("${path.module}/templates/install_python.sh.tpl")
  }
  
  part {
    content = file("${path.module}/templates/inst_node_exporter.sh.tpl")
  }
  
  part {
    content = data.template_file.consul_jenkins_node.rendered

  }
  part {
    content = file("${path.module}/templates/jenkins_node.sh.tpl")
  }
}

data "template_file" "consul_mysql" {
  count    = 1
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
      consul_version = var.consul_version
      config = <<EOF
       "node_name": "ops-mysql-server-${count.index+1}",
       "enable_script_checks": true,
       "client_addr": "0.0.0.0",
       "bind_addr": "0.0.0.0",
       "server": false
      EOF
  }
}

# Create the user-data for the Consul agent
data "template_cloudinit_config" "consul_mysql" {
  count    = 1
  part {
    content = file("${path.module}/templates/inst_node_exporter.sh.tpl")
  }
  
  part {
    content = file("${path.module}/templates/install_python.sh.tpl")
  }

  part {
    content = element(data.template_file.consul_mysql.*.rendered, count.index)

  }
  part {
    content = file("${path.module}/templates/mysql.sh.tpl")
  }
}


data "template_file" "consul_ELK" {
  template = file("${path.module}/templates/consul.sh.tpl")

  vars = {
      consul_version = var.consul_version
      config = <<EOF
       "node_name": "ops-elk-server",
       "enable_script_checks": true,
       "client_addr": "0.0.0.0",
       "bind_addr": "0.0.0.0",
       "server": false
      EOF
  }
}


# Create the user-data for the Consul agent
data "template_cloudinit_config" "consul_ELK" {

  part {
    content = file("${path.module}/templates/inst_node_exporter.sh.tpl")
  }
  
  part {
    content = file("${path.module}/templates/install_python.sh.tpl")
  }

  part {
    content = data.template_file.consul_ELK.rendered

  }
  part {
    content = file("${path.module}/templates/ELK.sh.tpl")
  }
}


resource "aws_instance" "ubuntu-nodes" {
 
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.jenkins-sg.id, aws_security_group.ops_consul.id]
  key_name               = aws_key_pair.VPC-demo-key.key_name
  iam_instance_profile = aws_iam_instance_profile.eks-kubectl.name
  subnet_id = aws_subnet.private.1.id
  # associate_public_ip_address = true
  user_data = data.template_cloudinit_config.consul_jenkins_node.rendered

  tags = {
    Name = "Jenkins Ubuntu Node"
  }
}

resource "aws_instance" "jenkins_server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.jenkins-sg.id, aws_security_group.ops_consul.id]
  key_name               = aws_key_pair.VPC-demo-key.key_name
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  subnet_id = aws_subnet.private.0.id
  # associate_public_ip_address = true
  user_data = data.template_cloudinit_config.consul_jenkins_master.rendered

  tags = {
    Name = "Jenkins Server"
  }
}


# Create the Consul cluster
resource "aws_instance" "consul_server" {
  count = 3

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.VPC-demo-key.key_name
  subnet_id = element(aws_subnet.private.*.id, count.index)

  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.ops_consul.id]
  depends_on = [aws_nat_gateway.nat]

  tags = {
    Name = "consul-server-${count.index+1}"
    consul_server = "true"
  }

  user_data = element(data.template_cloudinit_config.consul_server.*.rendered, count.index)
}


resource "aws_instance" "db-server" {
 count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.mysql-sg.id, aws_security_group.ops_consul.id]
  key_name               = aws_key_pair.VPC-demo-key.key_name
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  subnet_id = element(aws_subnet.private.*.id, count.index)
  user_data = element(data.template_cloudinit_config.consul_mysql.*.rendered, count.index)

  tags = {
    Name = "mysql-server-${count.index+1}"
  }
}

# Allocate the bastion instance
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.public.0.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.VPC-demo-key.key_name

  associate_public_ip_address = true

  tags = {
    Name  = "bastion-server"
  }
}

resource "aws_instance" "ELK-server" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"

  vpc_security_group_ids = [aws_security_group.elk_sg.id, aws_security_group.ops_consul.id]
  key_name               = aws_key_pair.VPC-demo-key.key_name
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  subnet_id = aws_subnet.private.1.id

  user_data = data.template_cloudinit_config.consul_ELK.rendered

  tags = {
    Name = "ELK Server"
  }
}



data "template_file" "dev_hosts" {
  template = "${file("dev_hosts.cfg")}"
 
  depends_on = [
    aws_instance.jenkins_server,
    aws_instance.ubuntu-nodes,
    aws_instance.db-server,
    aws_instance.ELK-server,
    aws_instance.consul_server
  ]
  vars = {
    jenkins_server = aws_instance.jenkins_server.private_ip
    ubuntu_nodes = aws_instance.ubuntu-nodes.private_ip
    ELK_server = aws_instance.ELK-server.private_ip
    db_servers = "${join("\n", [for instance in aws_instance.db-server : instance.private_ip] )}"
    consul_servers = "${join("\n", [for instance in aws_instance.consul_server : instance.private_ip] )}"
  }
}

resource "null_resource" "host_file" {
  triggers = {
    template_rendered = data.template_file.dev_hosts.rendered
  }
  provisioner "local-exec" {
    command = "echo \"${data.template_file.dev_hosts.rendered}\" > hosts.INI"
  }
}

data "template_file" "ssh_config" {
  template = "${file("ssh_config.cfg")}"
 
  depends_on = [
    aws_instance.bastion
  ]
  vars = {
    bastion_server = aws_instance.bastion.public_ip
  }
}

resource "null_resource" "ssh_config" {
  triggers = {
    template_rendered = data.template_file.ssh_config.rendered
  }
  provisioner "local-exec" {
    command = "echo \"${data.template_file.ssh_config.rendered}\" > ssh_config"
  }
}


