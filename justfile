# NixOS Configuration Tasks

# Format all Nix files
fmt:
    nix fmt

# Validate the Nix configuration
validate:
    nix flake check

# Policy tests do not contact any host
test:
    python3 -m unittest discover -s tests -p 'test_*.py'

# Verify that the deployment and CI produce identical systems
check-colmena:
    python3 scripts/check-colmena.py

# Prepare a dependency update for review
update:
    nix flake update
    ./scripts/update-caddy-plugin-hash.sh
    nix shell nixpkgs#skopeo --command python3 scripts/update-container-images.py
    nix shell nixpkgs#skopeo --command python3 scripts/update-beszel.py

# Trigger GitOps deployment on dev-nixos
deploy:
    ssh nixos@dev-nixos "sudo systemctl start internal-gitops"

# Watch GitOps deployment logs
deploy-watch:
    ssh nixos@dev-nixos "sudo journalctl -u internal-gitops -f"

# Check GitOps service status
deploy-status:
    ssh nixos@dev-nixos "sudo systemctl status internal-gitops"

# Reconcile the fleet even when the Git revision did not change
reconcile:
    ssh nixos@dev-nixos "sudo touch /var/lib/internal-gitops/force && sudo systemctl start internal-gitops.service"

# Compare repository, active system and boot profile on every deployment target
fleet-status:
    ./scripts/fleet-status.sh

# === SOPS Secrets Management ===

# Edit secrets.yaml with SOPS
secrets-edit:
    nix shell nixpkgs#sops --command sops secrets/secrets.yaml

# View decrypted secrets.yaml (read-only)
secrets-view:
    nix shell nixpkgs#sops --command sops -d secrets/secrets.yaml

# Re-encrypt all secrets after adding a new host key
secrets-rekey:
    @echo "🔄 Re-encrypting all secrets..."
    nix shell nixpkgs#sops --command sops updatekeys -y secrets/secrets.yaml
    @echo "✅ All secrets re-encrypted"

# Add a new host to SOPS (usage: just secrets-add-host hostname)
secrets-add-host hostname:
    @echo "📡 Fetching SSH key from {{hostname}}..."
    @ssh root@{{hostname}} 'cat /etc/ssh/ssh_host_ed25519_key.pub' > /tmp/{{hostname}}.pub
    @echo "🔑 Converting to age format..."
    @nix shell nixpkgs#ssh-to-age --command sh -c 'cat /tmp/{{hostname}}.pub | ssh-to-age'
    @echo ""
    @echo "⚠️  Add this key to .sops.yaml manually:"
    @echo "  - &{{hostname}} <key_from_above>"
    @echo ""
    @echo "Then run: just secrets-rekey"
    @rm /tmp/{{hostname}}.pub

# SSH to Authelia for application administration
authelia-ssh:
    ssh root@authelia
