# Registrar o bucket no Lake Formation
resource "aws_lakeformation_resource" "data_location" {
  arn = aws_s3_bucket.bucket.arn
}

# Conceder permissões ao Glue Role
resource "aws_lakeformation_permissions" "glue_permissions" {
  principal = aws_iam_role.glue_role.arn
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.risco_db.name
  }
}