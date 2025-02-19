# Crear un Key Pair para EC2
provider "aws" {
  region = var.aws_region  # Usamos una variable para la región, que podemos definir en variables.tf
  #profile = "default"
  #quitar profile si se compila desde la nube
}

resource "aws_key_pair" "key" {
  key_name   = "my-key-name-${var.tag_value}"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}

# Obtener la VPC por defecto
data "aws_vpc" "default" {
  default = true
}


# Paso 2: Listar todas las subredes de la VPC
data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
#Paso 2.1: Listar zonas de disponibilidad
data "aws_availability_zones" "available" {}

#Paso 3: Crear siempre 1 subredes por cada az
resource "aws_subnet" "subnet" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = element(["172.31.103.0/24", "172.31.104.0/24", "172.31.105.0/24"], count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${var.tag_value}-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# Local para almacenar las subredes creadas
locals {
  all_subnet_ids = aws_subnet.subnet[*].id  # Lista de IDs de subredes creadas
}

# --------------------------------------------------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg-${var.tag_value}"
  description = "Security group for Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  // Permitir tráfico HTTP en el puerto 80 (entrada de los clientes)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acceso público desde cualquier lugar
  }


  // Permitir todo el tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg-${var.tag_value}"
  }
}


# Crear un Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.tag_value}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # Reglas de entrada para EC2
  ingress {
    from_port   = 22   # Permitir SSH para acceso a la EC2
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # O reemplaza con una IP específica si prefieres restringir el acceso
  }
  
  ingress {
    from_port   = 80   # Permitir HTTP (NGINX)
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]  # Acceso desde cualquier IP
  }

  # Reglas de salida para permitir todo el tráfico
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Todo el tráfico
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg-${var.tag_value}"
  }
}


resource "random_integer" "example" {
  min = 1
  max = 100
}

# Crear una instancia EC2 con un bloque de provisionamiento SSH
resource "aws_instance" "my_instance" {
  count = var.replicas
  ami             = var.ami_id  # Reemplaza con una AMI válida para tu región (Ubuntu, RedHat, etc.)
  instance_type   = var.instance_type
  key_name        = aws_key_pair.key.key_name
  #subnet_id       = local.subnet_exists ? values(data.aws_subnet.exist_subnet_details)[0].id : aws_subnet.next_subnet.id
  #subnet_id = data.aws_subnets.vpc_subnets.ids[(count.index+random_integer.example.result) % length(data.aws_subnets.vpc_subnets.ids)]
  subnet_id= local.all_subnet_ids[(count.index+random_integer.example.result) % length(local.all_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true  # Si necesitas acceso público
  disable_api_termination = false
  
  # Configuración de provisioners
  provisioner "remote-exec" {# este bloque es para que si ejecuto un local-exec sobre este ec2 espere a que la maquina este accesible.
    inline = ["echo Hey system"]
    connection {
      type        = "ssh"
      user        = "ubuntu"  # Usa "ec2-user" para AMIs de Amazon Linux, "ubuntu" para AMIs de Ubuntu
      private_key = file(var.private_key_path)  # Ruta a tu clave privada en tu máquina local
      host        = self.public_ip  # La IP pública de la instancia
    }
  }

  tags = {
    Name = "Wordpress-${var.tag_value}-${count.index}"
  }
  depends_on = [aws_security_group.ec2_sg, null_resource.update_hosts_ini1,local_file.config_json]
}

# Crear un Target Group para el Load Balancer
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group-${var.tag_value}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "my-target-group-${var.tag_value}"
  }
}
# --------------------------------------   Descomentar si tenemos permisos para crear load balancers --------------------------

# Crear un Load Balancer
resource "aws_lb" "my_lb" {
  name               = "my-load-balancer-${var.tag_value}"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.lb_sg.id]
  subnets            = local.all_subnet_ids[*]

  enable_deletion_protection = false

  tags = {
    Name = "my-load-balancer-${var.tag_value}"
  }
}


# Crear un Listener para el Load Balancer, asociando el Target Group
resource "aws_lb_listener" "my_lb_listener" {#reenvia al grupo de destino
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

# Asociar las instancias EC2 al Target Group
resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  count               = var.replicas
  target_group_arn    = aws_lb_target_group.my_target_group.arn
  target_id           = aws_instance.my_instance[count.index].id
  port                = 80
}

resource "local_file" "config_json" {
  content = jsonencode({
    load_balancer_url = aws_lb.my_lb.dns_name
  })
  filename = "${path.module}/app/frontend/config/config.json"
}

resource "null_resource" "update_hosts_ini1" {
  provisioner "local-exec" {
    #command = "pwd"
    command = "echo [webservers] > ${var.module_path}ansible/hosts.ini "
     }
  # Usar triggers para forzar la ejecución del recurso
  triggers = {
    always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  }
}

resource "null_resource" "update_hosts_ini2" {
  provisioner "local-exec" {
    command = "echo \"${join("\n", [for ip in aws_instance.my_instance[*].public_ip : "${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"])}\" >> ${var.module_path}ansible/hosts.ini"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [aws_instance.my_instance]  # Esto asegura que las instancias estén creadas antes de ejecutar el local-exec
}


resource "null_resource" "provisioner1" {
  provisioner "local-exec" {

    command = "export ANSIBLE_CONFIG=${var.module_path}ansible/ansible.cfg && ansible-playbook -i ${var.module_path}ansible/hosts.ini ${var.module_path}ansible/install1.yml"
  }
  # Usar triggers para forzar la ejecución del recurso
  triggers = {
    always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  }
  
  depends_on = [aws_instance.my_instance,null_resource.update_hosts_ini2]
}


