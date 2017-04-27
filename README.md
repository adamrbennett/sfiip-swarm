## SFI IP Microservices Architecture


## Overview
The infrastructure utilizes AWS OpsWorks for creating EC2 instances and provisioning them with Chef recipes. Instances are created within a VPC which contains a number of different subnets. Subnets can be classified as public or private. The public subnets use a routing table that contains a route to an internet gateway, which enables them to receive traffic directly from the internet. For this reason, the public subnets are inherently less secure than the private subnets.

Most instances and AWS resources should reside in a private subnet. The idea is to only run what is absolutely necessary in the public subnets and run everything else in the private subnets. Instances in the private subnets can make outbound internet requests through a NAT gateway, which runs in the public subnets. Any inbound traffic to the private subnets must be done through an ELB or proxy which runs in the public space.

<!-- ## Run Locally
1. Start the VMs: `infra/vagrant up`
1. Push the docker images: `infra/bin/push.sh`
1. Login to the manager node: `infra/vagrant ssh manager1`
1. Start services from the manager node: `/vagrant/bin/bootstrap.sh` -->

## Run in AWS

#### Initialize infrastructure in AWS
> The instances must be started in a controlled fashion so that the various clusters form properly.

>The non-infra instances run a consul client that communicates with the consul server cluster through an internal ELB. For this reason, the infrastructure instances must be registered with the ELB, which can take some time. Consul clients that start before the ELB is up and its instances are registered will not be able to join the cluster.

1. Execute the terraform plan: `infra/aws/terraform apply` to create the AWS infrastructure.
1. Start the *infrastructure* instances from the OpsWorks console.
1. Once the *infrastructure* instances have been launched and provisioned, start the *mgr1* instance. The swarm will initialize.
1. After the *mgr1* instance has started and has been successfully provisioned, start the remaining *manager* instances. The swarm manager cluster will form.
1. Start the remaining instances in the stack.
1. Navigate to the consul UI: `http://<pub1 IP address>:8500` and verify that all nodes are registered.
1. Setup OpsWorks SSH permissions (see Notes below).
1. Create a CNAME domain record with a name of `*.dev` that points to the *manager* ELB.

#### Start services in AWS
1. From one of the *manager* nodes, create a docker secret named `jenkins_ssh` and set the value to a private SSH key that can access the git repositories. Example:
```
cat << EOF | docker secret create jenkins_ssh -
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
EOF
```
1. From one of the *manager* nodes, execute the bootstrap shell script: `/root/bootstrap.sh`. This will start all of the supporting services:
  - cadvisor (container metrics)
  - node-exporter (host metrics)
  - metrics (prometheus metrics aggregator)
  - grafana (metrics visualizer)
  - portainer (swarm management console)
  - proxy (http request proxy)
  - jenkins (continuous integration)

#### Configure Jenkins
1. Navigate to the jenkins console: `http://jenkins.dev.vadr.us`
1. Login: `abennett/letmein`
1. Create a username/password credential to authenticate with the docker hub registry. Supply the following values:
  - User Name: docker hub user name
  - Password: docker hub password
  - ID: `docker-registry-credentials`
1. Run a build to verify the jenkins configuration and deploy a service to the swarm.
1. Verify the service is registered with consul via the consul UI. Navigate to the service using the following URL format: `http://<build number>.<service name>.dev.vadr.us/<path>`

## Notes

#### SSH Access
SSH access is provided through a [bastion host](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/) located within a public subnet (pub1) that receives a public IP. To enable SSH access, you must have an IAM user with the appropriate privileges, and you must enable SSH privileges (and sudo, if desired) for that user through the OpsWorks console. This is not automated for security reasons. See the AWS OpsWorks [documentation](http://docs.aws.amazon.com/opsworks/latest/userguide/workinginstances-ssh.html) for more details.

  It is recommended that the public node (pub1) only be started prior to establishing an SSH session, and then shutdown afterward. NOTE: after enabling SSH access for the user in the OpsWorks console, OpsWorks will execute the `sync_remote_users` command on all nodes in the stack. You will not be able to SSH until this command has completed, so wait a couple minutes, or use the OpsWorks console to confirm the command has completed.

To avoid storing SSH keys within the infrastructure, you must use SSH forwarding. To SSH into the network, execute this command: `ssh -A <iam user name>@<pub1 IP address>`. Once you have established an SSH connection to pub1, you can then SSH into any of the nodes within the private subnets, e.g.: `ssh mgr1`, and the SSH credentials used in your initial session will be forwarded.
