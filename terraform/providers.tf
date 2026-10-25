terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Este proveedor apunta al emulador local floci-az (https://floci.io/floci-az/terraform/)
# en lugar de a Azure real: las credenciales son falsas y el emulador no las valida.
# Con esta configuracion es IMPOSIBLE desplegar nada en una suscripcion real de Azure.
provider "azurerm" {
  features {}

  use_cli = false

  environment   = "stack"
  metadata_host = "localhost:4577"

  subscription_id = "00000000-0000-0000-0000-000000000001"
  tenant_id       = "00000000-0000-0000-0000-000000000002"
  client_id       = "00000000-0000-0000-0000-000000000003"
  client_secret   = "changeme"
}
