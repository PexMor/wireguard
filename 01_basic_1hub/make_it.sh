#!/bin/bash

# brew install wireguard-tools

BD=$HOME/.config/wg-test
[ -d "$BD" ] || mkdir -p "$BD"
umask 077

function gen_keypair() {
  local NAME=$1
  if [ -s "$BD/$NAME-priv" ]; then
    echo "Private key '$NAME'  already exists"
    return
  else
    echo "Making key for '$NAME'"
    wg genkey > "$BD/$NAME-priv"
    wg pubkey < "$BD/$NAME-priv" > "$BD/$NAME-pub"
  fi
}

function gen_psk() {
  local N0=$1
  local N1=$2
  if [ -s "$BD/$N0-$N1-psk" ]; then
    echo "Preshared key '$N0-$N1'  already exists"
    return
  else
    echo "Making preshared key for '$N0-$N1'"
    wg genpsk > "$BD/$N0-$N1-psk"
  fi
}

NODES=()

if [ -f "$BD/config.inc" ]; then
  source "$BD/config.inc"
else
  # use demo defaults
  NODES+=(node0)
  NODES+=(node1)
  for NODE in "${NODES[@]}"; do
    gen_keypair $NODE
  done
  PORT=54321
  IP_PFX="172.20.46"
  SRV=srv
  SRV_NODE=srv.example.com
fi

gen_keypair $SRV
SRV_PRIV=`cat "$BD/$SRV-priv" | tr -d "\r\n\t "`
SRV_PUB=`cat "$BD/$SRV-pub"   | tr -d "\r\n\t "`

cat >"$BD/_$SRV.conf" <<DATA
[NetDev]
Name=wg0
Kind=wireguard
Description=WireGuard tunnel wg0

[WireGuard]
ListenPort=$PORT
PrivateKey=$SRV_PRIV

DATA

# starting IP
CNT=10
#############################
# Loop over nodes
#############################
for NODE in "${NODES[@]}"; do
  gen_psk $SRV $NODE
  PEER_PRIV=`cat "$BD/$NODE-priv" | tr -d "\r\n\t "`
  PEER_PUB=`cat "$BD/$NODE-pub"   | tr -d "\r\n\t "`
  PSK_FN="$BD/$SRV-$NODE-psk"
  PSK=`cat "$PSK_FN"   | tr -d "\r\n\t "`

cat >>"$BD/_$SRV.conf" <<DATA
[WireGuardPeer]
# $NODE
PublicKey=$PEER_PUB
PresharedKey=$PSK
AllowedIPs=$IP_PFX.${CNT}/32
PersistentKeepalive=25

DATA

cat >"$BD/_systemd-style_$NODE.conf" <<DATA
[NetDev]
Name=wg0
Kind=wireguard
Description=WireGuard tunnel wg0

[WireGuard]
ListenPort=$PORT
PrivateKey=$PEER_PRIV

[WireGuardPeer]
PublicKey=$SRV_PUB
PresharedKey=$PSK
AllowedIPs=$IP_PFX.1/32
Endpoint=$SRV_NODE:$PORT
PersistentKeepalive=25
DATA

# you can add any IP mask to the AllowedIP
# to let the client router also such subnet via the wg
# i.e. 192.168.1.0/24 (separated by comma ,)
cat >"$BD/_wg-style_$NODE.conf" <<DATA
[Interface]
Address = $IP_PFX.${CNT}
ListenPort = $PORT
PrivateKey = $PEER_PRIV
DNS = $IP_PFX.1

[Peer]
PublicKey = $SRV_PUB
PresharedKey = $PSK
AllowedIPs = $IP_PFX.1/24
Endpoint = $SRV_NODE:$PORT
PersistentKeepalive = 25
DATA

cat >"$BD/_wg2-style_$NODE.conf" <<DATA
[Interface]
Address = $IP_PFX.${CNT}
ListenPort = $PORT
PrivateKey = $PEER_PRIV
DNS = $IP_PFX.1

[Peer]
PublicKey = $SRV_PUB
PresharedKey = $PSK
AllowedIPs = 0.0.0.0/0
Endpoint = $SRV_NODE:$PORT
PersistentKeepalive = 25
DATA

CNT=$[CNT+1]
done

echo "---"
echo "Check $BD for results"
echo "---"
