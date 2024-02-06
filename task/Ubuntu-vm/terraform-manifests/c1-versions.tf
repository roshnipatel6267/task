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

