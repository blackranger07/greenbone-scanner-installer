# greenbone-scanner-installer
Vulnerability Scanner Installer for Kali Linux

Greenbone Vulerability Scanner installer (for Kali Linux only) to check for vulnerabilities so that the user can better protect the devices on their network.

***The script must be ran as the root/sudo user or it will not run.***

Make the script gsa-install-suite.bash executable:

1.) chmod 755 gsa-install-suite.bash 

2.) To Start the installer: sudo ./gsascanner.bash

3.) Wait for the script to complete. All other files will be dealt with appropriately during the install.

**How to Greenbone?**

**Update vulnerability database:** greenbone-feed-sync (This will take time to complete.)

**To start:** gvm-start

**To stop:** gvm-stop

**ACCESS WEBUI locally via: https://127.0.0.1:9392**
