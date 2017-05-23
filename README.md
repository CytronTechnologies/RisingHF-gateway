# The Things Network: iC880a-based gateway

Reference setup for [The Things Network](http://thethingsnetwork.org/) gateways based on the RisingHF 915MHz 8-Channel LoRa concentrator with a Raspberry Pi host.

This installer targets the **SPI version** of the board.

## Setup based on Raspbian image

- Download [Raspbian Jessie Lite](https://www.raspberrypi.org/downloads/)
- Follow the [installation instruction](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) to create the SD card
- Start your RPi connected to Ethernet
- Plug the iC880a (**WARNING**: first power plug to the wall socket, then to the gateway DC jack, and ONLY THEN USB to RPi!)
- From a computer in the same LAN, `ssh` into the RPi using the default hostname:

        local $ ssh pi@raspberrypi.local

- Default password of a plain-vanilla RASPBIAN install for user `pi` is `raspberry`
- Use `raspi-config` utility to expand the filesystem (1 Expand filesystem):

        $ sudo raspi-config

- Reboot
- Configure locales and time zone:

        $ sudo dpkg-reconfigure locales
        $ sudo dpkg-reconfigure tzdata

- Make sure you have an updated installation and install `git`:

        $ sudo apt-get update
        $ sudo apt-get upgrade
        $ sudo apt-get install git

- Create new user for TTN and add it to sudoers

        $ sudo adduser ttn 
        $ sudo adduser ttn sudo

- To prevent the system asking root password regularly, add TTN user in sudoers file

        $ sudo visudo

Add the line `ttn ALL=(ALL) NOPASSWD: ALL`

:warning: Beware this allows a connected console with the ttn user to issue any commands on your system, without any password control. This step is completely optional and remains your decision.

- Logout and login as `ttn` and remove the default `pi` user

        $ sudo userdel -rf pi

- Configure the wifi credentials (check [here for additional details](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md))

        $ sudo nano /etc/wpa_supplicant/wpa_supplicant.conf 

And add the following block at the end of the file, replacing SSID and password to match your network:

                network={
                    ssid="The_SSID_of_your_wifi"
                    psk="Your_wifi_password"
                }
 
- Clone [the installer](https://github.com/CytronTechnologies/ic880a-gateway/) and start the installation

        $ git clone https://github.com/CytronTechnologies/ic880a-gateway.git ~/ic880a-gateway
        $ cd ~/ic880a-gateway
        $ sudo ./install.sh

- By default, AU920-global_conf.json will be used. By declaring which band you are going to use in installation, different global_conf.json will be installed. For more info, please refer to [gateway-conf](https://github.com/CytronTechnologies/gateway-conf).
	
	* AU_915 - `$ sudo ./install.sh AU_915`
	* AU_920 - `$ sudo ./install.sh AU_920`
	* MY_919 - `$ sudo ./install.sh MY_919`
	* US_902 - `$ sudo ./install.sh US_902`

- **Big Success!** You should now have a running gateway in front of you!

# Credits

These scripts are largely based on the awesome work by [Ruud Vlaming](https://github.com/devlaam) on the [Lorank8 installer](https://github.com/Ideetron/Lorank).
