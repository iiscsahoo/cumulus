data "external" "github" {
    count = var.local_core_lambda ? 0 : 1
    program = ["curl", "-f", "-o ${var.archive}", "https://github.com/${var.repo}/releases/download/${var.release}/${var.zip_file}"]
}