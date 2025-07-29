# formal-overlay
Formal Nix expressions. Currently, this provides a Nix package for
the Formal Desktop app and a home-manager module to enable it as a service.

# Quickstart
## Use in NixOS flake (recommended)
If you're using a flake and home manager for your NixOS configuration, you can
add the overlay as shown below:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    formal-overlay = {
      url = "github:formalco/formal-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, formal-overlay }: {
    nixosConfigurations.yourHost = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        # Add the formal overlay.
        # Adds pkgs.formal
        {
          nixpkgs.overlays = [ formal-overlay.overlays.default ];
        }
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            # You could also add the overlay manually to home-manager.
            useGlobalPkgs = true;
            users.yourUser = {
              imports = [
                ./home-configuration.nix
                # Add the home manager module.
                formal-overlay.homeManagerModules.formal
              ];

              # This should probably go in your home configuration files.
              # Adds formal as a systemd user unit (named formal.service)
              services.formal.enable = true;
              # Adds formal CLI to your user's path.
              home.packages = [ pkgs.formal ];
            };
          };
        }
      ];
    };
  };
}
```

## With fetchTarball
If you're using a `configuration.nix` file, this approach is recommended. A
sample configuration is shown below:
```nix
{ config, pkgs, lib, ... }:

let
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz;
  formal-overlay = builtins.fetchTarball https://github.com/formalco/formal-overlay/archive/main.tar.gz;
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

  # Add the formal overlay.
  # Adds pkgs.formal
  nixpkgs.overlays = [ (import "${formal-overlay}") ];

  # You can also add the CLI to the environment packages.
  environment.systemPackages = [ pkgs.formal ];

  home-manager = {
    # You could also add the overlay manually to home-manager.
    useGlobalPkgs = true;
    users.yourUser = { pkgs, ... }: {
      imports = [
        # Add the home manager module.
        (import "${formal-overlay}/home-modules").formal
      ];

      # Adds formal as systemd user unit (named formal.service)
      services.formal.enable = true;
      # Adds formal CLI to your user's path.
      home.packages = [ pkgs.formal ];
    };
  };
}
```

# Additional setup and information
Formal Desktop includes additional components that depend on external system configuration to work properly.

## Keyring
Formal Desktop uses [zalando/go-keyring](https://github.com/zalando/go-keyring) to store login credentials,
which depends on the `org.freedesktop.secrets` D-Bus service. On GNOME and KDE, this is provided by GNOME Keyring and KWallet, respectively.

On other desktop environments, you may need to install an additional package that provides the `org.freedesktop.secrets` service to login successfully.
We recommend using GNOME keyring, which can be configured in your `configuration.nix` as follows:
```nix
{
  services.gnome.gnome-keyring.enable = true;
}
```
You may also need to create a "login" keyring. See the go-keyring repository for more information.

## System tray
Formal Desktop includes a system tray icon. GNOME does not support system tray icons by default,
and you will need to install and configure additional packages to enable this feature. From [the NixOS wiki](https://wiki.nixos.org/wiki/GNOME#Enable_system_tray_icons),
it amounts to the following in your `configuration.nix`:
```nix
{
  environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
}
```
Then, you need to enable the extension "AppIndicator and KStatusNotifierItem Support" in the Extensions app.

## Clipboard
Formal Desktop uses [golang-design/clipboard](https://github.com/golang-design/clipboard) to copy text to the clipboard.
This library currently does not support Wayland.