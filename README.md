# **Information & Theory**

## mikrotik-alp_rc_upgrade-server  - Docker-image for Mikrotik®-devices

The complete documentation is available here: https://github.com/felted67/mikrotik-alp_rc_upgrade-server/blob/main/doc/mus-documentation.pdf</br>
The source-code is also available here: https://github.com/felted67/mikrotik-alp_rc_upgrade-server/tree/main</br>

This docker-image for Mikrotik®-devices is intended to install inside a container-enabled device.</br>
If your Mikrotik®-device is able to run docker-images mainly depends on the device and the used RouterOS (ROS®).</br>
Versions beginning from 7.5 (roughly) are able to run containers on the device. The current version this image is build for </br>
is RouterOS 7.10 (at the time this documentation is written). Also container-functionality is current only available for AMD64-,</br>
ARM64- and ARM-architectures/devices.</br>
</br>
First you need to enable the container-feature on your device. Please use the Mikrotik®-documentation for enabling the container-mode.</br>
The documentation can be found here: <https://help.mikrotik.com/docs/display/ROS/Container>
</br>
Also some preliminaries should be kept in mind. First be sure that the system is powerful enough to run a docker-container.</br>
This means that your device must have enough available RAM and disk space (external storage), and also a powerful CPU.</br>
Currently the following CPU-architectures are available for docker-container: ARM, ARM64 and X86_64(AMD64).</br>
For external storage there is the paket "rose-storage" available, this can be used to mount SMB, NFS and iSCSI-devices into</br>
the Mikrotik®-device. Please keep in mind, that NFS-shares may lack of not allowing "chmod"- and "chown"-commands</br>
on the shares. Also you could use a external-disk (SSD/USB-Stick) as a storage-device.</br>
</br>
This image is build using Docker-in-Docker-techniques on a CI/CD-system. The images are tested on several CHR-</br>
(CloudHostedRouter)-systems on  AMD64(x86_64)-hosts (virtual/non-virtual) and also on different</br> ARM/ARM64-devices (hAP ax2, hAP ax3, RB3011 and others).</br>

### Theory of the image

Mainly a docker-image consists of one process, which is running alone in the container on the host-system. This means when this</br>
process has ended, the whole container ends. At this point this image is different. Because of using a very small Linux (Alpine Linux),</br>
it is possible to run the openrc-init-system in the container as the main process. This openrc-process breaks the historical way a</br>
container is meant to run, but gives also to control running tasks inside the container.</br>
So mainly the openrc-(init) -process is running all the time, giving the chance to add several more tasks to the container. </br>
Also it is possible to restart the processes beside openrc running inside the container without killing the complete container itself.</br>
This is the main theory of this image - no magic for far...</br>

### Installation of docker-image

First open WinBox® and connect to the device.</br>
Install docker-image to Mikrotik®-device and attach via "New Terminal" and  <code>/container shell number=X </code> (where X is the number of container).</br>
There are three arch-versions available: </br>
amd64 => for chr-devices (x86_64)</br>
arm64 => for arm64/aarch64-devices</br>
arm => for arm-devices</br>
If you don't now the number of the container, please type on the console in WInBox®:</br>
<code> /container print</code> - The number of the container is given on the output.</br>
In the previous opened shell of the container in terminal of WinBox® do:</br>
1.) Set root-password: $ <code>passwd root </code></br>
~~2.) Run <code>/sbin/first_start.sh</code> to complete configuration of the image.</br>~~
2.) New behaviour: the script <code>/sbin/first_start.sh</code> is started automatically. Until the container is new created or recreated, all infomations in the </br>
      container are used until changed. Therefore after a "normal" restart (start/stop/start), all settings will survive. </br>
      A root password is NOT defined (but can be set via cli of container), ~~but you can use the stated ssh-keys as connection-keys. </br>
      BUT BEWARE: these keys are used unless they are changed in <code>~/.ssh/authorized_keys</code> !!! Anyone can get and use these keys !!! </br>~~
3.) Assign under IP/Firewall/NAT a DST-NAT-rule to ip of docker-container (defined under /interfaces/veth) and needed port of service in container. </br>
     Exposed ports are: <code>80/tcp</code>(Webserver) & <code>22/tcp</code>(SSH).</br>

~~Useable ssh-keys: </br>
The ssh-keys can be found in the container in the directory <code>/root/.ssh/*</code>. </br>
Use temporary a root password to connect or copy the private keys out of the directory <code>/root/.ssh/*</code> without the .pub-extension.</br>
These keys can be used to connect via ssh out-of-the-box. Please use the appropriate keys (rsa/dsa/ed25519) !!! </br>~~

### Remarks

The tag beside -devel and -latest displays the version of the image, devided in two parts with a "-" between them.</br>
Left part of image-tag reflects the used AlpineLinux-version (v3.18.2-..).The right part is the version of the image itself (..-0.0.1).</br>
Tag -latest is the actual and latest (highest tag) stable running version.</br>
Tag -devel is the current development version, not advised for production. Also the -devel-tag may not run, as development in going on.</br>
***Please be advised again NOT to use the -devel-version in a production-environment.***</br>
Because of development is made with Gitlab and therefore with CI/CD-techniques, these version are created automatically without further notice</br>
and will not be revised or tested permanently. A tagged version with version-number or the -latest-tagged-images are tested on the target-system </br>
before getting tagged !</br>
</p>
It is useful at the beginning to assign the container a root-directory (Root-Dir) to get a "stable" filesystem for the container.</br>
Using rose-storage-package for filesystem of container may not work if nfs-shares are used.
Depending on the service and/or first_start.sh-script</br> a chown or chmod in the script may not work on nfs-shares.</br>

### Disclaimer

Mikrotik®, WInBox®, RouterOS, ROS®, hap x2, hap x3, RB3011 and others are or maybe trademarks or registered names of SIA Mikrotīkls.</br>
This project is not affliated with SIA Mikrotīkls and SIA Mikrotīkls is not responsible for this project. Link: <https://mikrotik.com/aboutus></br>
All names, trademarks or other techniques are only used to illustrate ths project.</br>
There is not responsibilty for any faults, errors, defects and so on regarding using this images.</br>
This is a private project and all information stated here are given you as it is and with no responsibilty for any defects, errors and harm using this software.</br>
Alpine Linux is copyrighted by the Alpine Linux Development Team with all rights reserved.</br>
Also all names and symbols from Alpine Linux are used for illustration purposes only with no responsibilty</br>
of the Alpine Linux Development Team. Link: <https://www.alpinelinux.org/></br>
