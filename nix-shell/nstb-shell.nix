{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    aircrack-ng
    gobuster
    hashcat
    httprobe
    thc-hydra
    john
    masscan
    metasploit
    nikto
    nmap
    recon-ng
    sqlmap
    theharvester
    wireshark
    nuclei
    enum4linux
    whatweb
    wpscan
    netdiscover
    seclists
    burpsuite
    gophish
  ];
  
    shellHook = ''
    export SECLISTS_DIR=$(nix eval --raw nixpkgs#seclists)/share/wordlists/seclists
    echo "[+] SecLists is available at: $SECLISTS_DIR"
  '';
}
