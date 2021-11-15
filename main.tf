resource "azurerm_resource_group" "KTHW_RG" {
  name     = "KTHW_RG"
  location = "North Europe"
  tags = {
    "env" = "kthw"
  }
}

resource "azurerm_virtual_network" "KTHW_VNet" {
  name                = "KTHW_VNet"
  location            = azurerm_resource_group.KTHW_RG.location
  resource_group_name = azurerm_resource_group.KTHW_RG.name
  address_space       = ["10.10.0.0/16"]
  tags = {
    "env" = "kthw"
  }
}

resource "azurerm_subnet" "KTHW_Subnet1" {
  name                 = "KTHW_Subnet1"
  resource_group_name  = azurerm_resource_group.KTHW_RG.name
  virtual_network_name = azurerm_virtual_network.KTHW_VNet.name
  address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_network_security_group" "KTHW_NSG" {
  name                = "KTHW_NSG"
  location            = azurerm_resource_group.KTHW_RG.location
  resource_group_name = azurerm_resource_group.KTHW_RG.name
}

resource "azurerm_subnet_network_security_group_association" "KTHW_Subnet1_NSG" {
  subnet_id                 = azurerm_subnet.KTHW_Subnet1.id
  network_security_group_id = azurerm_network_security_group.KTHW_NSG.id
}
