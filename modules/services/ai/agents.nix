{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.ai.infra-agents.enable = lib.mkEnableOption "Enable infrastructure AI agents environment";

  config = lib.mkIf config.my-services.ai.infra-agents.enable {
    environment.systemPackages = with pkgs; [
      # === Base Development ===
      git
      vim
      jq
      yq
      tree
      wget
      curl
      
      # === Infrastructure as Code ===
      colmena

      # === Languages & Runtimes ===
      python3
      python3Packages.pip
      python3Packages.virtualenv
      nodejs_22
      corepack
      rustc
      cargo
      go
      
      # === GitHub CLI & Tools ===
      gh
      github-copilot-cli  # GitHub Copilot CLI
      
      # === Cybersecurity & Pentesting ===
      nmap
      masscan
      rustscan
      nikto
      sqlmap
      metasploit
      burpsuite
      wireshark
      tcpdump
      aircrack-ng
      hydra
      john
      hashcat
      ffuf
      gobuster
      feroxbuster
      wfuzz
      
      # === Network Analysis ===
      netcat
      socat
      iperf3
      mtr
      bind.dnsutils  # dig, nslookup, host
      ldns  # drill
      whois
      
      # === Security Scanning ===
      trivy
      grype
      syft
      prowler
      nuclei
      
      # === Container Security ===
      hadolint
      dive
      
      # === OSINT ===
      theharvester
      recon-ng
      sherlock
      
      # === Forensics & Analysis ===
      binwalk
      foremost
      volatility3
      sleuthkit
      
      # === Web Tools ===
      httpie
      curlie
      xh
      
      # === Cloud CLI ===
      awscli2
      google-cloud-sdk
      azure-cli
      
      # === Utilities ===
      ripgrep
      fd
      bat
      eza
      fzf
      zellij  # Multiplexeur moderne (recommandé)
      tmux
      screen
      htop
      btop
      ncdu
      
      # === Compression ===
      p7zip
      unzip
      gzip
      bzip2
      xz
    ];

    # Configuration pour permettre l'installation de packages npm non disponibles dans nixpkgs
    # (exemple: codex-cli, etc.)
    environment.variables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };
    
    # Ajouter le bin path de npm global au PATH
    environment.sessionVariables = {
      PATH = "$HOME/.npm-global/bin:$PATH";
    };

    # Enable Docker for agent container operations
    my-services.dev.docker.enable = true;

    # Ensure the main user can use docker
    users.users.nixos.extraGroups = ["docker"];

    # Configuration Zellij pour terminal web (évite conflits avec raccourcis navigateur)
    environment.etc."zellij/config.kdl".source = ../../data/zellij-config.kdl;
    environment.sessionVariables = {
      ZELLIJ_CONFIG_DIR = "/etc/zellij";
    };
  };
}
