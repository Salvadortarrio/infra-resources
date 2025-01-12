# Infra Resources

Este repositorio contiene los recursos necesarios para la infraestructura base del proyecto. Aquí se definen las configuraciones y scripts necesarios para implementar y gestionar la infraestructura utilizando herramientas de Infraestructura como Código (IaC).

## Contenido
- **Arquitectura de red:** Configuración de subredes, grupos de seguridad y redes virtuales.
- **Servidores:** Definiciones para el aprovisionamiento de máquinas virtuales u otros servidores.
- **Automatización:** Scripts para configurar y desplegar la infraestructura.

## Uso
1. Clonar el repositorio:
   ```bash
   git clone https://github.com/<user>/infra-resources.git




   terraform init
   terraform plan
   terraform apply
   terraform destroy -auto-approve


   terraform apply -auto-approve



ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ec2-user@15.237.202.141 "ls /tmp"


terragrunt run-all init && terragrunt run-all plan && terragrunt run-all apply --terragrunt-non-interactive

terragrunt run-all destroy --terragrunt-non-interactive




