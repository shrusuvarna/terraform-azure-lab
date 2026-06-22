
# -------------------------------
# AZURE PROVIDER
# -------------------------------
provider "azurerm" {
  features {}
}

# -------------------------------
# RESOURCE GROUP (NEW ONE)
# -------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-shruti-terraform"   # NEW RG (so no conflict)
  location = "West US 2"             # Same region as VM
}

# -------------------------------
# STORAGE ACCOUNT
# -------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "shrutistorageterraform01"  # MUST be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"   # SAME as manual
  account_replication_type = "LRS"        # SAME as manual
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
  name                 = "default"   # same as portal
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
# VIRTUAL MACHINE
# -------------------------------
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm-shruti-01"   # SAME name as manual
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  network_interface_ids = [azurerm_network_interface.nic.id]

  vm_size = "Standard_B2as_v2"   # ✅ SAME as your manual choice

  # Ubuntu image
  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # OS Disk
  storage_os_disk {
    name              = "vm-shruti-01-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"   # ✅ SAME as manual (Standard SSD)
  }

  # Login config
  os_profile {
    computer_name  = "vm-shruti-01"
    admin_username = "azureuser"          # ✅ SAME username
    admin_password = "Terraform@12345"    # change if needed
  }

  # Linux config
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
