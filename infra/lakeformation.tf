# 1. REGISTRO DO BUCKET REFINED (Onde o Job falha ao escrever)
resource "aws_lakeformation_resource" "refined_registration" {
  arn = aws_s3_bucket.refined.arn
}

# 2. PERMISSÕES DE LOCALIZAÇÃO PARA O REFINED
resource "aws_lakeformation_permissions" "glue_refined_location" {
  principal = aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_s3_bucket.refined.arn
  }

  depends_on = [aws_lakeformation_resource.refined_registration]
}

# 3. PERMISSÕES DE LOCALIZAÇÃO PARA O RAW
# Como o raw já está no console, apenas damos a permissão para a role
resource "aws_lakeformation_permissions" "glue_raw_location" {
  principal = aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_s3_bucket.raw.arn
  }
}

# 4. ACESSO AO BANCO DE DADOS
resource "aws_lakeformation_permissions" "glue_database_access" {
  principal = aws_iam_role.glue_role.arn
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER"]

  database {
    name = aws_glue_catalog_database.risco_db.name
  }
}