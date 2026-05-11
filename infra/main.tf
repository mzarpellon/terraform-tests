provider "aws" {
  region = var.region
}

# Dados da conta para uso no iam.tf
data "aws_caller_identity" "current" {}

# Buckets S3
resource "aws_s3_bucket" "raw" { bucket = "${var.bucket-prefix}-raw" }
resource "aws_s3_bucket" "refined" { bucket = "${var.bucket-prefix}-refined" }
resource "aws_s3_bucket" "curated" { bucket = "${var.bucket-prefix}-curated" }
resource "aws_s3_bucket" "scripts" { bucket = "${var.bucket-prefix}-scripts" }
resource "aws_s3_bucket" "logs" { bucket = "${var.bucket-prefix}-logs" }
resource "aws_s3_bucket" "athena-results" { bucket = "${var.bucket-prefix}-athena-results" }

# Scripts e Samples
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "processar_transacoes.py"
  source = "../scripts/processar_transacoes.py"
  etag   = filemd5("../scripts/processar_transacoes.py")
}

resource "aws_s3_object" "json_sample" {
  bucket       = aws_s3_bucket.raw.id
  key          = "transacao/transacoes_input.json"
  source       = "../data_sample/transacoes_input.json"
  etag         = filemd5("../data_sample/transacoes_input.json")
  content_type = "application/json"
}

# Glue Catalog
resource "aws_glue_catalog_database" "risco_db" {
  name = "db_risco_credito"
}

# Glue Job
resource "aws_glue_job" "process_job" {
  name              = "job-processar-transacoes"
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/processar_transacoes.py"
    python_version  = "3"
  }

  default_arguments = {
    "--JOB_NAME"                         = "job-processar-transacoes"
    "--DB_NAME"                          = aws_glue_catalog_database.risco_db.name
    "--S3_SOURCE"                        = "s3://${aws_s3_bucket.raw.bucket}"
    "--S3_TARGET"                        = "s3://${aws_s3_bucket.refined.bucket}"
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--conf" = "spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter"
  }
}

# Step Functions Orquestrador
resource "aws_sfn_state_machine" "pipeline" {
  name     = "pipeline-risco-credito"
  role_arn = aws_iam_role.sfn_role.arn # Agora usando a role correta

  definition = jsonencode({
    StartAt = "RunGlueJob",
    States = {
      RunGlueJob = {
        Type     = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = aws_glue_job.process_job.name
        },
        End = true
      }
    }
  })
}