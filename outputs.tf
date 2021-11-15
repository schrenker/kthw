resource "local_file" "inventory" {
  content = templatefile("./templates/inventory.tmpl",
    {
      ansibleJumpbox      = azurerm_linux_virtual_machine.Jumpbox.public_ip_address
      ansibleKControllers = azurerm_linux_virtual_machine.KController.*.private_ip_address
      ansibleKWorkers     = azurerm_linux_virtual_machine.KWorker.*.private_ip_address
  })
  filename = "./ansible/inventory"
}
