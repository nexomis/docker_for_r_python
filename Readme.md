#

## Connexion SSH

```
ssh -o ProxyCommand="ssh -W %h:%p -q admin@{{bastion_ip}}" admin@{{host_ip}}
```