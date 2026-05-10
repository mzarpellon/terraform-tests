# Registro do Bucket RAW
resource "aws_lakeformation_resource" "raw_location" {
  arn = aws_s3_bucket.raw.arn
}

# Registro do Bucket REFINED
resource "aws_lakeformation_resource" "refined_location" {
  arn = aws_s3_bucket.refined.arn
}

# Registro do Bucket CURATED
resource "aws_lakeformation_resource" "curated_location" {
  arn = aws_s3_bucket.curated.arn
}

# Conceder permissões ao Glue Role
resource "aws_lakeformation_permissions" "glue_permissions" {
  principal = aws_iam_role.glue_role.arn
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.risco_db.name
  }
}