# Exercice Docker #4

Réaliser, via Docker, le déploiement de deux conteneurs pouvant communiquer entre eux:

* Pour cela, vous créerez dans un premier temps un réseau qui sera utilisé par les deux conteneurs
* Vous créerez ensuite un conteneur sur lequel vous devrez installer la commande servant à la réalisation du ping
* Sauvegardez ensuite l'image issue de cette installation pour pouvoir créer un second conteneur directement pourvu de ping
* Vérifier / connecter les deux conteneurs au même réseau virtuel
* Dans chacun des conteneur, vérifier la capacité de communiquer avec son voisin via le nom du conteneur (tester la résolution DNS interne à Docker)


---

Result  CLI:
```bash
$ docker network create exo4-reseau
4dbbe0c95708beb8c0a0210abcf868b247ac65940982da181ae48e474672969f

$ docker run -d --name exo4-ubuntu1 --network exo4-reseau ubuntu:24.04 sleep infinity
48ed403511be9762160eb82f0f5007a0a44d913eb3dbe1592d7d115d2d1bb18e

$ docker exec exo4-ubuntu1 apt-get update
Get:1 http://ports.ubuntu.com/ubuntu-ports noble InRelease [256 kB]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble-updates InRelease [126 kB]
Get:3 http://ports.ubuntu.com/ubuntu-ports noble-backports InRelease [126 kB]
Get:4 http://ports.ubuntu.com/ubuntu-ports noble-security InRelease [126 kB]
Get:5 http://ports.ubuntu.com/ubuntu-ports noble/restricted arm64 Packages [113 kB]
Get:6 http://ports.ubuntu.com/ubuntu-ports noble/multiverse arm64 Packages [274 kB]
Get:7 http://ports.ubuntu.com/ubuntu-ports noble/universe arm64 Packages [19.0 MB]
Get:8 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 Packages [1776 kB]
Get:9 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 Packages [1762 kB]
Get:10 http://ports.ubuntu.com/ubuntu-ports noble-updates/restricted arm64 Packages [3185 kB]
Get:11 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe arm64 Packages [2212 kB]
Get:12 http://ports.ubuntu.com/ubuntu-ports noble-updates/multiverse arm64 Packages [110 kB]
Get:13 http://ports.ubuntu.com/ubuntu-ports noble-backports/universe arm64 Packages [36.3 kB]
Get:14 http://ports.ubuntu.com/ubuntu-ports noble-backports/main arm64 Packages [49.0 kB]
Get:15 http://ports.ubuntu.com/ubuntu-ports noble-backports/multiverse arm64 Packages [671 B]
Get:16 http://ports.ubuntu.com/ubuntu-ports noble-security/main arm64 Packages [1448 kB]
Get:17 http://ports.ubuntu.com/ubuntu-ports noble-security/restricted arm64 Packages [3063 kB]
Get:18 http://ports.ubuntu.com/ubuntu-ports noble-security/multiverse arm64 Packages [105 kB]
Get:19 http://ports.ubuntu.com/ubuntu-ports noble-security/universe arm64 Packages [1636 kB]
Fetched 35.4 MB in 4s (8599 kB/s)
Reading package lists...

$ docker exec exo4-ubuntu1 apt-get install -y iputils-ping
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
  libcap2-bin libpam-cap
The following NEW packages will be installed:
  iputils-ping libcap2-bin libpam-cap
0 upgraded, 3 newly installed, 0 to remove and 3 not upgraded.
Need to get 90.6 kB of archives.
After this operation, 598 kB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libcap2-bin arm64 1:2.66-5ubuntu2.4 [33.5 kB]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 iputils-ping arm64 3:20240117-1ubuntu0.1 [44.6 kB]
Get:3 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 libpam-cap arm64 1:2.66-5ubuntu2.4 [12.5 kB]
debconf: delaying package configuration, since apt-utils is not installed
Fetched 90.6 kB in 1s (176 kB/s)
Selecting previously unselected package libcap2-bin.
(Reading database ...
(Reading database ... 5%
(Reading database ... 10%
(Reading database ... 15%
(Reading database ... 20%
(Reading database ... 25%
(Reading database ... 30%
(Reading database ... 35%
(Reading database ... 40%
(Reading database ... 45%
(Reading database ... 50%
(Reading database ... 55%
(Reading database ... 60%
(Reading database ... 65%
(Reading database ... 70%
(Reading database ... 75%
(Reading database ... 80%
(Reading database ... 85%
(Reading database ... 90%
(Reading database ... 95%
(Reading database ... 100%
(Reading database ... 4376 files and directories currently installed.)
Preparing to unpack .../libcap2-bin_1%3a2.66-5ubuntu2.4_arm64.deb ...
Unpacking libcap2-bin (1:2.66-5ubuntu2.4) ...
Selecting previously unselected package iputils-ping.
Preparing to unpack .../iputils-ping_3%3a20240117-1ubuntu0.1_arm64.deb ...
Unpacking iputils-ping (3:20240117-1ubuntu0.1) ...
Selecting previously unselected package libpam-cap:arm64.
Preparing to unpack .../libpam-cap_1%3a2.66-5ubuntu2.4_arm64.deb ...
Unpacking libpam-cap:arm64 (1:2.66-5ubuntu2.4) ...
Setting up libcap2-bin (1:2.66-5ubuntu2.4) ...
Setting up libpam-cap:arm64 (1:2.66-5ubuntu2.4) ...
debconf: unable to initialize frontend: Dialog
debconf: (TERM is not set, so the dialog frontend is not usable.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC entries checked: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /usr/lib/aarch64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 8.)
debconf: falling back to frontend: Teletype
Setting up iputils-ping (3:20240117-1ubuntu0.1) ...

$ docker commit --author 'Adenan KHACHNANE <140979426+4d3n4n@users.noreply.github.com>' exo4-ubuntu1 ubuntu-ping:exo4
sha256:0b852c1e9d588fa047fb54595b3462161af78323209839b892e0a6da6a48c0c2

$ docker run -d --name exo4-ubuntu2 --network exo4-reseau ubuntu-ping:exo4 sleep infinity
dd4429ae2f4ee2d17a01c9677a2799bd085a3edb7b7b4255da7c70fe61a6dc8e

$ docker network inspect exo4-reseau --format '{{range .Containers}}{{println .Name .IPv4Address}}{{end}}'
exo4-ubuntu1 172.18.0.2/16
exo4-ubuntu2 172.18.0.3/16


$ docker exec exo4-ubuntu1 ping -c 4 exo4-ubuntu2
PING exo4-ubuntu2 (172.18.0.3) 56(84) bytes of data.
64 bytes from exo4-ubuntu2.exo4-reseau (172.18.0.3): icmp_seq=1 ttl=64 time=0.072 ms
64 bytes from exo4-ubuntu2.exo4-reseau (172.18.0.3): icmp_seq=2 ttl=64 time=0.158 ms
64 bytes from exo4-ubuntu2.exo4-reseau (172.18.0.3): icmp_seq=3 ttl=64 time=0.144 ms
64 bytes from exo4-ubuntu2.exo4-reseau (172.18.0.3): icmp_seq=4 ttl=64 time=0.141 ms

4 packets transmitted, 4 received, 0% packet loss, time 3074ms
rtt min/avg/max/mdev = 0.072/0.128/0.158/0.033 ms

$ docker exec exo4-ubuntu2 ping -c 4 exo4-ubuntu1
PING exo4-ubuntu1 (172.18.0.2) 56(84) bytes of data.
64 bytes from exo4-ubuntu1.exo4-reseau (172.18.0.2): icmp_seq=1 ttl=64 time=0.041 ms
64 bytes from exo4-ubuntu1.exo4-reseau (172.18.0.2): icmp_seq=2 ttl=64 time=0.167 ms
64 bytes from exo4-ubuntu1.exo4-reseau (172.18.0.2): icmp_seq=3 ttl=64 time=0.147 ms
64 bytes from exo4-ubuntu1.exo4-reseau (172.18.0.2): icmp_seq=4 ttl=64 time=0.215 ms

4 packets transmitted, 4 received, 0% packet loss, time 3070ms
rtt min/avg/max/mdev = 0.041/0.142/0.215/0.063 ms
```
