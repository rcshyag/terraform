provider "aws" {
  region = "us-east-1"
}

variable lab_username {
  // add your lab-user name and uncomment the line below
  default = "lab-user-8"
}


resource "aws_s3_bucket" "windows_s3_bucket" {
  // S3 bucket paths have to be globally unique because they become
  // part of a (potentially) public DNS name. Using `bucket_prefix`
  // lets us a customized name as a prefix to a random one.
  bucket_prefix = "${var.lab_username}-"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "Private Lab Content Bucket"
    Environment = "Terraform Lab User"
    Lab         = "Module 1 Lab 3"
    User        = "${var.lab_username}"
  }
}

resource "aws_iam_role" "windows_s3_role" {
  name_prefix = "${var.lab_username}-"
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

  tags = {
      Name        = "Lab Content Role"
      Environment = "Lab"
      Lab         = "Module 1 Lab 3"
      User        = "${var.lab_username}"
  }
}


resource "aws_iam_instance_profile" "windows_s3_profile" {
  name_prefix = "${var.lab_username}-lab-s3-instance-profile"
  role = "${aws_iam_role.windows_s3_role.name}"
}

resource "aws_iam_role_policy" "windows_s3_policy" {
  name_prefix = "${var.lab_username}-"
  role        = "${aws_iam_role.windows_s3_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

// Create a new security group
resource "aws_security_group" "windows_server_rdp" {
    name_prefix = "${var.lab_username}-"
    description = "Allow RDP connections to windows server."

    ingress {
      from_port   = "3389"
      to_port     = "3389"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      User = "${var.lab_username}"
    }
}

resource "tls_private_key" "provisioning_key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "aws_key_pair" "aws_provisioning_pair" {
  key_name_prefix = "${var.lab_username}"
  public_key = "${tls_private_key.provisioning_key.public_key_openssh}"
}

resource "aws_instance" "windows-server-with-s3-access" {

  // Windows 2019 Server
  ami                         = "ami-0a9ca0496f746e6e0"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.aws_provisioning_pair.key_name}"

  // Creation of this instance depends on the instance profile already existing
  iam_instance_profile        = "${aws_iam_instance_profile.windows_s3_profile.name}"
  associate_public_ip_address = true

  // Creation of this instance depends on the security group already existing
  vpc_security_group_ids      = ["${aws_security_group.windows_server_rdp.id}"]

  // The password is encrypted and only exposed as ciphertext that can be decrypted
  get_password_data           = true

  tags = {
      Name = "Windows Server with S3 Access"
      Environment = "Terraform Lab"
      Lab         = "Module 1 Lab 3"
      User = "${var.lab_username}"
  }

  // Create an explicit dependency
  depends_on = ["aws_s3_bucket.windows_s3_bucket"]
}
