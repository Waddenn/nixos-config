nixos-config/
├── README.md                # Description générale du projet et instructions d'utilisation
├── flake.nix                # Fichier Flake principal
├── flake.lock               # Fichier de verrouillage des versions
├── LICENSE                  # Licence du projet
├── hosts/                   # Configurations spécifiques aux machines
│   ├── README.md            # Explication du répertoire
│   ├── asus-nixos/          # Configuration pour la machine "asus-nixos"
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── gnome.nix        # Configuration spécifique pour GNOME
│   │   └── home.nix         # Configuration Home Manager pour cet hôte
│   └── another-host/        # Exemple d'une autre machine
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── gnome.nix
│       └── home.nix
├── modules/                 # Modules réutilisables
│   ├── README.md            # Explication du répertoire
│   ├── desktop/             # Modules spécifiques aux environnements de bureau
│   │   ├── gnome/           # Configuration pour GNOME
│   │   │   ├── base.nix     # Configuration de base pour GNOME
│   │   │   ├── extensions.nix # Gestion des extensions GNOME
│   │   │   └── theming.nix  # Thèmes et personnalisation GNOME
│   │   └── kde/             # (Optionnel) Pour KDE si nécessaire
│   ├── common/              # Modules génériques
│   │   ├── base.nix         # Configurations de base communes
│   │   ├── networking.nix   # Configuration réseau
│   │   └── users.nix        # Gestion des utilisateurs
│   ├── services/            # Configuration des services spécifiques
│   │   ├── nginx.nix
│   │   ├── docker.nix
│   │   └── ssh.nix
│   └── hardware/            # Configuration matérielle réutilisable
│       ├── amd.nix
│       └── intel.nix
├── overlays/                # Overlays pour personnaliser les paquets Nix
│   ├── README.md            # Explication du répertoire
│   ├── custom-overlay.nix   # Exemple d'overlay personnalisé
│   └── another-overlay.nix
├── home-manager/            # Configurations Home Manager pour tous les utilisateurs
│   ├── README.md            # Explication du répertoire
│   ├── shared/              # Configurations communes entre les utilisateurs
│   │   ├── applications.nix # Applications communes
│   │   ├── shell.nix        # Configuration du shell (bash, zsh, etc.)
│   │   └── aliases.nix      # Aliases communs
│   └── users/               # Configurations spécifiques par utilisateur
│       ├── user1.nix        # Configuration Home Manager pour "user1"
│       ├── user2.nix        # Configuration Home Manager pour "user2"
│       └── templates/       # Modèles pour de nouveaux utilisateurs
│           └── example.nix
├── nixos-docs/              # Documentation spécifique à NixOS
│   ├── gnome-tips.md        # Astuces spécifiques à GNOME
│   ├── home-manager-tips.md # Conseils pour Home Manager
│   └── troubleshooting.md   # Dépannage courant
└── scripts/                 # Scripts utiles
    ├── bootstrap.sh         # Script pour configurer une machine NixOS depuis zéro
    ├── update.sh            # Script pour mettre à jour flake.lock et vérifier les dépendances
    └── deploy.sh            # Script pour déployer une configuration sur une machine
