{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Network Utils
    ethtool
    dnsutils # dig, nslookup
    ipcalc
    mtr # My Traceroute
    nmap # Security scanning
    
    # System Utils
    btop # Better htop
    git
    vim
    neovim
    wget
    curl
    unzip
    zip
    fd # fast find
    ripgrep # fast grep
    jq # json parser
    file
    which
    tree
    just # command runner
  ];
}
