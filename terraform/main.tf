resource "azurerm_resource_group" "kthw_rg" {
  name     = "kthw_rg"
  location = "North Europe"
}

resource "azurerm_virtual_network" "kthw_vnet" {
  name                = "kthw_vnet"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "kthw_bastion_subnet" {
  name                 = "kthw_bastion_subnet"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  virtual_network_name = azurerm_virtual_network.kthw_vnet.name
  address_prefixes     = ["10.10.0.0/24"]
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

resource "azurerm_public_ip" "kthw_bastion_public_ip" {
  name                = "kthw_bastion_public_ip"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "kthw_loadbalancer_public_ip" {
  name                = "kthw_loadbalancer_public_ip"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_table" "kthw_route_table_pods" {
  name                = "kthw_route_table_pods"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
}

resource "azurerm_route" "pod_route" {
  count                  = var.num_workers
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
  subnet_id      = azurerm_subnet.kthw_worker_subnet.id
  route_table_id = azurerm_route_table.kthw_route_table_pods.id
}

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

resource "azurerm_network_security_group" "kthw_bastion_nsg" {
  name                = "kthw_bastion_nsg"
  location            = azurerm_resource_group.kthw_rg.location
  resource_group_name = azurerm_resource_group.kthw_rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_controller_subnet_assoc" {
  subnet_id                 = azurerm_subnet.kthw_controller_subnet.id
  network_security_group_id = azurerm_network_security_group.kthw_controller_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_worker_subnet_assoc" {
  subnet_id                 = azurerm_subnet.kthw_worker_subnet.id
  network_security_group_id = azurerm_network_security_group.kthw_worker_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_bastion_subnet_assoc" {
  subnet_id                 = azurerm_subnet.kthw_bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.kthw_bastion_nsg.id
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
  network_security_group_name  = azurerm_network_security_group.kthw_controller_nsg.name
}

resource "azurerm_network_security_rule" "nsg_rule_allow_https_port" {
  name                         = "allow_https_port"
  priority                     = 1010
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "6443"
  source_address_prefixes      = ["0.0.0.0/0"]
  destination_address_prefixes = ["10.10.10.0/24"]
  resource_group_name          = azurerm_resource_group.kthw_rg.name
  network_security_group_name  = azurerm_network_security_group.kthw_controller_nsg.name
}

resource "azurerm_network_security_rule" "nsg_rule_allow_ssh_to_bastion" {
  name                         = "allow_ssh_to_bastion"
  priority                     = 1000
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "TCP"
  source_port_range            = "*"
  destination_port_range       = "22"
  source_address_prefixes      = ["0.0.0.0/0"]
  destination_address_prefixes = ["10.10.0.0/24"]
  resource_group_name          = azurerm_resource_group.kthw_rg.name
  network_security_group_name  = azurerm_network_security_group.kthw_bastion_nsg.name
}

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

resource "azurerm_network_interface" "kthw_worker_nic" {
  count                = var.num_workers
  name                 = "${var.worker_name}${count.index}"
  resource_group_name  = azurerm_resource_group.kthw_rg.name
  location             = azurerm_resource_group.kthw_rg.location
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kthw_worker_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.20.1${count.index}"
  }
}

resource "azurerm_network_interface" "kthw_bastion_nic" {
  name                = "kthw_bastion_nic"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  # enable_ip_forwarding = true

  ip_configuration {
    name                          = "bastion"
    subnet_id                     = azurerm_subnet.kthw_bastion_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.0.10"
    public_ip_address_id          = azurerm_public_ip.kthw_bastion_public_ip.id
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

resource "azurerm_linux_virtual_machine" "kthw_bastion" {
  name                = "kthwbastion"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  size                = var.bastion_vm
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.kthw_bastion_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("../pub.key")
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_lb" "kthw_controller_loadbalancer" {
  name                = "kthw_controller_loadbalancer"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  location            = azurerm_resource_group.kthw_rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "controller_loadbalancer_frontend"
    public_ip_address_id = azurerm_public_ip.kthw_loadbalancer_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "controller_backend_pool" {
  loadbalancer_id = azurerm_lb.kthw_controller_loadbalancer.id
  name            = "controller_backend_pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "controller_backend_pool_addresses" {
  count                   = var.num_controllers
  backend_address_pool_id = azurerm_lb_backend_address_pool.controller_backend_pool.id
  network_interface_id    = azurerm_network_interface.kthw_controller_nic[count.index].id
  ip_configuration_name   = "internal"
}

resource "azurerm_lb_probe" "controller_loadbalancer_probe" {
  name                = "controller_health_probe"
  resource_group_name = azurerm_resource_group.kthw_rg.name
  loadbalancer_id     = azurerm_lb.kthw_controller_loadbalancer.id
  protocol            = "Https"
  port                = 6443
  request_path        = "/healthz"
}

resource "azurerm_lb_rule" "controller_loadbalancer_rule" {
  name                           = "ControlPlane"
  resource_group_name            = azurerm_resource_group.kthw_rg.name
  loadbalancer_id                = azurerm_lb.kthw_controller_loadbalancer.id
  frontend_ip_configuration_name = "controller_loadbalancer_frontend"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.controller_backend_pool.id]
  probe_id                       = azurerm_lb_probe.controller_loadbalancer_probe.id
}
