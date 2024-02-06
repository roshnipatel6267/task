
# Terraform Block
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.17.0"
    }
  }
}

# Provider Block
provider "azurerm" {
 features {}  
skip_provider_registration = "true"        
}

# Random String Resource
resource "random_string" "myrandom" {
  length = 6
  upper = false 
  special = false
  numeric = false   
}
# Create Resource Group
data "azurerm_resource_group" "existing" {
  name = "sa1_test_eic_TejalDave"
}


# Create Azure Storage account
resource "azurerm_storage_account" "roshnitest11" {
  name                = "${var.storage_account_name}${random_string.myrandom.id}"
  resource_group_name = data.azurerm_resource_group.existing.name

  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = var.storage_account_kind

  static_website {
    index_document     = var.static_website_index_document
    error_404_document = var.static_website_error_404_document
  }
}

resource "azurerm_storage_container" "roshni-container" {
  name                  = "roshni-container"
  storage_account_name  = azurerm_storage_account.roshnitest11.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "roshni-blob" {
  name                   = "roshni-blob"
  storage_account_name   = azurerm_storage_account.roshnitest11.name
  storage_container_name = azurerm_storage_container.roshni-container.name
  type                   = "Block"
  source                 = "./test/file2.txt"
  #source                 = filebase64("${path.module}/test/file2.txt")
}

resource "azurerm_linux_virtual_machine" "roshnivm" {
  name                  = "roshni-vm1"
  computer_name         = "devlinux-vm1"
  resource_group_name   = data.azurerm_resource_group.existing.name
  location              = data.azurerm_resource_group.existing.location
  size                  = "Standard_DS1_v2"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.myvmnic.id]

  admin_ssh_key {
    username  = "azureuser"
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }

  os_disk {
    name                 = "osdisk${random_string.myrandom.id}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Redhat"
    offer     = "RHEL"
    sku       = "83-gen2"
    version   = "latest"
  }
  custom_data = filebase64("${path.module}/file1/app1-cloud-init.txt")
  #custom_data = filebase64("file1/app1-cloud-init.txt")
}


# Create Virtual Network
resource "azurerm_virtual_network" "myvnet" {
  name                = local.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
}

# Create Subnet
resource "azurerm_subnet" "mysubnet" {
  name                 = local.snet_name
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Public IP Address
resource "azurerm_public_ip" "mypublicip" {
  name                = local.pip_name
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  allocation_method   = "Static"
  domain_name_label   = "app1-${terraform.workspace}-${random_string.myrandom.id}"
}

# Create Network Interface
resource "azurerm_network_interface" "myvmnic" {
  name                = local.nic_name
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

