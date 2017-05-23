# The Things Network Installer for RisingHF-based gateway

Reference setup for [The Things Network](http://thethingsnetwork.org/) gateways based on the RisingHF 915MHz 8-Channel LoRa concentrator with a Raspberry Pi host.

This installer targets the **SPI version** of the board.

## Manual Installation on Raspbian Image

- Connect Raspberry Pi to Ethernet or WiFi
- Use raspi-config utility to **enable SPI** and also **expand the filesystem**:

        $ sudo raspi-config

- Reboot (it will ask on exit, but you can do it manually with sudo reboot)
- Configure locales and time zone:

        $ sudo dpkg-reconfigure locales
        $ sudo dpkg-reconfigure tzdata

- **Optional, you can follow this step if you are using fresh Raspbian image**

  Make sure you have an updated installation and install `git`:

        $ sudo apt-get update
        $ sudo apt-get upgrade
        $ sudo apt-get install git

- **Optional, you can follow this step if you wish to use WiFi instead of Ethernet**

  Configure the wifi credentials (check [here for additional details](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md))

        $ sudo nano /etc/wpa_supplicant/wpa_supplicant.conf 

  And add the following block at the end of the file, replacing SSID and password to match your network:

        network={
           ssid="The_SSID_of_your_wifi"
           psk="Your_wifi_password"
        }
 
- Clone [the installer](https://github.com/CytronTechnologies/RisingHF-gateway/) and start the installation

        $ git clone https://github.com/CytronTechnologies/RisingHF-gateway.git ~/RisingHF-gateway
        $ cd ~/RisingHF-gateway
        $ sudo ./install.sh

- By default, AU920-global_conf.json will be used. By declaring which band you are going to use in installation, different global_conf.json will be installed. For more info, please refer to [gateway-conf](https://github.com/CytronTechnologies/gateway-conf).
	
	* AU_915 - `$ sudo ./install.sh AU_915`
	* AU_920 - `$ sudo ./install.sh AU_920`
	* MY_919 - `$ sudo ./install.sh MY_919`
	* US_902 - `$ sudo ./install.sh US_902`

- **Big Success!** You should now have a running gateway in front of you!

# Credits

These scripts are largely based on the awesome work by [Ruud Vlaming](https://github.com/devlaam) on the [Lorank8 installer](https://github.com/Ideetron/Lorank).
