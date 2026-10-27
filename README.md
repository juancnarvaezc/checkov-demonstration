# checkov-demonstration

![Terraform 1.16.0](https://img.shields.io/badge/Terraform-1.16.0-7B42BC?logo=terraform)

Demostración de seguridad de infraestructura como código. El propósito es analizar con Checkov una configuración de Terraform que contenga errores de seguridad, explicar los hallazgos, corregirlos y repetir el análisis para mostrar el resultado. Todo se realiza localmente, sin desplegar recursos en la nube ni generar costos.

## Estructura del repositorio

```text
checkov-demonstration/
├── .github/
│   └── workflows/
│       ├── checkov.yml
│       └── terraform-ci.yml
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   └── .terraform.lock.hcl
├── docker-compose.yml
├── .gitignore
├── LICENSE
└── README.md
```

## Rama main

Contiene los workflows de Integración Continua:

- **.github/workflows/terraform-ci.yml**: ejecuta `terraform fmt -check`, `terraform init -backend=false` y `terraform validate` sobre la carpeta `terraform/`.
- **.github/workflows/checkov.yml**: ejecuta el análisis de seguridad con Checkov (acción oficial `bridgecrewio/checkov-action`) sobre la carpeta `terraform/`.

Ambos workflows se disparan en push y pull request sobre las ramas `main` y `test`, solo cuando cambian archivos dentro de `terraform/`.

## Rama test

Contiene la arquitectura de demostración en Azure (apuntando al emulador local floci-az) con tres errores de seguridad intencionales:

1. Maquina virtual Linux con autenticación por contraseña (debe usar claves SSH).
2. Regla de grupo de seguridad de red con puerto SSH (22) abierto a Internet.
3. Regla de grupo de seguridad de red con puerto RDP (3389) abierto a Internet.

El proveedor de Terraform está configurado para apuntar a `https://localhost:4577`, el emulador local de Azure floci-az. Las credenciales son falsas, por lo que es imposible desplegar recursos en Azure real por accidente.

## Los errores de seguridad y sus correcciones

Checkov detecta cinco fallos provocados por los tres errores anteriores (el error de la contraseña dispara tres checks relacionados).

### Error 1: Autenticación por contraseña en la VM

Archivo: `terraform/main.tf`, recurso `azurerm_linux_virtual_machine.demo`.

Configuración insegura:

```diff
- admin_password = var.admin_password
- disable_password_authentication = false
```

Corrección:

```diff
+ admin_ssh_key {
+   username   = var.admin_username
+   public_key = var.admin_ssh_key
+ }
+
+ disable_password_authentication = true
```

### Error 2: Puerto SSH abierto a Internet

Archivo: `terraform/main.tf`, recurso `azurerm_network_security_rule.ssh`.

Configuración insegura:

```diff
- source_address_prefix = "Internet"
- destination_port_range = "22"
```

Corrección:

```diff
+ source_address_prefix = "203.0.113.0/24"
```

### Error 3: Puerto RDP abierto a Internet

Archivo: `terraform/main.tf`, recurso `azurerm_network_security_rule.rdp`.

Configuración insegura:

```diff
- source_address_prefix = "Internet"
- destination_port_range = "3389"
```

Corrección:

```diff
+ source_address_prefix = "203.0.113.0/24"
```

`203.0.113.0/24` es un rango de documentación ([RFC 5737](https://doi.org/10.17487/RFC5737])). En un entorno real se usaria el CIDR de la red de administración o una IP unica (/32).

## Cómo ejecutar la demostración

### Requisitos previos

- Terraform 1.16.0 o superior.
- Checkov (`pip install checkov`).
- Docker Desktop (para el emulador floci-az).

### Paso 1: Analizar el estado inseguro

Desde la raíz del repositorio:

```bash
cd terraform
terraform init
terraform validate
cd ..
checkov -d terraform --compact
```

Resultado esperado: `terraform validate` pasa, pero Checkov reporta **5 fallos**.

### Paso 2: Corregir los errores

Aplicar las correcciones descritas arriba en `terraform/main.tf` y volver a ejecutar:

```bash
checkov -d terraform --compact
```

Resultado esperado: **0 fallos**.

### Paso 3: Desplegar en el emulador local (opcional)

```bash
docker compose up -d
cd terraform
terraform apply
terraform destroy
cd ..
```

Esto crea y destruye 9 recursos en el emulador floci-az, sin tocar Azure real ni generar costos.

## Rama de trabajo y tag

- La rama `test` contiene el estado inicial inseguro.
- El tag `demo-rota` permite restaurar ese estado inicial para repetir la demostración cuantas veces sea necesario.

## Detalles técnicos

- Proveedor Terraform: `hashicorp/azurerm` versión `~> 4.0`.
- Máquina virtual: `Standard_B1s` con Ubuntu 22.04 LTS (tier gratuito de Azure).
- Emulador: `floci/floci-az:latest` en el puerto 4577 con TLS habilitado.
- Checkov: versión 3.3.29 local / 3.3.30 en GitHub Actions.

## Equipo

**Firmes por Palmer:**

- Mario Alberto Julio Wilches.
- Ana Sofia Meza Herrera.
- Juan Carlos Narváez Castaño.
- Alejandro Villarreal Imitola.
