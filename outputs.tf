resource "local_file" "inventory" {
  content = templatefile("./templates/inventory.tmpl",
    {
      ansibleJumpbox      = azurerm_linux_virtual_machine.Jumpbox.public_ip_address
      ansibleKControllers = azurerm_linux_virtual_machine.KController.*.private_ip_address
      ansibleKWorkers     = azurerm_linux_virtual_machine.KWorker.*.private_ip_address
  })
  filename = "./ansible/inventory"
}

resource "local_file" "sshcfg" {
  content = templatefile("./templates/sshcfg.tmpl",
    {
      ansibleJumpbox = azurerm_linux_virtual_machine.Jumpbox.public_ip_address
  })
  filename = "./ansible/ssh.cfg"
}

resource "local_file" "allvars" {
  content = templatefile("./templates/all.yml.tmpl",
    {
      lb_ip = azurerm_public_ip.KTHW_LB_IP.ip_address
  })
  filename = "./ansible/group_vars/all.yml"
}
