# --- ROLE PARA O AWS GLUE ---
resource "aws_iam_role" "glue_role" {
  name = "${var.project-name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

# Política Gerenciada (Logs e Catálogo)
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Política Customizada (S3, Catálogo e PassRole)
resource "aws_iam_role_policy" "glue_custom_policy" {
  name = "glue_custom_access_policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissões de S3 (Leitura e Escrita)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", 
          "s3:PutObject", 
          "s3:ListBucket", 
          "s3:DeleteObject",
          "s3:AbortMultipartUpload" # Importante para falhas no Parquet
        ]
        Resource = [
          aws_s3_bucket.scripts.arn, "${aws_s3_bucket.scripts.arn}/*",
          aws_s3_bucket.raw.arn, "${aws_s3_bucket.raw.arn}/*",
          aws_s3_bucket.refined.arn, "${aws_s3_bucket.refined.arn}/*"
        ]
      },
      # Permissões de Catálogo (Metadados)
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase", "glue:CreateTable", "glue:UpdateTable",
          "glue:GetTable", "glue:GetPartitions", "glue:BatchCreatePartition",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.risco_db.name}",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.risco_db.name}/*"
        ]
      },
      # PASSO 1: Permissão de PassRole (Crucial para o Spark/Glue 4.0)
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project-name}-glue-role"
      }
    ]
  })
}

# --- ROLE PARA O STEP FUNCTIONS ---
resource "aws_iam_role" "sfn_role" {
  name = "${var.project-name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

# Permissão para o SFN disparar o Glue Job e passar a Role
resource "aws_iam_role_policy" "sfn_glue_policy" {
  name = "sfn_execute_glue_policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun", "glue:GetJobRun", 
          "glue:GetJobRuns", "glue:BatchStopJobRun"
        ]
        Resource = aws_glue_job.process_job.arn
      },
      # SFN também precisa de PassRole para entregar a Role ao Glue
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.glue_role.arn
      }
    ]
  })
}