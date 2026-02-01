# NixOS Configuration Tasks

# Format all Nix files
fmt:
    nix fmt

# Validate the Nix configuration
validate:
    nix flake check

# Trigger GitOps deployment on dev-nixos
deploy:
    ssh nixos@dev-nixos "sudo systemctl start internal-gitops"

# Watch GitOps deployment logs
deploy-watch:
    ssh nixos@dev-nixos "sudo journalctl -u internal-gitops -f"

# Check GitOps service status
deploy-status:
    ssh nixos@dev-nixos "sudo systemctl status internal-gitops"
