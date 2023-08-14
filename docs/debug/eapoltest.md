---
layout: default
title: Testing EAP-TLS
parent: Debug
nav_order: 2
---

# Testing EAP-TLS
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

A quick way of testing your connection is to use the _eapol_test_ client.

You can download the latest version of the wpa_supplicant source from [their website](http://w1.fi/wpa_supplicant/).

```sh
{% raw %}
curl http://w1.fi/releases/wpa_supplicant-2.10.tar.gz -o wpa_supplicant.tar.gz
{% endraw %}
```

Untar it
```sh
{% raw %}
tar -xvf wpa_supplicant.tar.gz 
{% endraw %}
```

You then have to configure it to build the eapol_test client
```sh
{% raw %}
cd wpa_supplicant-2.10/wpa_supplicant/
cp defconfig .config
{% endraw %}
```

Open the .config file with your preferred editor

Find the line containing

`#CONFIG_EAPOL_TEST=y`

and uncomment it

`CONFIG_EAPOL_TEST=y`

If you don’t have a compiler, install it.

In my case I did

```sh
{% raw %}
apt install build-essential
{% endraw %}
```

Install the required libraries (the compiler will fail and point out missing pieces).

In my case I had to install the following, but your system may have different requirements:

```sh
{% raw %}
apt install libssl-dev libnl1 libnl-dev libnl-3-dev libdbus-1-dev libnl-genl-3-dev libnl-route-3-dev
{% endraw %}
```

When you’re ready to compile, run:

```sh
{% raw %}
make eapol_test
{% endraw %}
```

If everything goes as expected, you will find the compiled binary in the wpa_subbplicant/ folder.

Copy it to /usr/local/bin/ to have the command available system wide

```sh
{% raw %}
cp eapol_test /usr/local/bin/
{% endraw %}
```

Now, in order to test the EAP-TLS connection, you have to create a configuration file.

Create an eapol_test.conf file and open it with your preferred editor and add the following.

```js
{% raw %}
network={
    ssid="DoesNotMatterForThisTest"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="youridentity"
    ca_cert="/etc/freeradius/certs/ca.pem"
    client_cert="~/client.pem"
    private_key="~/client.key"
    private_key_passwd="whatever"
    eapol_flags=3
}
{% endraw %}
```
Adjust the paths to your CA cert and client cert/key (I’m running this from the same freeradius machine, so i picked the CA certificate from the freeradius directory), then run the following command:

```sh
{% raw %}
eapol_test -c eapol_test.conf -s <radiussecret>
{% endraw %}
```

This will help you A LOT to debug any issues, together with freeradius debug output.

