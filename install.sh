#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

VERSION="spi"
CONFIG="AU_920"
if [[ $1 != "" ]]; then CONFIG=$1; fi

echo "The Things Network Gateway installer"
echo "Modified by Cytron Technologies Sdn Bhd"
echo "Version: $VERSION"
echo "Config: $CONFIG"

# Update the gateway installer to the correct branch (defaults to master)
echo "Updating installer files..."
OLD_HEAD=$(git rev-parse HEAD)
git fetch
#git checkout -q $VERSION
git pull
NEW_HEAD=$(git rev-parse HEAD)

if [[ $OLD_HEAD != $NEW_HEAD ]]; then
    echo "New installer found. Restarting process..."
    exec "./install.sh" "$CONFIG"
fi

# Request gateway configuration data
# There are two ways to do it, manually specify everything
# or rely on the gateway EUI and retrieve settings files from remote (recommended)
echo "Gateway configuration:"

# Try to get gateway ID from MAC address
# First try eth0, if that does not exist, try wlan0 (for RPi Zero)
GATEWAY_EUI_NIC="eth0"
if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    GATEWAY_EUI_NIC="wlan0"
fi

if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    echo "ERROR: No network interface found. Cannot set gateway ID."
    exit 1
fi

GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
GATEWAY_EUI=${GATEWAY_EUI^^} # toupper

echo "Detected EUI $GATEWAY_EUI from $GATEWAY_EUI_NIC"

#read -r -p "Do you want to use remote settings file? [y/N]" response
#response=${response,,} # tolower

#if [[ $response =~ ^(yes|y) ]]; then
#    NEW_HOSTNAME="ttn-gateway"
#    REMOTE_CONFIG=true
#else
    printf "       Host name [cytron-lora-gw]:"
    read NEW_HOSTNAME
    if [[ $NEW_HOSTNAME == "" ]]; then NEW_HOSTNAME="cytron-lora-gw"; fi

    printf "       Descriptive name [Cytron Indoor LoRa Gateway]:"
    read GATEWAY_NAME
    if [[ $GATEWAY_NAME == "" ]]; then GATEWAY_NAME="Cytron Indoor LoRa Gateway"; fi

    printf "       Contact email[support@cytron.com.my]: "
    read GATEWAY_EMAIL
    if [[ $GATEWAY_EMAIL == "" ]]; then GATEWAY_EMAIL="support@cytron.com.my"; fi

    printf "       Latitude [5.315007]: "
    read GATEWAY_LAT
    if [[ $GATEWAY_LAT == "" ]]; then GATEWAY_LAT="5.315007"; fi

    printf "       Longitude [100.4737183]: "
    read GATEWAY_LON
    if [[ $GATEWAY_LON == "" ]]; then GATEWAY_LON="100.4737183"; fi

    printf "       Altitude [17]: "
    read GATEWAY_ALT
    if [[ $GATEWAY_ALT == "" ]]; then GATEWAY_ALT="17"; fi
#fi


# Change hostname if needed
CURRENT_HOSTNAME=$(hostname)

if [[ $NEW_HOSTNAME != $CURRENT_HOSTNAME ]]; then
    echo "Updating hostname to '$NEW_HOSTNAME'..."
    hostname $NEW_HOSTNAME
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
fi

# Install LoRaWAN packet forwarder repositories
INSTALL_DIR="/opt/ttn-gateway"
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR

# Remove WiringPi built from source (older installer versions)
if [ -d wiringPi ]; then
    pushd wiringPi
    ./build uninstall
    popd
    rm -rf wiringPi
fi 

# Build LoRa gateway app
if [ ! -d lora_gateway ]; then
    git clone -b legacy https://github.com/CytronTechnologies/lora_gateway.git
    pushd lora_gateway
else
    pushd lora_gateway
    git fetch origin
    git checkout legacy
    git reset --hard
fi

sed -i -e 's/PLATFORM= kerlink/PLATFORM= imst_rpi/g' ./libloragw/library.cfg

make

popd

