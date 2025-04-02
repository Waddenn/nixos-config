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
  ];
}
