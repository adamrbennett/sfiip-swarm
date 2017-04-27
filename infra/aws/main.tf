variable "account_id" {}
variable "access_key" {}
variable "secret_key" {}
variable "region" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "roles" {
  source = "./modules/roles"
}

module "vpc" {
  source = "./modules/vpc"
  region = "${var.region}"
}

resource "aws_elb" "infra" {
  name = "infra"
  internal = true
  subnets = [
    "${module.vpc.infra1a_subnet_id}",
    "${module.vpc.infra1b_subnet_id}"
  ]

  listener {
    instance_port     = 8300
    instance_protocol = "tcp"
    lb_port           = 8300
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8301
    instance_protocol = "tcp"
    lb_port           = 8301
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8302
    instance_protocol = "tcp"
    lb_port           = 8302
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 8500
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "TCP:8500"
    interval = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "sfiip-infra-elb"
  }
}

resource "aws_elb" "mgr" {
  name = "mgr"
  subnets = [
    "${module.vpc.pub1a_subnet_id}",
    "${module.vpc.pub1b_subnet_id}"
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/health"
    interval = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "sfiip-mgr-elb"
  }
}

resource "aws_opsworks_stack" "dev" {
  depends_on = [
    "module.roles",
    "module.vpc"
  ]
  name = "dev"
  region = "${var.region}"
  service_role_arn = "${module.roles.service_role_arn}"
  default_instance_profile_arn = "${module.roles.instance_profile_arn}"
  vpc_id = "${module.vpc.vpc_id}"
  default_subnet_id = "${module.vpc.wrk1a_subnet_id}"
  default_os = "Ubuntu 16.04 LTS"
  configuration_manager_name = "Chef"
  configuration_manager_version = "12"
  use_custom_cookbooks = true
  manage_berkshelf = true
  use_opsworks_security_groups = false
  color = "rgb(57, 131, 94)"
  custom_cookbooks_source {
    type = "s3",
    url = "https://s3.amazonaws.com/ps-cookbooks/cookbooks.tar.gz"
  }
}

resource "aws_opsworks_custom_layer" "pub" {
  name = "public"
  short_name = "pub"
  stack_id = "${aws_opsworks_stack.dev.id}"
  auto_assign_public_ips = true
  custom_security_group_ids = ["${module.vpc.vpc_default_security_group_id}"]
  custom_setup_recipes = [
    "consul_ps::client"
  ]
  custom_json = <<EOF
{
  "consul": {
    "version": "0.8.0",
    "config": {
      "ui": true,
      "datacenter": "${var.region}",
      "retry_join": ["${aws_elb.infra.dns_name}"],
      "ports": {
        "dns": 53
      },
      "recursors": [
        "8.8.8.8",
        "8.8.4.4"
      ]
    }
  }
}
EOF
}

resource "aws_opsworks_custom_layer" "infra" {
  name = "infrastructure"
  short_name = "infra"
  stack_id = "${aws_opsworks_stack.dev.id}"
  auto_assign_public_ips = false
  elastic_load_balancer = "${aws_elb.infra.name}"
  drain_elb_on_shutdown = true
  custom_security_group_ids = ["${module.vpc.vpc_default_security_group_id}"]
  custom_configure_recipes = [
    "docker_ps::default",
    "consul_ps::server"
  ]
  custom_json = <<EOF
{
  "consul": {
    "version": "0.8.0",
    "config": {
      "server": true,
      "bootstrap_expect": 3,
      "retry_join": ["infra1"],
      "datacenter": "${var.region}",
      "ports": {
        "dns": 53
      },
      "recursors": [
        "8.8.8.8",
        "8.8.4.4"
      ]
    }
  },
  "hashicorp-vault": {
    "config": {
      "backend_type": "consul",
      "backend_options": {
        "address": "127.0.0.1:8500"
      },
      "tls_disable": 1
    }
  }
}
EOF
}

