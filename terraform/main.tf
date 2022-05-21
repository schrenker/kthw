# Governance
resource "azurerm_resource_group" "kthw_rg" {
  name     = "kthw_rg"
  location = "North Europe"
}

# networking
resource "azurerm_virtual_network" "kthw_vnet" {
  name                = "kthw_vnet"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "kthw_controller_subnet" {
  name                 = "kthw_controller_subnet"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  virtual_network_name = azurerm_virtual_network.kthw_vnet.name
  address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_subnet" "kthw_worker_subnet" {
  name                 = "kthw_worker_subnet"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  virtual_network_name = azurerm_virtual_network.kthw_vnet.name
  address_prefixes     = ["10.10.20.0/24"]
}

resource "azurerm_route_table" "kthw_route_table_pods" {
  name                = "kthw_route_table_pods"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
}

resource "azurerm_route" "pod_route" {
  count                  = var.num_worker
  name                   = "pod_route_${count.index}"
  resource_group_name    = azurerm_resource_group.kthw_rg.name
  route_table_name       = azurerm_route_table.kthw_route_table_pods.name
  address_prefix         = "10.20.${count.index}.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.10.20.1${count.index}"
}

resource "azurerm_subnet_route_table_association" "control_subnet_route_assoc" {
  subnet_id      = azurerm_subnet.kthw_controller_subnet.id
  route_table_id = azurerm_route_table.kthw_route_table_pods.id
}

resource "azurerm_subnet_route_table_association" "worker_subnet_route_assoc" {
  subnet_id      = azurerm_subnet.kthw_worker.id
  route_table_id = azurerm_route_table.kthw_route_table_pods.id
}

# communication flow
resource "azurerm_network_security_group" "kthw_controller_nsg" {
  name                = "kthw_controller_nsg"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
}

resource "azurerm_network_security_group" "kthw_worker_nsg" {
  name                = "kthw_worker_nsg"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_controller_subnet_assoc" {
  subnet_id                 = azurerm_subnet.kthw_control_subnet.id
  network_security_group_id = azurerm_network_security_group.kthw_controller_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_worker_subnet_assoc" {
  subnet_id                 = azurerm_subnet.kthw_worker_subnet.id
  network_security_group_id = azurerm_network_security_group.kthw_worker_nsg.id
}

resource "azurerm_network_security_rule" "nsg_rule_allow_pods_to_controllers" {
  name                         = "allow_pods_to_controllers"
  priority                     = 1000
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "*"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = ["10.20.0.0/16"]
  destination_address_prefixes = ["10.10.10.0/24"]
  resource_group_name          = azurerm_resource_group.kthw_rg.name
  network_security_group_name  = azurerm_network_security_group.kthw_control_nsg.name
}

# compute
resource "azurerm_availability_set" "kthw_controller_as" {
  name                = "kthw_controller_as"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
}

resource "azurerm_availability_set" "kthw_worker_as" {
  name                = "kthw_worker_as"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
}

resource "azurerm_network_interface" "kthw_controller_nic" {
  count               = var.num_controllers
  name                = "${var.controller_name}${count.index}"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  # enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kthw_controller_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.10.1${count.index}"
  }
}

resource "azurerm_linux_virtual_machine" "kthw_controller" {
  count               = var.num_controllers
  name                = "${var.controller_name}${count.index}"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  size                = var.controller_vm
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.kthw_controller_nic[count.index].id
  ]
  availability_set_id = azurerm_availability_set.kthw_controller_as.id

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("../pub.key")
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "kthw_worker_nic" {
  count                = var.num_workers
  name                 = "${var.worker_name}${count.index}"
  resource_group_name  = azurerm_resource_group.KTHW_RG.name
  location             = azurerm_resource_group.KTHW_RG.location
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kthw_worker_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.20.1${count.index}"
  }
}

resource "azurerm_linux_virtual_machine" "kthw_worker" {
  count               = var.num_workers
  name                = "${var.worker_name}${count.index}"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  size                = var.worker_vm
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.kthw_worker_nic[count.index].id
  ]
  availability_set_id = azurerm_availability_set.kthw_worker_as.id

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("../pub.key")
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

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

