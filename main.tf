
# -------------------------------
# AZURE PROVIDER
# -------------------------------
provider "azurerm" {
  features {}
}

# -------------------------------
# RESOURCE GROUP
# -------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-shruti-terraform"
  location = "West US 2"
}

# -------------------------------
# STORAGE ACCOUNT
# -------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "shrutistorageterraform01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# -------------------------------
# VIRTUAL NETWORK
# -------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vm-shruti-01-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -------------------------------
# SUBNET
# -------------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# -------------------------------
# PUBLIC IP
# -------------------------------
resource "azurerm_public_ip" "publicip" {
  name                = "vm-shruti-01-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# -------------------------------
# NETWORK SECURITY GROUP (FIX)
# -------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-shruti-01-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -------------------------------
# NETWORK INTERFACE
# -------------------------------
resource "azurerm_network_interface" "nic" {
  name                = "vm-shruti-01-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.publicip.id
    private_ip_address_allocation = "Dynamic"
  }
}

# -------------------------------
# ASSOCIATE NSG WITH NIC (FIX)
# -------------------------------
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -------------------------------
# VIRTUAL MACHINE
# -------------------------------
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm-shruti-01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  network_interface_ids = [azurerm_network_interface.nic.id]

  vm_size = "Standard_B2as_v2"

  # Ubuntu image
  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # OS disk
  storage_os_disk {
    name              = "vm-shruti-01-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Login
  os_profile {
    computer_name  = "vm-shruti-01"
    admin_username = "azureuser"
    admin_password = "Terraform@12345"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