resource "aws_opsworks_custom_layer" "mgr" {
  name = "manager"
  short_name = "mgr"
  stack_id = "${aws_opsworks_stack.dev.id}"
  auto_assign_public_ips = false
  elastic_load_balancer = "${aws_elb.mgr.name}"
  drain_elb_on_shutdown = true
  custom_security_group_ids = ["${module.vpc.vpc_default_security_group_id}"]
  custom_configure_recipes = [
    "docker_ps::default",
    "consul_ps::client",
    "docker_ps::registrator",
    "docker_ps::swarm_init",
    "docker_ps::swarm_bootstrap"
  ]
  custom_shutdown_recipes = [
    "docker_ps::swarm_leave"
  ]
  custom_json = <<EOF
{
  "docker_ps": {
    "docker": {
      "dns": "172.17.0.1"
    },
    "swarm": {
      "leader": "mgr1"
    },
    "registrator": {
      "command": "-internal -cleanup consul://127.0.0.1:8500"
    }
  },
  "aws_ps": {
    "ecr_helper": {
      "registry": "814258403605.dkr.ecr.us-east-1.amazonaws.com"
    }
  },
  "consul": {
    "version": "0.8.0",
    "config": {
      "datacenter": "${var.region}",
      "retry_join": ["${aws_elb.infra.dns_name}"],
      "ports": {
        "dns": 53
      },
      "recursors": [
        "8.8.8.8",
        "8.8.4.4"
      ]
    }
  }
}
EOF
}

resource "aws_opsworks_custom_layer" "wrk" {
  name = "worker"
  short_name = "wrk"
  stack_id = "${aws_opsworks_stack.dev.id}"
  auto_assign_public_ips = false
  custom_security_group_ids = ["${module.vpc.vpc_default_security_group_id}"]
  custom_configure_recipes = [
    "docker_ps::default",
    "consul_ps::client",
    "docker_ps::registrator",
    "docker_ps::swarm_join"
  ]
  custom_shutdown_recipes = [
    "docker_ps::swarm_leave"
  ]
  custom_json = <<EOF
{
  "docker_ps": {
    "docker": {
      "dns": "172.17.0.1"
    },
    "swarm": {
      "leader": "mgr1"
    },
    "registrator": {
      "command": "-internal -cleanup consul://127.0.0.1:8500"
    }
  },
  "aws_ps": {
    "ecr_helper": {
      "registry": "814258403605.dkr.ecr.us-east-1.amazonaws.com"
    }
  },
  "consul": {
    "version": "0.8.0",
    "config": {
      "datacenter": "${var.region}",
      "retry_join": ["${aws_elb.infra.dns_name}"],
      "ports": {
        "dns": 53
      },
      "recursors": [
        "8.8.8.8",
        "8.8.4.4"
      ]
    }
  }
}
EOF
}

resource "aws_opsworks_instance" "pub1" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.pub.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "pub1"
  subnet_id = "${module.vpc.pub1a_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "infra1" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.infra.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "infra1"
  subnet_id = "${module.vpc.infra1a_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "infra2" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.infra.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "infra2"
  subnet_id = "${module.vpc.infra1b_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "infra3" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.infra.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "infra3"
  subnet_id = "${module.vpc.infra1c_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "mgr1" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.mgr.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "mgr1"
  subnet_id = "${module.vpc.mgr1a_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "mgr2" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.mgr.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "mgr2"
  subnet_id = "${module.vpc.mgr1b_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "mgr3" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.mgr.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "mgr3"
  subnet_id = "${module.vpc.mgr1c_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "wrk1" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.wrk.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "wrk1"
  subnet_id = "${module.vpc.wrk1a_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "wrk2" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.wrk.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "wrk2"
  subnet_id = "${module.vpc.wrk1b_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}

resource "aws_opsworks_instance" "wrk3" {
  stack_id = "${aws_opsworks_stack.dev.id}"
  layer_ids = [
    "${aws_opsworks_custom_layer.wrk.id}"
  ]
  instance_type = "t2.micro"
  os = "Ubuntu 16.04 LTS"
  hostname = "wrk3"
  subnet_id = "${module.vpc.wrk1c_subnet_id}"
  virtualization_type = "hvm"
  root_device_type = "ebs"
}
