import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F

# Captura variáveis de Ambiente no Terraform
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_SOURCE', 'S3_TARGET'])

if not args.get('S3_TARGET'):
    raise ValueError("ERRO: A variável S3_TARGET está vazia! Verifique os argumentos do Job no Terraform.")

source_path = args['S3_SOURCE'].rstrip('/') + '/transacao/'
target_path = args['S3_TARGET'].rstrip('/') + '/' # Garante uma única barra no final

print(f"DEBUG - S3_SOURCE: {args['S3_SOURCE']}")
print(f"DEBUG - S3_TARGET: {args['S3_TARGET']}")


sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Leitura do arquivo JSON (Raw)
df = spark.read.option("multiline", "true").json(source_path)

# Agora o show() deve funcionar
df.show()

# # Escrita em parquet (refined)
df.write.mode('overwrite').parquet(target_path)

# job.commit()
