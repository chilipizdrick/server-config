# Notes on deployment steps

## Deploy to HOSTKEY VPS

1. Setup VPS instance without any OS, set public ssh key for simpler authorization
2. Install `tar` on server via `ssh root@<target-host> -l 'dnf install tar'`
3. Run `nixos-anywhere` installation: 

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#<host> --target-host root@<target-host>
```

### Post install steps for headscale server

To create a headscale user use

```bash
headscale users create <user>
```

To generate preauth token for user use

```bash
headscale preauthkeys create --user <user>
```

And then to login with this key in tailscale use

```bash
tailscale up --login-server <headscale_server_url> --authkey <authkey>
```

To enable exit node routes use

```bash
headscale routes enable -r <route_id>
```


