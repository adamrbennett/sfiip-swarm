resource "aws_iam_role" "sfiip_ec2" {
  name = "sfiip-ec2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "sfiip_ec2" {
  name = "sfiip-ec2"
  roles = ["${aws_iam_role.sfiip_ec2.name}"]
}

resource "aws_iam_policy_attachment" "ecr_read" {
  name       = "ecr-read-attachment"
  roles      = ["${aws_iam_role.sfiip_ec2.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_policy_attachment" "s3_read" {
  name       = "s3-read-attachment"
  roles      = ["${aws_iam_role.sfiip_ec2.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role" "sfiip_opsworks" {
  name = "sfiip-opsworks"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "opsworks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sfiip_opsworks" {
  name = "sfiip-opsworks"
  role = "${aws_iam_role.sfiip_opsworks.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": [
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:DescribeAlarms",
             "ec2:*",
             "ecs:*",
             "elasticloadbalancing:*",
             "iam:GetRolePolicy",
             "iam:ListInstanceProfiles",
             "iam:ListRoles",
             "iam:ListUsers",
             "iam:PassRole",
             "opsworks:*",
             "rds:*"
        ],
        "Resource": ["*"]
    }]
}
EOF
}

// output

output "service_role_arn" {
  value = "${aws_iam_role.sfiip_opsworks.arn}"
}

output "instance_profile_arn" {
  value = "${aws_iam_instance_profile.sfiip_ec2.arn}"
}
