resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  description = "Allow SSH inbound traffic from VPC"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
    # HTTP access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "jenkins-sg" {
 name        = "jenkins-sg"
 description = "security group for jenkins nodes"
 vpc_id      = aws_vpc.terra_vpc.id
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
   from_port   = 8
   to_port     = 0
   protocol    = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

# Create an IAM role for eks kubectl
resource "aws_iam_role" "eks-kubectl" {
  name               = "ops-eks-kubectl"
  assume_role_policy = file("policies/assume-role.json")
}

# Create the policy
resource "aws_iam_policy" "eks-kubectl" {
  name        = "ops-eks-kubectl"
  description = "Allows unubtu node to run kubectl."
  policy      = file("policies/describe-eks.json")
}

# Attach the policy
resource "aws_iam_policy_attachment" "eks-kubectl" {
  name       = "ops-eks-kubectl"
  roles      = [aws_iam_role.eks-kubectl.name]
  policy_arn = aws_iam_policy.eks-kubectl.arn
}

# Create the instance profile
resource "aws_iam_instance_profile" "eks-kubectl" {
  name  = "ops-eks-kubectl"
  role = aws_iam_role.eks-kubectl.name
}

resource "aws_security_group" "mysql-sg" {
  name        = "mysql-sg"
  description = "Allow ssh & mysql inbound traffic"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all inside security group"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ssh from the world"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow mysql from the world"
  }

  ingress {
    from_port   = 33062
    to_port     = 33062
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow mysql from the world"
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow https from the world"
  }

    ingress {
    from_port   = 9104
    to_port     = 9104
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow mysql exporter from the world"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow node exporter from the world"
  }
  
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow elasticsearch from the world"
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow kibana from the world"
  }

   ingress {
   from_port   = 8
   to_port     = 0
   protocol    = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow all outside security group"
  }
}

resource "aws_security_group" "bastion_sg" {
  name = "bastion_sg"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      # "100.67.11.109/32",
      "0.0.0.0/0"
    ]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ops_consul" {
  name        = "ops-consul"
  description = "Allow ssh & consul inbound traffic"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all inside security group"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ssh from the world"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http from the world"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http from the world"
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow https from the world"
  }

  ingress {
    from_port   = 8500  
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

    ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

   ingress {
    from_port   = 8500  
    to_port     = 8500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

    ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  
    ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  
   ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }  

  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  } 

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul DNS access from the world"
  }  

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul DNS access from the world"
  }  
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow node exporter access from the world"
  } 

  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul exporter access from the world"
  } 

  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul exporter access from the world"
  }  

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow elasticsearch from the world"
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow kibana from the world"
  }
  
   ingress {
   from_port   = 8
   to_port     = 0
   protocol    = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow all outside security group"
  }
}

resource "aws_security_group" "elk_sg" {
  name = "elk_sg"
  description = "All all elasticsearch traffic"
  vpc_id      = aws_vpc.terra_vpc.id

  # elasticsearch port
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # logstash port
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # kibana ports
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

#Monitoring Security Group
resource "aws_security_group" "monitor_sg" {
  name        = "monitor_sg"
  description = "Security group for monitoring server"
  vpc_id      = aws_vpc.terra_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP from control host IP
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all SSH External
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic to HTTP port 3000
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic to HTTP port 9090
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic to HTTP port 9100
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic to HTTP port 9104
  ingress {
    from_port   = 9104
    to_port     = 9104
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # Allow all traffic to HTTP port 5000
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul exporter access from the world"
  } 

  ingress {
    from_port   = 9107
    to_port     = 9107
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow consul exporter access from the world"
  }  
}
# Create an IAM role for the auto-join
resource "aws_iam_role" "consul-join" {
  name               = "ops-consul-join"
  assume_role_policy = file("${path.module}/policies/assume-role.json")
}

# Create the policy
resource "aws_iam_policy" "consul-join" {
  name        = "ops-consul-join"
  description = "Allows Consul nodes to describe instances for joining."
  policy      = file("${path.module}/policies/describe-instances.json")
}

# Attach the policy
resource "aws_iam_policy_attachment" "consul-join" {
  name       = "ops-consul-join"
  roles      = ["${aws_iam_role.consul-join.name}"]
  policy_arn = aws_iam_policy.consul-join.arn
}

# Create the instance profile
resource "aws_iam_instance_profile" "consul-join" {
  name  = "ops-consul-join"
  role = aws_iam_role.consul-join.name
}