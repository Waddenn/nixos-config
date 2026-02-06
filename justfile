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
    nix shell nixpkgs#sops --command sops updatekeys -y secrets/cf_api_token.env.enc
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

# Generate Authelia password hash
authelia-hash-password:
    ./scripts/authelia-hash-password.sh

# Generate Authelia secrets (automated)
authelia-generate-secrets:
    ./scripts/add-authelia-secrets.sh

# Initialize users_database.yml on Authelia server with admin user
authelia-init-users:
    ./scripts/authelia-init-users.sh

# Create a new Authelia user (interactive)
authelia-create-user:
    ./scripts/authelia-create-user.sh

# SSH to Authelia server to manage users manually
authelia-ssh:
    ssh root@authelia
