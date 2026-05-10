# Role para o AWS Glue
resource "aws_iam_role" "glue_role" {
  name = "${var.project-name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

# Políticas básicas para o Glue
resource "aws_iam_role_policy_attachment" "glue_service" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Role para o Step Functions
resource "aws_iam_role" "sfn_role" {
  name = "${var.project-name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = { Service = "states.amazonaws.com" }
    }]
  })
}