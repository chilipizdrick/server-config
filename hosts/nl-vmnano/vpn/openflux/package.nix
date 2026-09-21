{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "openflux";
  version = "0.17.1";

  src = fetchFromGitHub {
    owner = "p1neappleXpress";
    repo = "OpenFlux";
    rev = "v${version}";
    hash = "sha256-epkh1UaMq84vkKfefIc+wx1u33wtqPZ0pQtaIa/nTg8=";
  };

  proxyVendor = true;
  vendorHash = "sha256-ugDuwsWPkAkfzDPV+xAw+9GiQWj05ZY3WJDdAniJ6EU=";

  ldflags = [
    "-s"
    "-w"
  ];

  subPackages = ["."];

  postInstall = ''
    # Provide both OpenFlux and lowercase openflux binaries
    ln -s $out/bin/OpenFlux $out/bin/openflux
  '';

  meta = with lib; {
    description = "Network stack research tool - IPv4 TCP/UDP tunnel with pluggable transports";
    homepage = "https://github.com/p1neappleXpress/OpenFlux";
    license = licenses.gpl3Plus;
    mainProgram = "openflux";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
