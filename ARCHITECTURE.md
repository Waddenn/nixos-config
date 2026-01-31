# Architecture & Contribution Guide

This document crystallizes the architectural vision of this NixOS configuration repository. It serves as a guide for future maintenance and development (for humans and AI agents).

## 🌍 Philosophy
**"Explicit Infra, Implicit Services."**

We strive for a balance between modularity and clarity:
- **Infrastructure (Base)** is explicitly imported by each host.
- **Services (Capabilities)** are activated via standard NixOS options.
- **No Magic**: We avoid hidden injection of configuration by the builder.

## 📂 Directory Structure

- **`flake.nix`**: The entry point. Minimalist.
- **`lib/`**: Contains the logic (`builder.nix`) and helper functions. The "Brain".
- **`hosts/`**: The "Assembler". Each directory represents a machine.
    - Contains strictly configuration (values), no logic.
- **`modules/`**: The "Bricks".
    - **`infra/`**: Base layers (Templates) like `proxmox-lxc.nix`, `proxmox-vm.nix`.
    - **`services/`**: Feature modules (Networking, Monitoring, Dev...).
    - **`container/`**: OCI container definitions wrapped in modules.
    - **`identities/`**: User configurations (e.g. `nixos.nix`).
- **`secrets/`**: Encrypted secrets via SOPS.

## 🏗️ The "Host" Pattern (How to add a machine)

Every host definition in `hosts/<name>/default.nix` MUST follow this pattern:

```nix
{ ... }: {
  # 1. EXPLICIT INFRASTRUCTURE
  # Always import the base layer corresponding to the runtime environment.
  imports = [ ../../modules/infra/proxmox-lxc.nix ]; 

  # 2. ENABLE SERVICES
  # Use the `my-services` namespace.
  my-services.networking.tailscale = {
    enable = true;
    role = "server";
  };
  my-services.monitoring.uptime-kuma.enable = true;
  
  # 3. CONFIGURE NATIVE OPTIONS
  time.timeZone = "Europe/Paris";
}
```

## 🧩 The "Module" Pattern (How to add a service)

All services (native or Docker) MUST be wrapped in a NixOS module.

**Rules:**
1.  **Namespace**: Use `options.my-services.<category>.<name>`.
2.  **Toggle**: Always provide an `enable` option (`lib.mkEnableOption`).
3.  **Implementation**: Wrap the config in `lib.mkIf config.my-services....enable`.

**Example:**
```nix
{ config, lib, ... }: {
  options.my-services.super-app.enable = lib.mkEnableOption "Super App";
  
  config = lib.mkIf config.my-services.super-app.enable {
    # Implementation (Docker or Systemd)
    virtualisation.oci-containers.containers."super-app" = { ... };
  };
}
```

## ⚠️ Anti-Patterns (Guidelines)
These patterns are currently discouraged to maintain consistency, but can be revisited if the architecture evolves:

- **Direct imports in hosts**: `imports = [ ../../modules/some-service.nix ]`. Use options instead!
- **Magic Injection**: Avoid modifying `hosts/default.nix` to inject modules globally without clear intent.
- **Root clutter**: Keep the root directory clean.

## 🚀 Evolution
This architecture is a solid baseline, not a cage.
If you find a better way to handle things (e.g., a new standard for container management), **challenge these rules**.
The goal is always: **Maintainability > Clarity > Dogma**.

