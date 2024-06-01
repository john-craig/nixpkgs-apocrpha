# Selfhosted
The `services.selfhosted.<service_name>.enable`

This is useful for prototyping changes:
```
nix-build '<nixpkgs/nixos>' -I nixpkgs=/home/galahad/programming_alt/by_language/nix/nixpkgs-internal -A vm -k -I nixos-config=./default.nix --show-trace --dry-run
```