# 01 Simple with one HUB

In this setup we have number of clients/nodes and one HUB to which the clients/nodes connect and route traffic through.

# Iptables setup

__to-do__: masquerade and routing setup

# QR Android & iOS setup

The following commands helps you with configuring mobile clients.

At your favourite app store check for `wireguard` (!verify the vendor!).

on Mac: `brew install qrencode` [https://fukuchi.org/works/qrencode/index.html.en](https://fukuchi.org/works/qrencode/index.html.en)

```bash
alias wgqr='qrencode -t ansiutf8 -r '
# in terminal
qrencode -t ansiutf8 -r _wg-style-....conf
# as png
qrencode -t png -o client-qr.png  -r _wg-style-....conf
```
