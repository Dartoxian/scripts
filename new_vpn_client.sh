#!/bin/sh

# Based on openvpn openwrt setup described here https://openwrt.org/docs/guide-user/services/vpn/openvpn/server
#  * Configures dns to route to pihole for vpn clients.
#  * Adds vpn clients to the .lan domain

# Usage: ./new_vpn_client.sh <client_name>
# Output: a new .ovpn file which can be used to connect to the vpn.dartoxia.com vpn.

OVPN_DIR="/etc/openvpn"
OVPN_PKI="/etc/easy-rsa/pki"
OVPN_PORT="1194"
OVPN_PROTO="udp"
OVPN_DNS="192.168.1.10"
OVPN_POOL="192.168.8.0 255.255.255.0"
OVPN_DOMAIN="lan"
OVPN_SERV="vpn.dartoxia.com"

export EASYRSA_PKI="${OVPN_PKI}"
export EASYRSA_REQ_CN="ovpnca"
export EASYRSA_BATCH="1"

#easyrsa build-client-full $1 nopass

OVPN_DH="$(cat ${OVPN_PKI}/dh.pem)"
OVPN_TC="$(sed -e "/^#/d;/^\w/N;s/\n//" ${OVPN_PKI}/tc.pem)"
OVPN_CA="$(openssl x509 -in ${OVPN_PKI}/ca.crt)"
NL=$'\n'

umask go=
ls ${OVPN_PKI}/issued \
| sed -e "s/\.\w*$//" \
| while read -r OVPN_ID
do
OVPN_KEY="$(cat ${OVPN_PKI}/private/${OVPN_ID}.key)"
OVPN_CERT="$(openssl x509 -in ${OVPN_PKI}/issued/${OVPN_ID}.crt)"
OVPN_EKU="$(openssl x509 -in ${OVPN_PKI}/issued/${OVPN_ID}.crt -purpose)"
OVPN_CONF_SERVER="\
user nobody
group nogroup
dev tun
port ${OVPN_PORT}
proto ${OVPN_PROTO}
server ${OVPN_POOL}
topology subnet
client-to-client
keepalive 10 60
persist-tun
persist-key
push \"dhcp-option DNS ${OVPN_DNS}\"
push \"dhcp-option DOMAIN ${OVPN_DOMAIN}\"
push \"redirect-gateway def1\"
push \"persist-tun\"
push \"persist-key\"
<dh>${NL}${OVPN_DH}${NL}</dh>"
OVPN_CONF_CLIENT="\
dev tun
nobind
client
remote ${OVPN_SERV} ${OVPN_PORT} ${OVPN_PROTO}
auth-nocache
remote-cert-tls server"
OVPN_CONF_COMMON="\
<tls-crypt>${NL}${OVPN_TC}${NL}</tls-crypt>
<key>${NL}${OVPN_KEY}${NL}</key>
<cert>${NL}${OVPN_CERT}${NL}</cert>
<ca>${NL}${OVPN_CA}${NL}</ca>"
case ${OVPN_EKU} in
    (*"SSL server : Yes"*) cat << EOF > ${OVPN_DIR}/${OVPN_ID}.conf ;;
${OVPN_CONF_SERVER}
${OVPN_CONF_COMMON}
EOF
    (*"SSL client : Yes"*) cat << EOF > ${OVPN_DIR}/${OVPN_ID}.ovpn ;;
${OVPN_CONF_CLIENT}
${OVPN_CONF_COMMON}
EOF
esac
done
/etc/init.d/openvpn restart
ls ${OVPN_DIR}/*.ovpn
