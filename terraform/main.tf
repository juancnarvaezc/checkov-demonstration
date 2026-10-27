# Arquitectura básica de demostración: VM Linux con su red virtual y NSG.
# No se despliega realmente (el provider apunta a floci-az, ver providers.tf).

# Resource Group
resource "azurerm_resource_group" "demo" {
  name     = "rg-checkov-demo"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "demo" {
  name                = "vnet-checkov-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Subnet
resource "azurerm_subnet" "demo" {
  name                 = "snet-checkov-demo"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "demo" {
  name                = "nsg-checkov-demo"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# ERROR 2/3 de la demo: regla de SSH abierta a todo Internet.
resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow-SSH-Inbound"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "Internet" # <- ERROR: cualquier IP de Internet puede intentar conectarse
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.demo.name
  network_security_group_name = azurerm_network_security_group.demo.name
}

# ERROR 3/3 de la demo: regla RDP (escritorio remoto) abierta a todo Internet.
resource "azurerm_network_security_rule" "rdp" {
  name                        = "Allow-RDP-Inbound"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "Internet" # <- ERROR: escritorio remoto expuesto a Internet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.demo.name
  network_security_group_name = azurerm_network_security_group.demo.name
}

resource "azurerm_subnet_network_security_group_association" "demo" {
  subnet_id                 = azurerm_subnet.demo.id
  network_security_group_id = azurerm_network_security_group.demo.id
}

# Interfaz de red de la VM (solo IP privada)
resource "azurerm_network_interface" "demo" {
  name                = "nic-checkov-demo"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ERROR 1/3 de la demo: VM con autenticación por contraseña.
resource "azurerm_linux_virtual_machine" "demo" {
  name                = "vm-checkov-demo"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  size                = var.vm_size
  admin_username      = var.admin_username

  admin_password                  = var.admin_password
  disable_password_authentication = false # <- ERROR: permite ataques de fuerza bruta

  allow_extension_operations = false
  network_interface_ids      = [azurerm_network_interface.demo.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

