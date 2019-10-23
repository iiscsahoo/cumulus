resource "null_resource" "get_newest_CMA" {
  count = var.local_core_lambda ? 0 : 1
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "curl -f, -o , ${var.archive},  https://github.com/${var.repo}/releases/download/${var.release}/${var.zip_file}"]
  }
}