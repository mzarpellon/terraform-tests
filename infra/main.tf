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

# Glue Database
resource "aws_glue_catalog_database" "risco_db" {
  name = "db_risco_credito"
}

# Glue Job
resource "aws_glue_job" "process_job" {
  name = "job-processar-transacoes"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/processar_transacoes.py" 
    python_version = "3"
  }

  default_arguments = {
    "--DB_NAME" = aws_glue_catalog_database.risco_db.name
    "--S3_SOURCE" = "s3://${aws_s3_bucket.raw.bucket}/"
    "--S3_TARGET" = "s3://${aws_s3_bucket.refined.bucket}/"
    "--job-language" = "python"

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