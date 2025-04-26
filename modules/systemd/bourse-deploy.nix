{
  config,
  lib,
  pkgs,
  ...
}: {
  options.bourse-deploy.enable = lib.mkEnableOption "Enable bourse-deploy systemd service";

  config = lib.mkIf config.bourse-deploy.enable {
    systemd.services.bourse-deploy = {
      description = "Deploy Bourse Docker App";
      after = ["docker.service" "network.target"];
      wants = ["docker.service"];

      serviceConfig = {
        Type = "oneshot";
        User = "nixos";
        WorkingDirectory = "/home/nixos";
        ExecStart = pkgs.writeShellScript "bourse-deploy" ''
          set -e

          APP_NAME="bourse-app"
          CONTAINER_NAME="bourse-container"
          REPO_URL="https://github.com/Waddenn/bourse-dashboard.git"
          APP_DIR="/home/nixos/"

          if [ ! -d "$APP_DIR" ]; then
            git clone "$REPO_URL" "$APP_DIR"
          else
            cd "$APP_DIR"
            git pull origin main
          fi

          cd "$APP_DIR"
          docker build -t "$APP_NAME" .

          if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
            docker stop "$CONTAINER_NAME" || true
            docker rm "$CONTAINER_NAME" || true
          fi

          if docker images --format '{{.Repository}}' | grep -Eq "^${APP_NAME}$"; then
            docker rmi "$APP_NAME" || true
          fi

          docker run -d \
            -p 5000:5000 \
            --name "$CONTAINER_NAME" \
            --restart unless-stopped \
            -e TZ=Europe/Paris \
            -v /etc/localtime:/etc/localtime:ro \
            "$APP_NAME"
        '';
        Restart = "no";
      };
    };
  };
}
