---
layout: default
title: Install freeradius
parent: Radius
nav_order: 1
---

# Install freeradius
{: .no_toc }

---

Packages are available [here](https://networkradius.com/packages/).

Since I’m using debian 11, I  just followed the simple steps available on the website.

Trust the NetworkRadius repository by adding their PGP key

```sh
install -d -o root -g root -m 0755 /etc/apt/keyrings
curl -s 'https://packages.networkradius.com/pgp/packages%40networkradius.com' | \
    tee /etc/apt/keyrings/packages.networkradius.com.asc > /dev/null
```

Add the APT sources list:
```sh
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.networkradius.com.asc] http://packages.networkradius.com/freeradius-3.2/debian/bullseye bullseye main" | \
    tee /etc/apt/sources.list.d/networkradius.list > /dev/null
```
Install the required packages
```sh
apt update && apt install freeradius freeradius-ldap
```