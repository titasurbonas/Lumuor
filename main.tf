# ToDo create ecs cluster, create containers and move all all  
# variables to vars.tf

provider "aws"{
	region = var.aws_region
}

module vpc{
	source = "./modules/vpc"
	cidr_block = "10.206.104.192/27"
	vpc_name= "test_vpc_exercise"
	availability_zone = ["${var.aws_region}a"]
	ip_subnets_private = var.ip_subnets_private
	ip_subnets_public = var.ip_subnets_public
	enable_dhcp_options = true
}

# remove commends and attach file for public ssh key 
# resource "aws_key_pair" "ecs" {
#   key_name   = "exercise_ssh"
#   public_key = file("C:/Users/titas/ssh-key/public")
# }

resource "aws_launch_configuration" "ecs" {
  name                 = "ecs"
  image_id             = "ami-0a7c31280fbd23a86"
  instance_type        = "t2.micro"
  key_name             = "ecs_exercise_lu"
  iam_instance_profile = aws_iam_instance_profile.ecs.id
  security_groups      = [aws_security_group.ecs.id]
  user_data            = file("user_data.sh")
}


resource "aws_autoscaling_group" "ecs" {
  name                 = "ecs-asg"
  launch_configuration = aws_launch_configuration.ecs.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
	vpc_zone_identifier  = module.vpc.public_subnet_id
}

#ToDo open port for jenkins 8080
resource "aws_security_group" "ecs" {
  name = "ecs-sg"
	vpc_id      = module.vpc.vpc_id
  description = "Container Instance Allowed Ports"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags ={
    Name = "ecs-sg"
  }
}

################
# IAM resources
################
resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-instance-profile"
  path = "/"
  role = aws_iam_role.ecs_role.name
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name     = "ecs_service_role_policy"
  policy   = data.template_file.ecs_service_role_policy.rendered
  role     = aws_iam_role.ecs_role.id
}


resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name     = "ecs_instance_role_policy"
  policy   = file("policy/ecs-instance-role-policy.json")
  role     = aws_iam_role.ecs_role.id
}

data "template_file" "ecs_service_role_policy" {
  template = file("policy/ecs-service-role-policy.json")
  vars= {
    s3_bucket = "test-s3"
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = file("policy/ecs-role.json")
}

