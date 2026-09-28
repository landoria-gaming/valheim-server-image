# Optional: additional configuration

Run these commands on Debian.

## Enable swap

Swap provides disk-backed memory when RAM is full.

```bash
sudo apt-get update && sudo apt-get install -y util-linux
sudo fallocate -l 4G /swapfile # Set 4GB of swap
sudo chmod 600 /swapfile
sudo /usr/sbin/mkswap /swapfile
sudo /usr/sbin/swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Verify that swap is enabled:

```console
$ sudo /usr/sbin/swapon --show
NAME      TYPE SIZE USED PRIO
/swapfile file   4G   0B   -2
```

## Enable earlyoom

Earlyoom helps prevent host freezes by terminating processes when memory runs
critically low; it may terminate Valheim.

```bash
sudo apt-get update && sudo apt-get install -y earlyoom
sudo systemctl enable --now earlyoom
sudo systemctl is-active earlyoom # Should display "active"
```
