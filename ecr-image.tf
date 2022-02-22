resource "aws_ecr_repository" "ecr_repo" {
  name = "ecr_repo"
}

resource "docker_registry_image" "lambda-image" {
  name = "${aws_ecr_repository.ecr_repo.repository_url}:latest"

  build {
    context    = "app.py"
    dockerfile = "dockerfile"
  }
}