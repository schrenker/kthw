resource "azurerm_resource_group" "kthw_rg" {
  name     = "kthw_rg"
  location = "North Europe"
  tags = {
    "env" = "kthw"
  }
}

resource "azurerm_virtual_network" "kthw_vnet" {
  name                = "kthw_vnet"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
  address_space       = ["10.10.0.0/16"]
  tags = {
    "env" = "kthw"
  }
}

resource "azurerm_subnet" "kthw_control" {
  name                 = "kthw_control"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  virtual_network_name = azurerm_virtual_network.kthw_vnet.name
  address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_subnet" "kthw_worker" {
  name                 = "kthw_worker"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  virtual_network_name = azurerm_virtual_network.kthw_vnet.name
  address_prefixes     = ["10.10.20.0/24"]
}

resource "azurerm_network_security_group" "nsg_control" {
  name                = "nsg_control"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
}

resource "azurerm_network_security_group" "nsg_worker" {
  name                = "nsg_worker"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_control_subnet" {
  subnet_id                 = azurerm_subnet.kthw_control.id
  network_security_group_id = azurerm_network_security_group.nsg_control.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_worker_subnet" {
  subnet_id                 = azurerm_subnet.kthw_worker.id
  network_security_group_id = azurerm_network_security_group.nsg_worker.id
}

resource "azurerm_route_table" "pod_route_table" {
  name                = "pod_routing"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
}

resource "azurerm_route" "pod_route" {
  count                  = 3
  name                   = "pod_route_${count.index}"
  resource_group_name    = azurerm_resource_group.kthw_rg.name
  route_table_name       = azurerm_route_table.pod_route_table.name
  address_prefix         = "10.20.${count.index}.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.10.20.1${count.index}"
}

resource "azurerm_subnet_route_table_association" "worker_subnet_route" {
  subnet_id      = azurerm_subnet.kthw_worker.id
  route_table_id = azurerm_route_table.pod_route_table.id
}

resource "azurerm_subnet_route_table_association" "control_subnet_route" {
  subnet_id      = azurerm_subnet.kthw_control.id
  route_table_id = azurerm_route_table.pod_route_table.id
}

# resource "azurerm_network_security_rule" "KTHW_NSG_Internal" {
#   name                         = "Internal"
#   priority                     = 100
#   direction                    = "Inbound"
#   access                       = "Allow"
#   protocol                     = "*"
#   source_port_range            = "*"
#   destination_port_range       = "*"
#   source_address_prefixes      = ["10.10.10.0/24", "10.20.0.0/16"]
#   destination_address_prefixes = ["10.10.10.0/24", "10.20.0.0/16"]
#   resource_group_name          = azurerm_resource_group.KTHW_RG.name
#   network_security_group_name  = azurerm_network_security_group.KTHW_NSG.name
# }

# resource "azurerm_network_security_rule" "KTHW_NSG_External" {
#   name                        = "External"
#   priority                    = 101
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_ranges     = ["22", "6443"]
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.KTHW_RG.name
#   network_security_group_name = azurerm_network_security_group.KTHW_NSG.name
# }

# resource "azurerm_network_security_rule" "KTHW_NSG_External_ICMP" {
#   name                        = "External_ICMP"
#   priority                    = 102
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Icmp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.KTHW_RG.name
#   network_security_group_name = azurerm_network_security_group.KTHW_NSG.name
# }

# resource "azurerm_public_ip" "jumpbox_ip" {
#   name                = "jumpbox_ip"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   allocation_method   = "Static"
# }

# resource "azurerm_network_interface" "Jumpbox_NIC" {
#   name                 = "Jumpbox_NIC"
#   resource_group_name  = azurerm_resource_group.KTHW_RG.name
#   location             = azurerm_resource_group.KTHW_RG.location
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "jumpbox"
#     subnet_id                     = azurerm_subnet.KTHW_Subnet1.id
#     private_ip_address_allocation = "Static"
#     private_ip_address            = "10.10.10.100"
#     public_ip_address_id          = azurerm_public_ip.jumpbox_ip.id
#   }
# }

