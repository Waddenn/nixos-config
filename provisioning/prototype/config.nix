# Only this disposable container belongs to this state. No existing host is imported.
{...}: {
  terraform = {
    required_version = "~> 1.12.0";
    required_providers.proxmox = {
      source = "bpg/proxmox";
      version = "0.113.1";
    };
    backend.local.path = "/var/lib/proxmox-prototype/terraform.tfstate";
  };
  provider.proxmox = {
    endpoint = "https://proxade:8006/";
    insecure = false;
  };
  variable.ssh_public_key.type = "string";
  variable.template_file_id.type = "string";
  resource.proxmox_virtual_environment_container.prototype = {
    node_name = "proxade";
    vm_id = 9901;
    description = "Disposable nixos-config provisioning prototype; dedicated OpenTofu state";
    tags = ["nixos-prototype"];
    unprivileged = true;
    features.nesting = true;
    protection = true;
    started = true;
    start_on_boot = false;
    cpu.cores = 1;
    memory = {
      dedicated = 512;
      swap = 0;
    };
    disk = {
      datastore_id = "Storage2";
      size = 4;
    };
    operating_system = {
      template_file_id = "\${var.template_file_id}";
      type = "nixos";
    };
    initialization = {
      hostname = "nixos-provisioning-prototype";
      ip_config.ipv4.address = "dhcp";
      user_account.keys = ["\${var.ssh_public_key}"];
    };
    network_interface = {
      name = "eth0";
      bridge = "vmbr0";
    };
    lifecycle.prevent_destroy = true;
  };
}
