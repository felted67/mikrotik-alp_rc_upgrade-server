This is the short instruction to start the "mikrotik.upgrade.server":

Here is a rough overview of the needed steps in short:
1.	Install CONTAINER-package and enable CONTAINER-function on the device
2.	Create one or several VETH-devices for the container(s) and give them IP-addresses
3.	Create a bridge (also with IP-address) for these VETH-devices and the container(s) running on
4.	Prepare the FIREWALL, NAT and the PORT-FORWARDING to reach the container(s) from the outside networks (from the view outside the container-bridge)
5.	Configure the container with the used VETH-device, the image to be downloaded and some other configurations like DNS, start-on-boot, logging etc.
6.	Apply the container to the device. Source: https://hub.docker.com/repository/docker/felted67/mikrotik-alp_rc_upgrade-server/general
7.	Start the container
8.	Try to reach the web-interface   
9.	On access, please wait during the self-configuration and the download of the files/packages.
10.	 Use the “mus” on your network – have fun

The complete documentation is available here: https://github.com/felted67/mikrotik-alp_rc_upgrade-server/blob/main/doc/mus-documentation.pdf
Please read the complete documentation if you are running into issues !