{...}: {
  virtualisation.oci-containers.containers."bob" = {
    image = "docker.io/chilipizdrick/bob";
    login = {
      registry = "docker.io";
      username = "chilipizdrick";
      passwordFile = "/etc/bob/docker_hub_password.txt";
    };
    environmentFiles = [
      /etc/bob/.env
    ];
    volumes = [
      "/etc/bob/db:/app/db"
    ];
    extraOptions = [
      "--pull=newer"
    ];
  };

  system.activationScripts.create-bob-volumes = ''
    mkdir -p /etc/bob/db
    touch /etc/bob/db/db.sqlite3
  '';
}
