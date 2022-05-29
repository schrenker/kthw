resource "local_file" "inventory" {
  content = templatefile("./templates/inventory.tmpl",
    {
      bastion_host = azurerm_linux_virtual_machine.kthw_bastion.public_ip_address
      controllers  = azurerm_linux_virtual_machine.kthw_controller.*.private_ip_address
      workers      = azurerm_linux_virtual_machine.kthw_worker.*.private_ip_address
  })
  filename = "../ansible/inventory"
}

resource "local_file" "sshcfg" {
  content = templatefile("./templates/sshcfg.tmpl",
    {
      bastion        = azurerm_linux_virtual_machine.kthw_bastion.public_ip_address
      admin_username = var.admin_username
  })
  filename = "../ansible/ssh.cfg"
}

resource "local_file" "allvars" {
  content = templatefile("./templates/all.yml.tmpl",
    {
      loadbalancer_ip = azurerm_lb.kthw_controller_loadbalancer.frontend_ip_configuration.private_ip_address
      controller_ips  = join(",", azurerm_linux_virtual_machine.kthw_controller.*.private_ip_address)
      username        = var.admin_username
  })
  filename = "../ansible/group_vars/all.yml"
}