# resource "azurerm_linux_virtual_machine" "Jumpbox" {
#   name                = "Jumpbox"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   size                = "Standard_B1s"
#   admin_username      = var.admin_username
#   network_interface_ids = [
#     azurerm_network_interface.Jumpbox_NIC.id
#   ]

#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = file("../pub.key")
#   }

#   os_disk {
#     caching              = "None"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   tags = {
#     "env"  = "kthw"
#     "type" = "jumpbox"
#   }
# }

# resource "azurerm_network_interface" "KController_NIC" {
#   count                = 2
#   name                 = "${var.controller_name}_${count.index}"
#   resource_group_name  = azurerm_resource_group.KTHW_RG.name
#   location             = azurerm_resource_group.KTHW_RG.location
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.KTHW_Subnet1.id
#     private_ip_address_allocation = "Static"
#     private_ip_address            = "10.10.10.1${count.index}"
#   }
# }

# resource "azurerm_linux_virtual_machine" "KController" {
#   count               = 2
#   name                = "${var.controller_name}${count.index}"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   size                = var.controller_name
#   admin_username      = var.admin_username
#   network_interface_ids = [
#     azurerm_network_interface.KController_NIC[count.index].id
#   ]

#   admin_ssh_key {
#     username   = var.admin_username
#     public_key = file("../pub.key")
#   }

#   os_disk {
#     caching              = "None"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 50
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   tags = {
#     "env"  = "kthw"
#     "type" = "controller"
#   }
# }

# resource "azurerm_network_interface" "KWorker_NIC" {
#   count                = 3
#   name                 = "${var.worker_name}_${count.index}"
#   resource_group_name  = azurerm_resource_group.KTHW_RG.name
#   location             = azurerm_resource_group.KTHW_RG.location
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.KTHW_Subnet1.id
#     private_ip_address_allocation = "Static"
#     private_ip_address            = "10.10.10.2${count.index}"
#   }
# }

# resource "azurerm_linux_virtual_machine" "KWorker" {
#   count               = 3
#   name                = "${var.worker_name}${count.index}"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   size                = var.worker_vm
#   admin_username      = var.admin_username
#   network_interface_ids = [
#     azurerm_network_interface.KWorker_NIC[count.index].id
#   ]

#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = file("../pub.key")
#   }

#   os_disk {
#     caching              = "None"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 50
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   tags = {
#     "env"  = "kthw"
#     "type" = "worker"
#   }
# }

# resource "azurerm_public_ip" "KTHW_LB_IP" {
#   name                = "KTHW_LB_IP"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_lb" "LB" {
#   name                = "LB"
#   resource_group_name = azurerm_resource_group.KTHW_RG.name
#   location            = azurerm_resource_group.KTHW_RG.location
#   sku                 = "Standard"
#   sku_tier            = "Regional"

#   frontend_ip_configuration {
#     name                 = "PublicIP"
#     public_ip_address_id = azurerm_public_ip.KTHW_LB_IP.id
#     availability_zone    = "No-Zone"
#   }

# }

# resource "azurerm_lb_backend_address_pool" "KController_pool" {
#   loadbalancer_id = azurerm_lb.LB.id
#   name            = "KController_pool"
# }

# resource "azurerm_lb_backend_address_pool_address" "KController_address" {
#   count                   = 2
#   name                    = "KController${count.index}"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.KController_pool.id
#   virtual_network_id      = azurerm_virtual_network.KTHW_VNet.id
#   ip_address              = "10.10.10.1${count.index}"
# }

# resource "azurerm_lb_rule" "inbound_kubectl" {
#   resource_group_name            = azurerm_resource_group.KTHW_RG.name
#   loadbalancer_id                = azurerm_lb.LB.id
#   name                           = "inbound_kubectl"
#   protocol                       = "Tcp"
#   frontend_port                  = "6443"
#   backend_port                   = "6443"
#   frontend_ip_configuration_name = "PublicIP"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.KController_pool.id]
# }

