{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  gtk3,
  libayatana-appindicator,
}:

let
  inherit (stdenv.hostPlatform) system;
  version = "0.1.4";
  fetch = arch: hash: fetchurl {
    url = "https://static-assets.formalcloud.net/desktop-app/linux/formal-desktop_${version}_${arch}.deb";
    inherit hash;
  };
  sources = rec {
    aarch64-linux = fetch "arm64" "sha256-yidonBngXgYO6r1JA3i938ZBBg0JTEjVxS9jyDSSWGY=";
    x86_64-linux = fetch "amd64" "sha256-RiDafFAGewcydJguR57kzhoYahojR/oLj2AFiWxehvM=";
  };
  platforms = builtins.attrNames sources;
in
stdenv.mkDerivation rec {
  pname = "formal";
  inherit version;

  src = if (builtins.elem system platforms) then
    sources.${system}
  else
    throw "Unsupported system: ${system}";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    gtk3
    libayatana-appindicator
  ];

  installPhase = ''
    runHook preInstall
    install -D -m755 usr/bin/formal $out/bin/formal
    install -D usr/share/pixmaps/formal.png $out/share/pixmaps/formal.png
    substituteInPlace usr/share/applications/formal.desktop \
      --replace-fail /usr/bin/formal $out/bin/formal
    install -D -m644 usr/share/applications/formal.desktop $out/share/applications/formal.desktop

    runHook postInstall
  '';

  meta = {
    description = "Formal Desktop";
    homepage = "https://joinformal.com";
    mainProgram = "formal";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}