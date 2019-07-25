output "instance_id" {
  value = "${aws_instance.windows-server-with-s3-access.id}"
}

output "instance_public_ip" {
  value = "${aws_instance.windows-server-with-s3-access.public_ip}"
}

output "decrypted_password" {
  value = "${rsadecrypt(aws_instance.windows-server-with-s3-access.password_data, tls_private_key.provisioning_key.private_key_pem)}"
}

output "s3_bucket_id" {
  value = "${aws_s3_bucket.windows_s3_bucket.id}"
}
