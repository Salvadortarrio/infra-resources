# Asignación de valores a las variables

aws_region    = "eu-west-3"                             # Región (puede ser configurada también en variables.tf si es fija)
#bucket_name   = "proyect-1-stb-devops-bucket-terraform-prueba" # Nombre del bucket S3 (asegúrate de que sea único)
#ami_id        = "ami-0574a94188d1b84a1"  
ami_id= "ami-06e02ae7bdac6b938" # ubuntu 24.04             # Aquí pones la AMI de ubuntu 
#ami_id= "ami-07db896e164bc4476" # ubuntu 22.04
instance_type = "t2.small"                              # Tipo de instancia, si deseas cambiarlo
acl           =  "public-read"
db_username   = "admin"
db_password   = "adminnoadminhou"
create_replica= false
replicas  = 1
vpc_cidr = "10.17.0.0/16"
vpc_id="vpc-002427d5be38383d7"

#private_key_path = "~/.ssh/id_rsa" # Ruta al archivo .pem de la clave privada
#backend_bucket_name= "proyect-1-stb-devops-bucket"
#tag_value="stb"
#public_key_path="~/.ssh/id_rsa.pub"
#module_path="../modules/wordpress/"
#module_path="../modules/nginx-node-mongo/"
module_path="../modules/eks_wordpress/"
