resource "aws_spot_instance_request" "instance" {
  ami           = data.aws_ami.main.id
  spot_price    = data.aws_ec2_spot_price.spot_price.spot_price
  instance_type = var.INSTANCE_TYPE
  wait_for_fulfillment    = true
  vpc_security_group_ids  = [aws_security_group.main.id]
  subnet_id               = var.PRIVATE_SUBNET_ID[0]
  iam_instance_profile    = aws_iam_instance_profile.allow-secretmanager-readaccess.name

  tags   = {
    Name = local.TAG_PREFIX
  }
}

resource "aws_ec2_tag" "example" {
  resource_id = aws_spot_instance_request.instance.spot_instance_id
  key         = "Name"
  value       = local.TAG_PREFIX
}

resource "null_resource" "ansible" {
  provisioner "remote-exec" {
    connection {
      user = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host = aws_spot_instance_request.instance.private_ip
    }
    inline = [
      "ansible-pull -U https://github.com/devopsravi9/roboshop-ansible.git roboshop.yml -e HOST=localhost -e ROLE=rabbitmq -e ENV=${var.ENV}"
    ]

  }
}