# Build packet forwarder
if [ ! -d packet_forwarder ]; then
    git clone -b legacy https://github.com/CytronTechnologies/packet_forwarder.git
    pushd packet_forwarder
else
    pushd packet_forwarder
    git fetch origin
    git checkout legacy
    git reset --hard
fi

make

popd

# Download gateway conf
if [ ! -d gateway-conf ]; then
    git clone https://github.com/CytronTechnologies/gateway-conf.git
else
    pushd gateway-conf
    git fetch origin
    git checkout master
    git reset --hard
    popd
fi

# Symlink poly packet forwarder
if [ ! -d bin ]; then mkdir bin; fi
if [ -f ./bin/poly_pkt_fwd ]; then rm ./bin/poly_pkt_fwd; fi
ln -s $INSTALL_DIR/packet_forwarder/poly_pkt_fwd/poly_pkt_fwd ./bin/poly_pkt_fwd

if [ -f ./bin/global_conf.json ]; then rm ./bin/global_conf.json; fi

if [[ $CONFIG == "AU_915" ]];then
    cp -f ./gateway-conf/AU-global_conf.json ./bin/global_conf.json
fi
if [[ $CONFIG == "AU_920" ]];then
    cp -f ./gateway-conf/AU920-global_conf.json ./bin/global_conf.json
fi
if [[ $CONFIG == "MY_919" ]];then
    cp -f ./gateway-conf/MY-global_conf.json ./bin/global_conf.json
fi
if [[ $CONFIG == "US_902" ]];then
    cp -f ./gateway-conf/US-global_conf.json ./bin/global_conf.json
fi

# in case $CONFIG is invalid, use AU920-global_conf
if [ ! -f ./bin/global_conf.json ]; then cp -f ./gateway-conf/AU920-global_conf.json ./bin/global_conf.json; fi

LOCAL_CONFIG_FILE=$INSTALL_DIR/bin/local_conf.json

# Remove old config file
if [ -e $LOCAL_CONFIG_FILE ]; then rm $LOCAL_CONFIG_FILE; fi;

#if [ "$REMOTE_CONFIG" = true ] ; then
#    # Get remote configuration repo
#    if [ ! -d gateway-remote-config ]; then
#        git clone https://github.com/ttn-zh/gateway-remote-config.git
#        pushd gateway-remote-config
#    else
#        pushd gateway-remote-config
#        git pull
#        git reset --hard
#    fi
#
#    ln -s $INSTALL_DIR/gateway-remote-config/$GATEWAY_EUI.json $LOCAL_CONFIG_FILE

#    popd
#else

ROUTER=au
if [[ $CONFIG == "US_902" ]];then ROUTER=us ;fi;

    echo -e "{\n\t\"gateway_conf\": {\n\t\t\"gateway_ID\": \"$GATEWAY_EUI\",\n\t\t\"servers\": [ { \"server_address\": \"router.$ROUTER.thethings.network\", \"serv_port_up\": 1700, \"serv_port_down\": 1700, \"serv_enabled\": true } ],\n\t\t\"ref_latitude\": $GATEWAY_LAT,\n\t\t\"ref_longitude\": $GATEWAY_LON,\n\t\t\"ref_altitude\": $GATEWAY_ALT,\n\t\t\"contact_email\": \"$GATEWAY_EMAIL\",\n\t\t\"description\": \"$GATEWAY_NAME\" \n\t}\n}" >$LOCAL_CONFIG_FILE
#fi

popd

echo "Gateway EUI is: $GATEWAY_EUI"
echo "The hostname is: $NEW_HOSTNAME"
echo "Open TTN console and register your gateway using your EUI: https://console.thethingsnetwork.org/gateways"
echo
echo "Installation completed."

# Start packet forwarder as a service
cp ./start.sh $INSTALL_DIR/bin/
cp ./connect.sh $INSTALL_DIR/bin/
chmod +x $INSTALL_DIR/bin/connect.sh
cp ./ttn-gateway.service /lib/systemd/system/
systemctl enable ttn-gateway.service

echo "The system will reboot in 5 seconds..."
sleep 5
shutdown -r now
