import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, TimestampType

# Captura variáveis de Ambiente no Terraform
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_SOURCE', 'S3_TARGET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# schema
schema = StructType([
    StructField("id_transacao", StringType(), True),
    StructField("valor", DoubleType(), True),
    StructField("data_hora", StringType(), True), # Ou TimestampType se o formato permitir
    StructField("cliente_id", StringType(), True),
    StructField("status", StringType(), True)
])

# Leitura do arquivo JSON (Raw)
df = spark.read \
    .schema(schema) \
    .json(args['S3_SOURCE'])

# Transformação simples 
df_refined = df.withColumn('status_processamento', F.lit('CONCLUIDO'))

# Escrita em parquet (refined)
df_refined.write.mode('overwrite').parquet(args['S3_TARGET'])

job.commit()
