<div align="left" style="position: relative;">
<img src="https://raw.githubusercontent.com/PKief/vscode-material-icon-theme/ec559a9f6bfd399b82bb44393651661b08aaf7ba/icons/folder-markdown-open.svg" align="right" width="30%" style="margin: -20px 0 0 20px;">
<h1>NIXOS-CONFIG</h1>
<p align="left">
	<em>NixOS-Config: Orchestrating Harmony in System Configuration!</em>
</p>
<p align="left">
	<img src="https://img.shields.io/github/license/Waddenn/nixos-config?style=default&logo=opensourceinitiative&logoColor=white&color=0080ff" alt="license">
	<img src="https://img.shields.io/github/last-commit/Waddenn/nixos-config?style=default&logo=git&logoColor=white&color=0080ff" alt="last-commit">
	<img src="https://img.shields.io/github/languages/top/Waddenn/nixos-config?style=default&color=0080ff" alt="repo-top-language">
	<img src="https://img.shields.io/github/languages/count/Waddenn/nixos-config?style=default&color=0080ff" alt="repo-language-count">
</p>
<p align="left"><!-- default option, no dependency badges. -->
</p>
<p align="left">
	<!-- default option, no dependency badges. -->
</p>
</div>
<br clear="right">

## 🔗 Table of Contents

