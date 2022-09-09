terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.93.0"
    }
  }
}

provider "azurerm" {
    subscription_id = "3d0e9868-07c1-46ce-be62-902533cf6509"
    client_id = "e3f01557-86bb-46a3-b267-bd137a4e5576"
    client_secret = "S6-8Q~9ZsMVPESyy1WL-xL4fN41kZNbKd7~SraRd"
    tenant_id = "01454e03-3623-4535-b171-d8a0cf6d8eff"
    skip_provider_registration = true
    features {
      
    }
}

locals {
  resource_group="app-grp"
  location="North Europe"  
}


resource "azurerm_resource_group" "app_grp"{
  name=local.resource_group
  location=local.location
}

//Virtual network where scale set machines will be residing...
resource "azurerm_virtual_network" "app_network" {
  name                = "Scale-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]  
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

//Creating a subnet inside the virtual network.......
resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetOne"
  resource_group_name  = azurerm_resource_group.app_grp.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

//Load balancers Public IP......
resource "azurerm_public_ip" "load_ip" {
  name                = "load-ip"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku="Standard"
}

//Creating azure Load Balancer......
resource "azurerm_lb" "app_balancer" {
  name                = "app-balancer"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  sku="Standard"
  sku_tier = "Regional"
  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.load_ip.id
  }

  depends_on=[
    azurerm_public_ip.load_ip
  ]
}

//making backend pool......
resource "azurerm_lb_backend_address_pool" "scalesetpool" {
  loadbalancer_id = azurerm_lb.app_balancer.id
  name            = "scalesetpool"
  depends_on=[
    azurerm_lb.app_balancer
  ]
}

// Here we are defining the Health Probe....
resource "azurerm_lb_probe" "ProbeA" {
  resource_group_name = azurerm_resource_group.app_grp.name
  loadbalancer_id     = azurerm_lb.app_balancer.id
  name                = "probeA"
  port                = 80
  protocol            =  "Tcp"
  depends_on=[
    azurerm_lb.app_balancer
  ]
}

//Load balancing rules are defined......
resource "azurerm_lb_rule" "Rule1" {
  resource_group_name            = azurerm_resource_group.app_grp.name
  loadbalancer_id                = azurerm_lb.app_balancer.id
  name                           = "Rule1"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.scalesetpool.id ]
}

#Creating virtual machine scale set.......
resource "azurerm_windows_virtual_machine_scale_set" "scale_set" {
  name                = "scale-set"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  sku                 = "Standard_D2s_v3"
  instances           = 2
  admin_password      = "Azure@123"
  admin_username      = "vmuser"
  upgrade_mode = "Automatic"
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "scaleset-interface"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.SubnetA.id
      load_balancer_backend_address_pool_ids =[azurerm_lb_backend_address_pool.scalesetpool.id]
    }    
  }
  depends_on=[
      azurerm_virtual_network.app_network
    ]
}
