import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F

# Captura variáveis de Ambiente no Terraform
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_SOURCE', 'S3_TARGET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Leitura do arquivo JSON (Raw)
df = spark.read.json(args['S3_SOURCE'])

# Transformação simples 
df_refined = df.withColumn('status_processamento', F.lit('CONCLUIDO'))

# Escrita em parquet (refined)
df_refined.write.mode('overwrite').parquet(args['S3_TARGET'])

job.commit()