- [📍 Overview](#-overview)
- [👾 Features](#-features)
- [📁 Project Structure](#-project-structure)
  - [📂 Project Index](#-project-index)
- [🚀 Getting Started](#-getting-started)
  - [☑️ Prerequisites](#-prerequisites)
  - [⚙️ Installation](#-installation)
  - [🤖 Usage](#🤖-usage)
  - [🧪 Testing](#🧪-testing)
- [📌 Project Roadmap](#-project-roadmap)
- [🔰 Contributing](#-contributing)
- [🎗 License](#-license)
- [🙌 Acknowledgments](#-acknowledgments)

---

## 📍 Overview

The nixos-config project is an open-source solution for managing and maintaining NixOS configurations. It simplifies system configuration through automated building, updating, and garbage collection, and facilitates seamless deployment and initialization. Ideal for both desktop and server systems, it integrates resources like home-manager and nix-flatpak, providing a streamlined, error-free environment for developers and system administrators.

---

## 👾 Features

|      | Feature         | Summary       |
| :--- | :---:           | :---          |
| ⚙️  | **Architecture**  | <ul><li>The project is built on NixOS, a Linux distribution that uses the Nix package manager.</li><li>It uses a 'justfile' for orchestrating the building, updating, and garbage collection of the NixOS configuration.</li><li>It also uses 'flake.nix' for managing the project's dependencies and outputs.</li></ul> |
| 🔩 | **Code Quality**  | <ul><li>The codebase is primarily written in Nix language, with some shell scripts and YAML files.</li><li>The 'justfile' and 'flake.nix' files indicate a well-structured and organized codebase.</li><li>However, without a detailed review of the code, it's hard to make a definitive statement about the code quality.</li></ul> |
| 📄 | **Documentation** | <ul><li>The primary language of the project is Nix, with some usage of shell scripts and YAML.</li><li>There is no clear documentation on how to install, use, or test the project.</li><li>More detailed documentation would be beneficial for new contributors and users.</li></ul> |
| 🔌 | **Integrations**  | <ul><li>The project integrates with a wide range of services and applications, as indicated by the numerous '.nix' files in the dependencies.</li><li>These include Gitea, Ansible, Steam, Nvidia, Python3, Pipewire, GitLab, Nginx, Firefox, Docker, and many others.</li><li>This suggests a highly versatile and flexible system configuration.</li></ul> |
| 🧩 | **Modularity**    | <ul><li>The project appears to be highly modular, with separate '.nix' files for different services and applications.</li><li>This allows for easy addition, removal, or modification of individual components without affecting the rest of the system.</li><li>The use of 'justfile' and 'flake.nix' also contributes to the modularity of the project.</li></ul> |
| 🧪 | **Testing**       | <ul><li>There is no clear information on testing in the provided context details.</li><li>Without specific test commands or a test suite, it's hard to assess the project's testing capabilities.</li><li>Adding a testing framework would improve the project's reliability and maintainability.</li></ul> |
| ⚡️  | **Performance**   | <ul><li>Without specific performance metrics or benchmarks, it's hard to assess the project's performance.</li><li>The use of NixOS and the Nix package manager, however, suggests a focus on reproducibility and reliability, which can contribute to performance.</li><li>Performance would also depend on the specific configuration and usage of the system.</li></ul> |

---

## 📁 Project Structure

```sh
└── nixos-config/
    ├── flake.lock
    ├── flake.nix
    ├── home-manager
    │   └── tom
    ├── hosts
    │   ├── asus-nixos
    │   ├── lenovo-nixos
    │   └── proxmox-vm
    ├── justfile
    ├── lib
    │   └── mkSystems.nix
    ├── modules
    │   ├── boot
    │   ├── console
    │   ├── environment
    │   ├── global.nix
    │   ├── hardware
    │   ├── i18n
    │   ├── networking
    │   ├── nix
    │   ├── nixpkgs
    │   ├── programs
    │   ├── security
    │   ├── services
    │   ├── system
    │   ├── templates
    │   ├── time
    │   ├── virtualisation
    │   └── zramSwap
    ├── scripts
    │   ├── bootstrap.sh
    │   └── deploy.sh
    ├── secrets
    │   ├── cf_api_token.env.enc
    │   └── secrets.yaml
    ├── users
    │   ├── docker
    │   ├── nixos
    │   └── tom
    └── wallpapers
        ├── gnome-wallpaper-adwaita.jpg
        ├── makima.png
        ├── makima2.png
        └── wallhaven.png
```


### 📂 Project Index
<details open>
	<summary><b><code>NIXOS-CONFIG/</code></b></summary>
	<details> <!-- __root__ Submodule -->
		<summary><b>__root__</b></summary>
		<blockquote>
			<table>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/justfile'>justfile</a></b></td>
				<td>- The 'justfile' orchestrates the building, updating, and garbage collection of the NixOS configuration<br>- It also manages the Colmena build and application, updates flake inputs to their latest revisions, and handles secrets updates and generation<br>- This file plays a crucial role in maintaining the system's configuration and overall health.</td>
			</tr>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/flake.nix'>flake.nix</a></b></td>
				<td>- The flake.nix file serves as a configuration hub for the NixOS project, defining various system configurations for different machines and services<br>- It integrates multiple external resources, such as home-manager and nix-flatpak, and sets up configurations for desktop and server systems, including specific modules for each system.</td>
			</tr>
			</table>
		</blockquote>
	</details>
	<details> <!-- scripts Submodule -->
		<summary><b>scripts</b></summary>
		<blockquote>
			<table>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/scripts/deploy.sh'>deploy.sh</a></b></td>
				<td>- Deploy.sh within the scripts directory serves as the deployment script for the entire codebase<br>- It automates the process of pushing code changes to the production environment, ensuring a seamless and error-free deployment<br>- This script is integral to maintaining the project's continuous integration and delivery pipeline.</td>
			</tr>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/scripts/bootstrap.sh'>bootstrap.sh</a></b></td>
				<td>- Bootstrap.sh, located in the scripts directory, serves as the initialization script for the project<br>- It sets up the necessary environment and dependencies, ensuring the project's smooth operation<br>- This script is integral to the codebase architecture, providing the foundation for the project's functionality and performance.</td>
			</tr>
			</table>
		</blockquote>
	</details>
	<details> <!-- modules Submodule -->
		<summary><b>modules</b></summary>
		<blockquote>
			<table>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/global.nix'>global.nix</a></b></td>
				<td>- The 'global.nix' module orchestrates the integration of various system, hardware, networking, and service configurations for the project<br>- It imports a wide range of modules, from boot loaders and kernel settings to specific program setups and service configurations, ensuring a comprehensive and cohesive system setup.</td>
			</tr>
			</table>
			<details>
				<summary><b>services</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/fprintd.nix'>fprintd.nix</a></b></td>
						<td>- The fprintd.nix module in the services directory activates the fprintd service when enabled<br>- It specifically configures the fprintd service to use the libfprint-2-tod1-vfs0090 driver, enhancing the project's fingerprint recognition capabilities<br>- This module plays a crucial role in the overall biometric authentication feature of the codebase.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/flatpak.nix'>flatpak.nix</a></b></td>
						<td>- The module at 'modules/services/flatpak.nix' activates the Flatpak service within the project<br>- It introduces an option to enable Flatpak, a Linux application sandboxing and distribution framework, and sets the service to active when this option is enabled<br>- This contributes to the project's flexibility and extensibility in managing Linux applications.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/fwupd.nix'>fwupd.nix</a></b></td>
						<td>- The 'fwupd.nix' module in the services directory activates the fwupd service when enabled<br>- This service is crucial for managing firmware updates on Linux systems, enhancing the overall system's security and performance<br>- The module's activation is contingent on the 'fwupd.enable' option within the project's configuration.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/cloudflared.nix'>cloudflared.nix</a></b></td>
						<td>- The 'cloudflared.nix' module in the project architecture enables the Cloudflared service<br>- It sets up tunnels with specific credentials and default responses, providing a secure connection for the application<br>- This module is crucial for maintaining secure and reliable network communication within the application.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/vaultwarden.nix'>vaultwarden.nix</a></b></td>
						<td>- The Vaultwarden module in the codebase activates the Vaultwarden service when enabled<br>- It sets up the service configuration, including the server address, port, signup permissions, and domain<br>- This module plays a crucial role in managing the Vaultwarden service within the larger project architecture.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/nextcloud.nix'>nextcloud.nix</a></b></td>
						<td>- The 'nextcloud.nix' module in the codebase enables and configures the Nextcloud service<br>- It sets up the Nextcloud instance with specific settings, including database creation, Redis configuration, and PHP options<br>- It also manages the firewall rules to allow traffic on specific ports<br>- The module is crucial for the secure and efficient operation of the Nextcloud service within the project.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/docker.nix'>docker.nix</a></b></td>
						<td>- Docker.nix activates the Docker service within the project's architecture<br>- By leveraging the Nix package manager's capabilities, it provides an option to enable Docker<br>- Once this option is activated, the virtualisation of Docker is enabled, enhancing the project's containerization capabilities.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/gitlab.nix'>gitlab.nix</a></b></td>
						<td>- The 'gitlab.nix' module in the project configures and enables GitLab, a web-based DevOps lifecycle tool<br>- It sets up secure storage for sensitive data, configures GitLab with SMTP for email notifications, and establishes a secure connection with Nginx<br>- It also manages the automatic generation of necessary secrets if they do not exist.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/gnome.nix'>gnome.nix</a></b></td>
						<td>- The 'gnome.nix' module in the services directory provides an option to enable the GNOME desktop environment<br>- When activated, it ensures the X server and GNOME desktop manager services are enabled, integrating them into the overall system configuration<br>- This contributes to the project's flexibility, allowing users to customize their graphical interface.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/gotify.nix'>gotify.nix</a></b></td>
						<td>- Gotify.nix activates the Gotify service and sets up its environment within the project<br>- It enables the Gotify service, assigns port 8080 for its operation, and permits traffic through the firewall on this port<br>- This configuration ensures seamless communication for the Gotify service within the project's architecture.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/grafana.nix'>grafana.nix</a></b></td>
						<td>- The 'grafana.nix' module in the services directory enables Grafana, a platform for analytics and monitoring<br>- It configures the server's address and port, and adjusts the firewall to allow TCP traffic on the specified port<br>- This contributes to the overall project by facilitating data visualization.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/pipewire.nix'>pipewire.nix</a></b></td>
						<td>- The 'pipewire.nix' module in the services directory enables the use of Pipewire, a server for handling audio and video streams on Linux<br>- It activates Pipewire, ALSA, and Pulse services, while disabling Pulseaudio, to manage multimedia content effectively across the entire codebase.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/xserver-xkb.nix'>xserver-xkb.nix</a></b></td>
						<td>- The 'xserver-xkb.nix' module in the services directory enables or disables the XKB (X Keyboard Extension) within the X server configuration<br>- When enabled, it sets the keyboard layout to French<br>- This module plays a crucial role in managing keyboard layouts for different languages in the project's user interface.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/adguardhome.nix'>adguardhome.nix</a></b></td>
						<td>- The AdGuard Home module in the codebase enables a network-wide software for blocking ads & tracking<br>- It configures HTTP and DNS settings, enables protection and filtering, and sets up specific filters for blocking malicious websites<br>- The module also provides options for parental control and safe search enforcement.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/prometheus.nix'>prometheus.nix</a></b></td>
						<td>- The 'prometheus.nix' module in the services directory enables and configures the Prometheus monitoring system<br>- It sets the global scrape interval and defines the scrape configurations for the node job<br>- Additionally, it allows TCP traffic on ports 9090 and 9100 through the firewall.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/caddy.nix'>caddy.nix</a></b></td>
						<td>- The 'caddy.nix' module in the codebase configures the Caddy web server with enhanced security headers and specific virtual hosts<br>- It also manages encrypted secrets, sets up reverse proxy settings for different services, and configures TLS with Cloudflare DNS<br>- The module further allows firewall rules for specific TCP ports.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/immich.nix'>immich.nix</a></b></td>
						<td>- The immich.nix module in the services directory enables the immich service within the project's architecture<br>- It sets the service's status, port, host, and firewall settings<br>- This configuration is activated when the immich service is enabled, contributing to the overall functionality of the system.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/k3s.nix'>k3s.nix</a></b></td>
						<td>- The k3s.nix module in the services directory configures the networking firewall and k3s service within the project<br>- It primarily sets up TCP and UDP ports for the k3s API server and optionally for etcd clients, etcd peers, and flannel inter-node networking<br>- The module also enables the k3s service and assigns it a server role.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/printing.nix'>printing.nix</a></b></td>
						<td>- The 'printing.nix' module in the services directory activates the printing functionality when enabled<br>- It specifically initiates the printing services and loads the necessary drivers, such as 'hplip', to ensure successful operation<br>- This module plays a crucial role in the overall codebase architecture by managing the printing services.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/tailscale-client.nix'>tailscale-client.nix</a></b></td>
						<td>- The Tailscale-client module in the services directory enables the Tailscale client when activated<br>- It configures the service to open the firewall, use client routing features, and authenticate using a specific key file<br>- This module plays a crucial role in managing network connectivity and security within the larger codebase architecture.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/nginx.nix'>nginx.nix</a></b></td>
						<td>- Enabling the Nginx service and configuring a virtual host for "myhost.org" is the primary function of the nginx.nix module<br>- It also sets up SSL and ACME for secure connections, designates a root directory for the host, and accepts ACME terms while providing a default email for ACME notifications.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/gitea.nix'>gitea.nix</a></b></td>
						<td>- The 'gitea.nix' module in the codebase activates the Gitea service, a self-hosted Git service, when enabled<br>- It configures the service to run under a specific user and group, sets up the database, and defines the server settings<br>- Additionally, it opens TCP port 3000 in the firewall for network communication.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/paperless.nix'>paperless.nix</a></b></td>
						<td>- The module 'paperless.nix' activates the paperless service within the project's architecture<br>- Upon enabling, it sets up the service to run on a specified IP address and port<br>- This functionality contributes to the overall project by providing a paperless solution, enhancing the system's efficiency and sustainability.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/minecraft-server.nix'>minecraft-server.nix</a></b></td>
						<td>- The 'minecraft-server.nix' module in the project activates a Minecraft server with specific configurations<br>- It sets game parameters such as game mode, server message, maximum players, and remote control access<br>- Additionally, it allows the use of non-free packages from the Nix package collection.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/tailscale-server.nix'>tailscale-server.nix</a></b></td>
						<td>- The 'tailscale-server.nix' module in the services directory enables the Tailscale server when activated<br>- It configures the server to open the firewall, use server routing features, and includes extra flags for SSH<br>- This module is integral to the network security and remote access functionality of the entire codebase.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/calibre-web.nix'>calibre-web.nix</a></b></td>
						<td>- The 'calibre-web.nix' module in the services directory activates the Calibre-Web service, opens the firewall, and enables book uploading and conversion features<br>- This plays a crucial role in the overall codebase architecture by providing user-friendly interaction with the Calibre e-book library.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/gdm.nix'>gdm.nix</a></b></td>
						<td>- The 'gdm.nix' module in the services directory enables the GNOME Display Manager (GDM) within the project<br>- When activated, it also ensures the X server, a crucial component for graphical interfaces, is enabled<br>- This functionality contributes to the overall architecture by managing user sessions and providing a graphical user interface.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/services/openssh.nix'>openssh.nix</a></b></td>
						<td>- The 'openssh.nix' module in the services directory activates the OpenSSH service within the project<br>- It enhances security by disabling password and keyboard-interactive authentication, and prohibiting root login<br>- This configuration is only applied if the OpenSSH service is enabled, contributing to the overall secure architecture of the codebase.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>nixpkgs</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/nixpkgs/config.nix'>config.nix</a></b></td>
						<td>- The 'config.nix' module within the 'nixpkgs' directory enables the 'allowUnfree' option<br>- This functionality permits the use of non-free packages within the project, enhancing its flexibility and adaptability to various software dependencies<br>- It plays a crucial role in the project's configuration management.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>networking</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/networking/firewall.nix'>firewall.nix</a></b></td>
						<td>- The 'firewall.nix' module in the networking directory provides an option to enable or disable the firewall in the system configuration<br>- It plays a crucial role in managing network security by controlling the incoming and outgoing network traffic based on predetermined security rules.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/networking/networkmanager.nix'>networkmanager.nix</a></b></td>
						<td>- NetworkManager.nix serves as a configuration module within the project, enabling the NetworkManager functionality<br>- It provides an option to activate NetworkManager, which, when enabled, sets the corresponding network configuration<br>- This contributes to the overall network management within the codebase architecture.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>console</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/console/keyMap.nix'>keyMap.nix</a></b></td>
						<td>- KeyMap.nix within the console module enables the configuration of the keyboard layout<br>- When activated, it sets the console's keyMap to French ("fr")<br>- This feature enhances user experience by allowing customization of input methods according to user preferences.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>nix</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/nix/settings.nix'>settings.nix</a></b></td>
						<td>- The 'settings.nix' module within the 'nix' directory enables experimental features in the project's configuration<br>- Specifically, it activates the 'nix-command' and 'flakes' features when the 'experimental-features' option is turned on<br>- This contributes to the overall flexibility and extensibility of the codebase architecture.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/nix/gc.nix'>gc.nix</a></b></td>
						<td>- The gc.nix module in the Nix directory enables and configures the garbage collector (gc) for the Nix package manager<br>- It sets the gc to run automatically on a weekly basis, persistently, and deletes packages older than 14 days<br>- This contributes to efficient system resource management within the overall codebase.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>zramSwap</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/zramSwap/zramswap.nix'>zramswap.nix</a></b></td>
						<td>- The zramswap.nix module within the codebase architecture enables the use of zram, a compressed block device in RAM that can be used as swap space<br>- This feature is activated based on the configuration settings, enhancing system performance by reducing disk I/O.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>time</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/time/timeZone.nix'>timeZone.nix</a></b></td>
						<td>- The timeZone.nix module within the time directory enables the configuration of the system's time zone<br>- When activated, it sets the system's time zone to Europe/Paris<br>- This functionality contributes to the overall system settings configuration within the broader codebase architecture.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>i18n</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/i18n/i18n.nix'>i18n.nix</a></b></td>
						<td>- The i18n.nix module in the i18n directory enables internationalization support for the application<br>- When activated, it sets the default locale to English (US) and provides additional locale settings for French<br>- This feature enhances the application's accessibility and usability for users in different geographical locations.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>boot</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/boot/kernel.nix'>kernel.nix</a></b></td>
						<td>- The 'kernel.nix' module within the 'boot' directory enables the use of the latest Linux packages in the project<br>- It provides an option to activate these packages, and if enabled, sets the boot kernel packages to the most recent Linux packages<br>- This contributes to keeping the project updated with the latest Linux kernel developments.</td>
					</tr>
					</table>
					<details>
						<summary><b>loader</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/boot/loader/grub.nix'>grub.nix</a></b></td>
								<td>- The 'grub.nix' module in the 'boot/loader' directory enables the GRUB bootloader when the corresponding option is activated<br>- It also specifies the device to which the bootloader should be installed, in this case, '/dev/sda'<br>- This contributes to the overall system boot process within the project's architecture.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/boot/loader/systemd-boot.nix'>systemd-boot.nix</a></b></td>
								<td>- The 'systemd-boot.nix' module in the boot loader directory enables the systemd-boot option within the project's configuration<br>- It also allows interaction with EFI variables and sets a limit for systemd-boot configurations<br>- This module plays a crucial role in managing the boot process of the system.</td>
							</tr>
							</table>
						</blockquote>
					</details>
				</blockquote>
			</details>
			<details>
				<summary><b>system</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/system/autoUpgrade.nix'>autoUpgrade.nix</a></b></td>
						<td>- The 'autoUpgrade.nix' module in the system directory enables automatic system upgrades<br>- It sets the upgrade frequency to daily and ensures persistence of the upgrade process<br>- It also updates the 'nixpkgs' input and uses the output path of the current flake for the upgrade.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>security</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/security/rtkit.nix'>rtkit.nix</a></b></td>
						<td>- The 'rtkit.nix' module in the 'security' directory enables the use of 'rtkit', a real-time scheduling policy management daemon<br>- When activated, it sets the 'rtkit' option to true within the project's configuration, enhancing the system's security capabilities.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>templates</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/templates/proxmox-lxc.nix'>proxmox-lxc.nix</a></b></td>
						<td>- The Proxmox-LXC module configures a Proxmox Linux Container, setting it as a boot container and suppressing certain system units<br>- It also adjusts Nix settings, manages network privileges, and modifies security settings<br>- Additionally, it installs system packages, enables auto-upgrades, SSH, experimental features, and the Zsh shell.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/templates/server.nix'>server.nix</a></b></td>
						<td>- The 'server.nix' module in the project architecture integrates various services and settings, such as zramSwap, Tailscale, keyMap, i18n, NetworkManager, Nix settings, Nixpkgs config, timezone, OpenSSH, Docker, and GRUB<br>- It serves as a central configuration point, ensuring seamless interaction and functionality across different parts of the system.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>hardware</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/hardware/bluetooth.nix'>bluetooth.nix</a></b></td>
						<td>- The 'bluetooth.nix' module in the hardware directory manages Bluetooth functionality<br>- It provides an option to enable Bluetooth and configure its settings, such as discoverability and timeout<br>- This module plays a crucial role in the overall hardware management of the system.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/hardware/nvidia.nix'>nvidia.nix</a></b></td>
						<td>- The 'nvidia.nix' module in the project enables the configuration of Nvidia hardware settings<br>- It provides options for enabling OpenGL, loading Nvidia drivers, managing power settings, and selecting the appropriate driver version<br>- It also allows for the activation of the Nvidia settings menu and the use of the Nvidia open-source kernel module, albeit with limited support.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>programs</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/direnv.nix'>direnv.nix</a></b></td>
						<td>- The 'direnv.nix' module in the 'programs' directory activates the 'direnv' feature within the project<br>- It provides an option to enable 'direnv', a tool that loads and unloads environment variables depending on the current directory, enhancing the project's configurability and flexibility.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/firefox.nix'>firefox.nix</a></b></td>
						<td>- The 'firefox.nix' module in the 'programs' directory enables the Firefox browser within the software configuration<br>- It provides an option to activate Firefox, which, when enabled, triggers the activation of the Firefox program in the overall system configuration.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/python3Minimal.nix'>python3Minimal.nix</a></b></td>
						<td>- The 'python3Minimal.nix' module in the project structure enables the minimal version of Python 3<br>- When activated, it adds Python3Minimal to the system packages, enhancing the project's efficiency by utilizing a lightweight Python version<br>- This module contributes to the overall codebase architecture by providing a streamlined Python environment.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/terraform.nix'>terraform.nix</a></b></td>
						<td>- The 'terraform.nix' module in the project structure primarily enables the use of Terraform, a popular Infrastructure as Code (IaC) tool<br>- Upon activation, it adds Terraform to the system's environment packages, thereby integrating it into the overall codebase architecture<br>- This facilitates infrastructure management and provisioning within the project.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/zsh.nix'>zsh.nix</a></b></td>
						<td>- The 'zsh.nix' module in the project structure activates the Zsh shell and its features when enabled<br>- It initiates autosuggestions, syntax highlighting, and completion<br>- Additionally, it configures the 'Oh My Zsh' framework with the 'agnoster' theme and plugins for 'git', 'kubectl', and 'docker', enhancing the shell's functionality and user experience.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/ansible.nix'>ansible.nix</a></b></td>
						<td>- The 'ansible.nix' module in the project structure primarily enables the Ansible software package<br>- When activated, it adds Ansible to the system's environment packages, facilitating infrastructure management and application deployment automation within the entire codebase architecture.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/programs/steam.nix'>steam.nix</a></b></td>
						<td>- The 'steam.nix' module in the project structure enables the Steam gaming platform<br>- When activated, it opens the firewall for Steam's remote play, dedicated server, and local network game transfers, enhancing the gaming experience by ensuring seamless network connections<br>- This module is integral to the project's overall functionality, particularly for users leveraging the Steam platform.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>virtualisation</b></summary>
				<blockquote>
					<details>
						<summary><b>oci-containers</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/linkwarden.nix'>linkwarden.nix</a></b></td>
								<td>- The 'linkwarden.nix' module in the 'oci-containers' directory manages the deployment and configuration of Docker containers for the Linkwarden application and its PostgreSQL database<br>- It also handles the creation and removal of Docker networks, ensuring seamless inter-container communication<br>- Additionally, it oversees the automatic start-up and shutdown of these resources, contributing to the overall robustness of the system.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/uptime-kuma.nix'>uptime-kuma.nix</a></b></td>
								<td>- The 'uptime-kuma.nix' module in the 'oci-containers' directory configures a Docker container for the Uptime Kuma application<br>- It specifies the image to use, maps the necessary ports, and sets up the required volumes<br>- Additionally, it adjusts the firewall settings to allow traffic on the specified TCP port.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/beszel-agent.nix'>beszel-agent.nix</a></b></td>
								<td>- The beszel-agent.nix module enables Docker virtualisation and configures the "beszel-agent" container with specific environment variables, volumes, and network settings<br>- It also sets up a systemd service for the container with restart policies and dependencies<br>- Additionally, it opens TCP port 45876 in the firewall for network communication.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/nextcloud.nix'>nextcloud.nix</a></b></td>
								<td>- The code in 'nextcloud.nix' primarily manages the deployment and configuration of two Docker containers, 'mariadb' and 'nextcloud', within a custom network<br>- It ensures the containers' runtime environment, sets their dependencies, and handles their restart policies<br>- Additionally, it creates a root service that controls the lifecycle of all resources, providing an automated setup and teardown process.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/mullvad-browser.nix'>mullvad-browser.nix</a></b></td>
								<td>- The module at 'modules/virtualisation/oci-containers/mullvad-browser.nix' configures a Docker container for the Mullvad browser<br>- It sets environment variables, specifies volumes for configuration and data, and opens ports 3000 and 3001<br>- Additionally, it adjusts the firewall to allow TCP traffic on these ports.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/calibre.nix'>calibre.nix</a></b></td>
								<td>- The 'calibre.nix' module in the 'oci-containers' directory configures and manages the Calibre container in a Docker environment<br>- It sets up the runtime, defines container properties, manages service restarts, creates Docker networks, and controls the root service<br>- This ensures smooth operation and maintenance of the Calibre container within the project's architecture.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/adguardhome.nix'>adguardhome.nix</a></b></td>
								<td>- The code in 'adguardhome.nix' configures and manages the AdGuard Home container within the Docker environment<br>- It sets up the necessary Docker network, defines the container's image, volumes, ports, and extra options, and ensures the container's service restarts upon failure<br>- It also establishes a root service to manage all resources and containers.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/beszel.nix'>beszel.nix</a></b></td>
								<td>- The 'beszel.nix' module in the 'oci-containers' directory configures and manages the Docker-based virtualisation environment for the 'beszel' container<br>- It ensures the Docker service is enabled, sets up the container's image, volumes, ports, and logging, and defines the restart policy<br>- It also manages the Docker network for the 'beszel' container and orchestrates the overall lifecycle of the container resources.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/homeassistant.nix'>homeassistant.nix</a></b></td>
								<td>- The 'homeassistant.nix' module in the 'oci-containers' directory configures and manages a Docker-based Home Assistant container<br>- It sets up the runtime environment, defines the container's properties, and establishes the necessary systemd services and networks<br>- The module ensures the container's continuous operation and handles resource allocation and teardown.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/virtualisation/oci-containers/myspeed.nix'>myspeed.nix</a></b></td>
								<td>- The code in the file 'myspeed.nix' primarily configures and manages a Docker container named 'MySpeed'<br>- It sets up the runtime environment, defines the container's properties, and establishes the necessary network services<br>- Additionally, it ensures the container's continuous operation and handles the creation and teardown of all resources when the root service starts or stops.</td>
							</tr>
							</table>
						</blockquote>
					</details>
				</blockquote>
			</details>
			<details>
				<summary><b>environment</b></summary>
				<blockquote>
					<details>
						<summary><b>systemPackages</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/environment/systemPackages/gnomeExtensions.nix'>gnomeExtensions.nix</a></b></td>
								<td>- The gnomeExtensions.nix module in the environment/systemPackages directory enables a selection of GNOME extensions within the system environment<br>- When activated, it integrates extensions such as hide-top-bar, tailscale-qs, appindicator, and others, enhancing the GNOME desktop experience.</td>
							</tr>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/environment/systemPackages/ethtool.nix'>ethtool.nix</a></b></td>
								<td>- The module 'ethtool.nix' in the 'systemPackages' directory enables the inclusion of 'ethtool' in the system packages when activated<br>- This is part of the larger codebase architecture that allows for modular and conditional inclusion of various system packages based on user configuration.</td>
							</tr>
							</table>
						</blockquote>
					</details>
					<details>
						<summary><b>gnome</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/modules/environment/gnome/excludePackages.nix'>excludePackages.nix</a></b></td>
								<td>- The 'excludePackages.nix' within the 'gnome' module of the environment directory enables the exclusion of specific GNOME packages from the environment<br>- When activated, it prevents the installation of certain GNOME applications like gnome-tour, epiphany, geary, and others, providing a more customized GNOME experience.</td>
							</tr>
							</table>
						</blockquote>
					</details>
				</blockquote>
			</details>
		</blockquote>
	</details>
	<details> <!-- lib Submodule -->
		<summary><b>lib</b></summary>
		<blockquote>
			<table>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/lib/mkSystems.nix'>mkSystems.nix</a></b></td>
				<td>- The mkSystems.nix file in the lib directory defines two functions, mkDesktopSystem and mkServerSystem, which generate configurations for desktop and server systems respectively<br>- These functions incorporate various modules and configurations, including hardware, user settings, home-manager, nix-flatpak, and sops-nix, to create a comprehensive system setup.</td>
			</tr>
			</table>
		</blockquote>
	</details>
	<details> <!-- secrets Submodule -->
		<summary><b>secrets</b></summary>
		<blockquote>
			<table>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/secrets/secrets.yaml'>secrets.yaml</a></b></td>
				<td>- The 'secrets.yaml' file serves as a secure storage for sensitive data, such as the Cloudflare API token, within the project<br>- It employs encryption methods like AES256_GCM and AGE for data protection<br>- The file also includes metadata about the encryption methods used, the last modification date, and the SOPS version.</td>
			</tr>
			<tr>
				<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/secrets/cf_api_token.env.enc'>cf_api_token.env.enc</a></b></td>
				<td>- The 'secrets/cf_api_token.env.enc' file securely stores the Cloudflare API token and other sensitive data<br>- It uses encryption methods like AES256_GCM and AGE for data protection<br>- The file is crucial for authenticating and authorizing interactions with the Cloudflare API within the project's codebase.</td>
			</tr>
			</table>
		</blockquote>
	</details>
	<details> <!-- home-manager Submodule -->
		<summary><b>home-manager</b></summary>
		<blockquote>
			<details>
				<summary><b>tom</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/home.nix'>home.nix</a></b></td>
						<td>- Home.nix serves as a central configuration file for the user "Tom" in the home-manager project<br>- It imports various settings from other modules, including package defaults, Git, and GNOME desktop manager configurations<br>- It also sets the home directory and enables the home-manager program, contributing to the overall system setup and user environment customization.</td>
					</tr>
					</table>
					<details>
						<summary><b>packages</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/packages/default.nix'>default.nix</a></b></td>
								<td>- The 'default.nix' within the 'packages' directory of the 'home-manager/tom' path specifies the software packages to be installed in the user's home environment<br>- It includes a variety of applications, ranging from productivity tools like 'vscode' and 'libreoffice', to utilities such as 'fastfetch' and 'dconf-editor', and entertainment apps like 'showtime' and 'youtube-music'.</td>
							</tr>
							</table>
						</blockquote>
					</details>
					<details>
						<summary><b>programs</b></summary>
						<blockquote>
							<table>
							<tr>
								<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/programs/git.nix'>git.nix</a></b></td>
								<td>- The 'git.nix' file, located in the 'home-manager/tom/programs' directory, configures the Git program for the user 'waddenn'<br>- It enables Git, sets the user's name and email, and establishes 'main' as the default branch for new repositories<br>- This configuration enhances user experience and streamlines Git operations.</td>
							</tr>
							</table>
						</blockquote>
					</details>
					<details>
						<summary><b>desktopManager</b></summary>
						<blockquote>
							<details>
								<summary><b>gnome</b></summary>
								<blockquote>
									<table>
									<tr>
										<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/desktopManager/gnome/favorite-apps.nix'>favorite-apps.nix</a></b></td>
										<td>- The favorite-apps.nix within the gnome directory under the desktopManager module sets the preferred applications for the GNOME shell<br>- It configures the dconf settings to include applications like Brave Browser, GNOME Console, Vencord Vesktop, Remmina, and YouTube Music as favorites.</td>
									</tr>
									<tr>
										<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/desktopManager/gnome/background.nix'>background.nix</a></b></td>
										<td>- The 'background.nix' within the 'gnome' directory under 'desktopManager' in the 'home-manager' path sets the default and dark mode wallpapers for the GNOME desktop environment<br>- It achieves this by defining the 'picture-uri' and 'picture-uri-dark' settings in the 'org/gnome/desktop/background' dconf settings.</td>
									</tr>
									<tr>
										<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/desktopManager/gnome/interface.nix'>interface.nix</a></b></td>
										<td>- The gnome/interface.nix within the desktopManager directory configures the GNOME desktop environment settings<br>- It customizes the interface by setting the color scheme, enabling the weekday display on the clock, disabling hot corners, and setting the accent color<br>- Additionally, it sets the system locale to French.</td>
									</tr>
									<tr>
										<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/desktopManager/gnome/keybindings.nix'>keybindings.nix</a></b></td>
										<td>- The keybindings.nix file in the gnome desktop manager directory configures keyboard shortcuts for various actions in the GNOME desktop environment<br>- It customizes window management, workspace navigation, and media control keybindings, as well as defines custom shortcuts for opening a terminal and accessing resources.</td>
									</tr>
									<tr>
										<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/home-manager/tom/desktopManager/gnome/extensions.nix'>extensions.nix</a></b></td>
										<td>- The 'extensions.nix' file within the 'gnome' directory manages GNOME shell extensions and their settings<br>- It enables specific extensions, such as 'hidetopbar' and 'system-monitor', and configures their behavior<br>- This contributes to the overall user interface and functionality customization of the GNOME desktop environment in the project.</td>
									</tr>
									</table>
								</blockquote>
							</details>
						</blockquote>
					</details>
				</blockquote>
			</details>
		</blockquote>
	</details>
	<details> <!-- users Submodule -->
		<summary><b>users</b></summary>
		<blockquote>
			<details>
				<summary><b>nixos</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/users/nixos/default.nix'>default.nix</a></b></td>
						<td>- The 'default.nix' in the 'users/nixos' directory configures a standard user named 'nixos' with specific group permissions and authorized SSH keys<br>- It also sets the default user shell to 'zsh'<br>- This contributes to the overall system configuration and user management in the NixOS environment.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>tom</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/users/tom/default.nix'>default.nix</a></b></td>
						<td>- The 'default.nix' under 'users/tom' sets up a new user named 'Tom' with standard user privileges and specific group memberships<br>- It also establishes 'zsh' as the default shell for the user<br>- This contributes to the overall system configuration and user management in the codebase.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>docker</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/users/docker/default.nix'>default.nix</a></b></td>
						<td>- The 'default.nix' within the 'users/docker' directory establishes a standard user named 'docker' and assigns it to the 'docker' group<br>- This configuration is integral to the project's architecture, ensuring appropriate user permissions for Docker-related operations.</td>
					</tr>
					</table>
				</blockquote>
			</details>
		</blockquote>
	</details>
	<details> <!-- hosts Submodule -->
		<summary><b>hosts</b></summary>
		<blockquote>
			<details>
				<summary><b>asus-nixos</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/asus-nixos/hardware-configuration.nix'>hardware-configuration.nix</a></b></td>
						<td>- The 'hardware-configuration.nix' file in the 'asus-nixos' host directory is auto-generated by 'nixos-generate-config'<br>- It primarily manages the system's hardware configuration, including kernel modules, file systems, and networking settings<br>- It also specifies the host platform and updates the AMD CPU microcode<br>- Changes should be made in '/etc/nixos/configuration.nix' to avoid overwriting.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/asus-nixos/configuration.nix'>configuration.nix</a></b></td>
						<td>- The configuration.nix file in the hosts/asus-nixos directory manages system settings for a specific host<br>- It imports global configurations, sets system packages, enables services, and configures hardware and boot parameters<br>- It also controls the availability of various features and applications, ensuring the system is tailored to the user's needs.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>lenovo-nixos</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/lenovo-nixos/hardware-configuration.nix'>hardware-configuration.nix</a></b></td>
						<td>- The hardware-configuration.nix in the hosts/lenovo-nixos directory is a configuration file generated by 'nixos-generate-config'<br>- It primarily manages the boot process, file systems, and network settings for a Lenovo NixOS host<br>- It also specifies the host platform and updates the Intel CPU microcode if redistributable firmware is enabled.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/lenovo-nixos/configuration.nix'>configuration.nix</a></b></td>
						<td>- The 'configuration.nix' file in the 'lenovo-nixos' host directory configures a variety of services and features for a Lenovo NixOS system<br>- It enables functionalities such as Nvidia graphics, firewall, auto-upgrade, Firefox, Bluetooth, and more<br>- It also imports global settings from the 'global.nix' file in the 'modules' directory, ensuring a consistent configuration across the codebase.</td>
					</tr>
					</table>
				</blockquote>
			</details>
			<details>
				<summary><b>proxmox-vm</b></summary>
				<blockquote>
					<table>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/proxmox-vm/hardware-configuration.nix'>hardware-configuration.nix</a></b></td>
						<td>- The hardware-configuration.nix file in the proxmox-vm host primarily manages the hardware settings for a NixOS system<br>- It specifies the necessary kernel modules, file systems, and network configurations<br>- It also sets the host platform to x86_64-linux and enables DHCP for network interfaces<br>- Changes should be made in the /etc/nixos/configuration.nix file as this file is auto-generated.</td>
					</tr>
					<tr>
						<td><b><a href='https://github.com/Waddenn/nixos-config/blob/master/hosts/proxmox-vm/configuration.nix'>configuration.nix</a></b></td>
						<td>- The configuration.nix file in the Proxmox VM host primarily manages the import of various modules, including zramSwap, Tailscale server, keyMap, i18n, NetworkManager, Nix settings, Nix packages, timezone, OpenSSH, Docker, GRUB, and Zsh<br>- It also ensures the inclusion of the git package in the system environment.</td>
					</tr>
					</table>
				</blockquote>
			</details>
		</blockquote>
	</details>
</details>

---
## 🚀 Getting Started

### ☑️ Prerequisites

Before getting started with nixos-config, ensure your runtime environment meets the following requirements:

- **Programming Language:** Error detecting primary_language: {'lock': 1, 'nix': 86, 'sh': 2, 'yaml': 1, 'enc': 1}


### ⚙️ Installation

Install nixos-config using one of the following methods:

**Build from source:**

1. Clone the nixos-config repository:
```sh
❯ git clone https://github.com/Waddenn/nixos-config
```

2. Navigate to the project directory:
```sh
❯ cd nixos-config
```

3. Install the project dependencies:

echo 'INSERT-INSTALL-COMMAND-HERE'



### 🤖 Usage
Run nixos-config using the following command:
echo 'INSERT-RUN-COMMAND-HERE'

### 🧪 Testing
Run the test suite using the following command:
echo 'INSERT-TEST-COMMAND-HERE'

---
## 📌 Project Roadmap

- [X] **`Task 1`**: <strike>Implement feature one.</strike>
- [ ] **`Task 2`**: Implement feature two.
- [ ] **`Task 3`**: Implement feature three.

---

## 🔰 Contributing

- **💬 [Join the Discussions](https://github.com/Waddenn/nixos-config/discussions)**: Share your insights, provide feedback, or ask questions.
- **🐛 [Report Issues](https://github.com/Waddenn/nixos-config/issues)**: Submit bugs found or log feature requests for the `nixos-config` project.
- **💡 [Submit Pull Requests](https://github.com/Waddenn/nixos-config/blob/main/CONTRIBUTING.md)**: Review open PRs, and submit your own PRs.

<details closed>
<summary>Contributing Guidelines</summary>

1. **Fork the Repository**: Start by forking the project repository to your github account.
2. **Clone Locally**: Clone the forked repository to your local machine using a git client.
   ```sh
   git clone https://github.com/Waddenn/nixos-config
   ```
3. **Create a New Branch**: Always work on a new branch, giving it a descriptive name.
   ```sh
   git checkout -b new-feature-x
   ```
4. **Make Your Changes**: Develop and test your changes locally.
5. **Commit Your Changes**: Commit with a clear message describing your updates.
   ```sh
   git commit -m 'Implemented new feature x.'
   ```
6. **Push to github**: Push the changes to your forked repository.
   ```sh
   git push origin new-feature-x
   ```
7. **Submit a Pull Request**: Create a PR against the original project repository. Clearly describe the changes and their motivations.
8. **Review**: Once your PR is reviewed and approved, it will be merged into the main branch. Congratulations on your contribution!
</details>

<details closed>
<summary>Contributor Graph</summary>
<br>
<p align="left">
   <a href="https://github.com{/Waddenn/nixos-config/}graphs/contributors">
      <img src="https://contrib.rocks/image?repo=Waddenn/nixos-config">
   </a>
</p>
</details>

---

## 🎗 License

This project is protected under the [SELECT-A-LICENSE](https://choosealicense.com/licenses) License. For more details, refer to the [LICENSE](https://choosealicense.com/licenses/) file.

---

## 🙌 Acknowledgments

- List any resources, contributors, inspiration, etc. here.

---
