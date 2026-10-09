# Exercice Docker #1


Réaliser une image de conteneur compatible avec NGINX (serveur web):

Pour cela, suivre les étapes suivantes:
* Créer un conteneur Ubuntu
* Entrer dans le conteneur Ubuntu
* Mettre à jour les paquets dans le conteneur
* Installer NGINX dans le conteneur
* Sortir du conteneur
* Sauvegarder l'état actuel du conteneur en tant que nouvelle image nommée par exemple "ubuntu-nginx"

---

Result CLI :
```bash
docker run -it --name exo1-ubuntu ubuntu:24.04 bash
Unable to find image 'ubuntu:24.04' locally
24.04: Pulling from library/ubuntu
90812e242c93: Pull complete
d840120f5ea1: Download complete
Digest: sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55
Status: Downloaded newer image for ubuntu:24.04
root@f9e5acf00c75:/# apt update
Get:1 http://ports.ubuntu.com/ubuntu-ports noble InRelease [256 kB]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble-updates InRelease [126 kB]
Get:3 http://ports.ubuntu.com/ubuntu-ports noble-backports InRelease [126 kB]
Get:4 http://ports.ubuntu.com/ubuntu-ports noble-security InRelease [126 kB]
Get:5 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 Packages [1776 kB]
Get:6 http://ports.ubuntu.com/ubuntu-ports noble/restricted arm64 Packages [113 kB]
Get:7 http://ports.ubuntu.com/ubuntu-ports noble/universe arm64 Packages [19.0 MB]
Get:8 http://ports.ubuntu.com/ubuntu-ports noble/multiverse arm64 Packages [274 kB]
Get:9 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 Packages [1762 kB]
Get:10 http://ports.ubuntu.com/ubuntu-ports noble-updates/restricted arm64 Packages [3185 kB]
Get:11 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe arm64 Packages [2212 kB]
Get:12 http://ports.ubuntu.com/ubuntu-ports noble-updates/multiverse arm64 Packages [110 kB]
Get:13 http://ports.ubuntu.com/ubuntu-ports noble-backports/main arm64 Packages [49.0 kB]
Get:14 http://ports.ubuntu.com/ubuntu-ports noble-backports/multiverse arm64 Packages [671 B]
Get:15 http://ports.ubuntu.com/ubuntu-ports noble-backports/universe arm64 Packages [36.3 kB]
Get:16 http://ports.ubuntu.com/ubuntu-ports noble-security/main arm64 Packages [1448 kB]
Get:17 http://ports.ubuntu.com/ubuntu-ports noble-security/universe arm64 Packages [1636 kB]
Get:18 http://ports.ubuntu.com/ubuntu-ports noble-security/multiverse arm64 Packages [105 kB]
Get:19 http://ports.ubuntu.com/ubuntu-ports noble-security/restricted arm64 Packages [3063 kB]
Fetched 35.4 MB in 6s (6254 kB/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
3 packages can be upgraded. Run 'apt list --upgradable' to see them.
root@f9e5acf00c75:/# apt upgrade -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Calculating upgrade... Done
The following packages will be upgraded:
  libaudit-common libaudit1 libssl3t64
3 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
Need to get 1891 kB of archives.
After this operation, 2048 B of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libaudit-common all 1:3.1.2-2.1ubuntu0.1 [5948 B]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libaudit1 arm64 1:3.1.2-2.1ubuntu0.1 [47.6 kB]
Get:3 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libssl3t64 arm64 3.0.13-0ubuntu3.16 [1838 kB]
Fetched 1891 kB in 1s (2007 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
(Reading database ... 4376 files and directories currently installed.)
Preparing to unpack .../libaudit-common_1%3a3.1.2-2.1ubuntu0.1_all.deb ...
Unpacking libaudit-common (1:3.1.2-2.1ubuntu0.1) over (1:3.1.2-2.1build1.1) ...
Setting up libaudit-common (1:3.1.2-2.1ubuntu0.1) ...
(Reading database ... 4376 files and directories currently installed.)
Preparing to unpack .../libaudit1_1%3a3.1.2-2.1ubuntu0.1_arm64.deb ...
Unpacking libaudit1:arm64 (1:3.1.2-2.1ubuntu0.1) over (1:3.1.2-2.1build1.1) ...
Setting up libaudit1:arm64 (1:3.1.2-2.1ubuntu0.1) ...
(Reading database ... 4376 files and directories currently installed.)
Preparing to unpack .../libssl3t64_3.0.13-0ubuntu3.16_arm64.deb ...
Unpacking libssl3t64:arm64 (3.0.13-0ubuntu3.16) over (3.0.13-0ubuntu3.15) ...
Setting up libssl3t64:arm64 (3.0.13-0ubuntu3.16) ...
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
root@f9e5acf00c75:/# apt install nginx -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  iproute2 libatm1t64 libbpf1 libcap2-bin libelf1t64 libmnl0 libpam-cap libxtables12 nginx-common
Suggested packages:
  iproute2-doc python3:any fcgiwrap nginx-doc ssl-cert
The following NEW packages will be installed:
  iproute2 libatm1t64 libbpf1 libcap2-bin libelf1t64 libmnl0 libpam-cap libxtables12 nginx nginx-common
0 upgraded, 10 newly installed, 0 to remove and 0 not upgraded.
Need to get 2036 kB of archives.
After this operation, 6755 kB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libelf1t64 arm64 0.190-1.1ubuntu0.1 [58.4 kB]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 libbpf1 arm64 1:1.3.0-2build2 [168 kB]
Get:3 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 libmnl0 arm64 1.0.5-2build1 [12.4 kB]
Get:4 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 libxtables12 arm64 1.8.10-3ubuntu2 [35.9 kB]
Get:5 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libcap2-bin arm64 1:2.66-5ubuntu2.4 [33.5 kB]
Get:6 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 iproute2 arm64 6.1.0-1ubuntu6.4 [1126 kB]
Get:7 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 libatm1t64 arm64 1:2.5.1-5.1build1 [23.5 kB]
Get:8 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libpam-cap arm64 1:2.66-5ubuntu2.4 [12.5 kB]
Get:9 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 nginx-common all 1.24.0-2ubuntu7.18 [45.1 kB]
Get:10 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 nginx arm64 1.24.0-2ubuntu7.18 [521 kB]
Fetched 2036 kB in 1s (2502 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libelf1t64:arm64.
(Reading database ... 4376 files and directories currently installed.)
Preparing to unpack .../0-libelf1t64_0.190-1.1ubuntu0.1_arm64.deb ...
Unpacking libelf1t64:arm64 (0.190-1.1ubuntu0.1) ...
Selecting previously unselected package libbpf1:arm64.
Preparing to unpack .../1-libbpf1_1%3a1.3.0-2build2_arm64.deb ...
Unpacking libbpf1:arm64 (1:1.3.0-2build2) ...
Selecting previously unselected package libmnl0:arm64.
Preparing to unpack .../2-libmnl0_1.0.5-2build1_arm64.deb ...
Unpacking libmnl0:arm64 (1.0.5-2build1) ...
Selecting previously unselected package libxtables12:arm64.
Preparing to unpack .../3-libxtables12_1.8.10-3ubuntu2_arm64.deb ...
Unpacking libxtables12:arm64 (1.8.10-3ubuntu2) ...
Selecting previously unselected package libcap2-bin.
Preparing to unpack .../4-libcap2-bin_1%3a2.66-5ubuntu2.4_arm64.deb ...
Unpacking libcap2-bin (1:2.66-5ubuntu2.4) ...
Selecting previously unselected package iproute2.
Preparing to unpack .../5-iproute2_6.1.0-1ubuntu6.4_arm64.deb ...
Unpacking iproute2 (6.1.0-1ubuntu6.4) ...
Selecting previously unselected package libatm1t64:arm64.
Preparing to unpack .../6-libatm1t64_1%3a2.5.1-5.1build1_arm64.deb ...
Unpacking libatm1t64:arm64 (1:2.5.1-5.1build1) ...
Selecting previously unselected package libpam-cap:arm64.
Preparing to unpack .../7-libpam-cap_1%3a2.66-5ubuntu2.4_arm64.deb ...
Unpacking libpam-cap:arm64 (1:2.66-5ubuntu2.4) ...
Selecting previously unselected package nginx-common.
Preparing to unpack .../8-nginx-common_1.24.0-2ubuntu7.18_all.deb ...
Unpacking nginx-common (1.24.0-2ubuntu7.18) ...
Selecting previously unselected package nginx.
Preparing to unpack .../9-nginx_1.24.0-2ubuntu7.18_arm64.deb ...
Unpacking nginx (1.24.0-2ubuntu7.18) ...
Setting up libatm1t64:arm64 (1:2.5.1-5.1build1) ...
Setting up nginx-common (1.24.0-2ubuntu7.18) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 79.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC entries checked: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /usr/lib/aarch64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 8.)
debconf: falling back to frontend: Teletype
Setting up libelf1t64:arm64 (0.190-1.1ubuntu0.1) ...
Setting up libcap2-bin (1:2.66-5ubuntu2.4) ...
Setting up libmnl0:arm64 (1.0.5-2build1) ...
Setting up libxtables12:arm64 (1.8.10-3ubuntu2) ...
Setting up libpam-cap:arm64 (1:2.66-5ubuntu2.4) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 79.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC entries checked: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /usr/lib/aarch64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 8.)
debconf: falling back to frontend: Teletype
Setting up libbpf1:arm64 (1:1.3.0-2build2) ...
Setting up iproute2 (6.1.0-1ubuntu6.4) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 79.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC entries checked: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /usr/lib/aarch64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 8.)
debconf: falling back to frontend: Teletype
Setting up nginx (1.24.0-2ubuntu7.18) ...
invoke-rc.d: could not determine current runlevel
invoke-rc.d: policy-rc.d denied execution of start.
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
root@f9e5acf00c75:/# nginx -v
nginx version: nginx/1.24.0 (Ubuntu)
root@f9e5acf00c75:/# exit
exit
```
