---
description: Trigger an immediate GitOps deployment on the dev-nixos controller
---

To trigger an immediate update and rollout of the configuration across the fleet:

1. Ensure your local changes are pushed to the `main` branch on GitHub.
// turbo
2. Run the following command to start the GitOps service on the controller:
```bash
ssh nixos@dev-nixos "sudo systemctl start internal-gitops"
```

3. (Optional) To follow the logs and witness the new **Visual Dashboard**:
```bash
ssh nixos@dev-nixos "journalctl -u internal-gitops -f"
```

