{lib, ...}: let
  services = import ./inventory.nix {inherit lib;};
in {
  terraform = {
    required_version = "~> 1.12.0";
    required_providers.proxmox = {
      source = "bpg/proxmox";
      version = "0.113.1";
    };
    # Preserve the original state; moving a source directory must not lose ownership.
    backend.local.path = "/var/lib/proxmox-prototype/terraform.tfstate";
  };
  provider.proxmox = {
    endpoint = "https://proxade:8006/";
    insecure = false;
  };
  variable.bootstrap.type = "map(object({ssh_public_key=string, template_file_id=string}))";
  resource.proxmox_virtual_environment_container =
    lib.mapAttrs (name: s: {
      node_name = s.node;
      vm_id = s.vmId;
      description = "Disposable nixos-config provisioning prototype; dedicated OpenTofu state";
      tags = ["nixos-prototype"];
      unprivileged = true;
      features.nesting = true;
      protection = true;
      started = true;
      start_on_boot = false;
      cpu.cores = s.cores;
      memory = {
        dedicated = s.memoryMiB;
        swap = 0;
      };
      disk = {
        datastore_id = s.storage;
        size = s.diskGiB;
      };
      operating_system = {
        template_file_id = "\${var.bootstrap[\"${name}\"].template_file_id}";
        type = "nixos";
      };
      initialization = {
        hostname = s.hostname;
        ip_config.ipv4.address = s.ipv4;
        user_account.keys = ["\${var.bootstrap[\"${name}\"].ssh_public_key}"];
      };
      network_interface = {
        name = "eth0";
        bridge = s.bridge;
      };
      lifecycle.prevent_destroy = true;
    })
    services;
}
