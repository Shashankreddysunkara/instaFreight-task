# Create a new load balancer
resource "aws_elb" "jenkins-elb" {
  name               = "jenkins-elb"
  subnets = [aws_subnet.public.0.id]
  security_groups = [aws_security_group.jenkins-sg.id]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  instances                   = [aws_instance.jenkins_server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "jenkins-elb"
  }
}


resource "aws_elb" "ELK-elb" {
  name               = "ELK-elb"
  subnets = [aws_subnet.public.1.id]
  security_groups = [aws_security_group.elk_sg.id]

  listener {
    instance_port     = 5601
    instance_protocol = "http"
    lb_port           = 5601
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5601/status"
    interval            = 30
  }

  instances                   = [aws_instance.ELK-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "ELK-elb"
  }
}
