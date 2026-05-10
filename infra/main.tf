provider "aws" {
  region = var.region
}

# Buckets S3
resource "aws_s3_bucket" "raw" {
  bucket = "${var.bucket-prefix}-raw"
}

resource "aws_s3_bucket" "refined" {
  bucket = "${var.bucket-prefix}-refined"
}

resource "aws_s3_bucket" "curated" {
  bucket = "${var.bucket-prefix}-curated"
}

resource "aws_s3_bucket" "scripts" {
  bucket = "${var.bucket-prefix}-scripts"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket-prefix}-logs"
}

resource "aws_s3_bucket" "athena-results" {
  bucket = "${var.bucket-prefix}-athena-results"
}

# Copia scripts da pasta local para o S3
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "processar_transacoes.py" # O caminho que o Glue espera
  source = "../scripts/processar_transacoes.py" # O caminho do arquivo na sua máquina (WSL)
  etag   = filemd5("../scripts/processar_transacoes.py") # Atualiza o S3 se o código mudar
}

# Enviar o arquivo de exemplo para a camada RAW
resource "aws_s3_object" "json_sample" {
  bucket = aws_s3_bucket.raw.id
  key    = "transacao/transacoes_input.json" # O caminho dentro do bucket
  source = "../data_sample/transacoes_input.json" # Caminho no seu WSL
  
  # Garante que o Terraform perceba se você alterar o conteúdo do JSON
  etag = filemd5("../data_sample/transacoes_input.json")
  
  content_type = "application/json"
}

# Glue role
# Política para permitir que o Glue acesse os scripts e os dados
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "glue_s3_access_policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.scripts.arn,
          "${aws_s3_bucket.scripts.arn}/*",
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*",
          aws_s3_bucket.refined.arn,
          "${aws_s3_bucket.refined.arn}/*"
        ]
      }
    ]
  })
}

# Glue Database
resource "aws_glue_catalog_database" "risco_db" {
  name = "db_risco_credito"
}

# Glue Job
resource "aws_glue_job" "process_job" {
  name     = "job-processar-transacoes"
  role_arn = aws_iam_role.glue_role.arn
  
  glue_version      = "4.0" # Define uma versão estável
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/processar_transacoes.py" 
    python_version  = "3"
  }

  default_arguments = {
    "--JOB_NAME"                = "job-processar-transacoes"
    "--DB_NAME"                 = aws_glue_catalog_database.risco_db.name
    "--S3_SOURCE"               = "s3://${aws_s3_bucket.raw.bucket}/"
    "--S3_TARGET"               = "s3://${aws_s3_bucket.refined.bucket}/"
    "--job-language"            = "python"
    "--enable-continuous-cloudwatch-log" = "true" # ajuda no debug

  }
}

# Step Functions
resource "aws_sfn_state_machine" "pipeline" {
  name     = "pipeline-risco-credito"
  role_arn = aws_iam_role.glue_role.arn
  
  definition = jsonencode({
    StartAt = "RunGlueJob",
    States = {
        RunGlueJob = {
            Type = "Task",
            Resource = "arn:aws:states:::glue:startJobRun.sync",
            Parameters = {
                JobName = aws_glue_job.process_job.name
            },
            End = true
        }
    }
  })
}