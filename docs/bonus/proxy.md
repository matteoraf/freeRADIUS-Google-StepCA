---
layout: default
title: Proxying SCEP
parent: Bonus content
nav_order: 2
---

# Proxying SCEP
{: .no_toc }

---

If, for some (good) reason, you don’t want to expose your CA endpoint directly or you need to have a single CA but you want to make it easily accessible to multiple local infrastructures, you can decide to rely on a Registration Authority.
Key concepts are very well explained [here](https://smallstep.com/docs/step-ca/registration-authority-ra-mode/).

To make it very simple, you will establish a trust relation between the RA and the CA.
The RA will “authorize” certificate requests from clients with the provisioners that you’ll set up, it’ll then require the certificate to the upstream CA, which already trusts the RA and will immediately deliver the certificate.

In my case, I decided to go with a simpler way, I set up my own SCEP proxy instance using [micromdm’s implementation](https://github.com/micromdm/scep/) as a base.
You can find it in [this repo](https://github.com/matteoraf/scep-proxy/).

This proxy is just made with a server and a client coupled together, so the first receives the request, checks the challenge and forwards the request to Step-CA.
I plan to implement some additional checks on the proxy using my MDM API, but this will come at a future time.

In my case, to have an additional protection layer, I decided to put this behind a free Cloudflare proxy and install fail2ban, so I had to do some changes to the package in order to have some more logging to filter on and to [extract the correct IP from the request headers](https://developers.cloudflare.com/fundamentals/get-started/reference/http-request-headers/#cf-connecting-ip).


So, as usual, here are the steps involved
1. Download and build the Scep Proxy package
2. Set up an internal CA
3. Install step-ca Root cert in the system trust store 
4. Setup a server certificate using ACME (let’s encrypt is fine) and renewal
5. Set up the proxy to run as a service
6. Set up fail2ban and connect to Cloudflare
7. Set up your firewall to only accept connections from Cloudflare IPs

## Download and build the Scep Proxy package
You can download sources from the repo linked above. You’ll have to compile the package (install a go compiler first if you don’t have it) on your own system and then copy the scepproxy bin to */usr/bin/scepproxy* to make it available system-wide

## Set up an internal CA.
This is the key pair that it will use to encrypt/decrypt the PKI Envelope used to exchange certs and other data with the client and with the server.
In this case you can either use its internal CA or provide your own CA signed by the Step-CA root. That is totally up to you, the choice you make doesn’t change anything from a user perspective nor does it change the security of your system.
In case you decide to use the internal one, just don’t forget to put the fingerprint of this CA in the SCEP configuration profile, because this is the CA that your client will exchange SCEP messages with.
Creating a new CA it’s as easy as follows:

Create the required directories
 ```sh
scepproxy ca -init -depot /etc/scepproxy/depot
```

Init the CA
 ```sh
scepproxy ca -init -depot /etc/scepproxy/depot
```

As you can see we first create the directory where to save the CA key pair and then we init it. You can of course add additional details, just run the following command to get some details
 ```sh
scepproxy ca --help
```

## Install step-ca Root cert in the system trust store
This is important because Step-CA exposes its SCEP endpoint with https, so the SCEP proxy needs to trust that certificate.

For debian, you just need to put your root public key in the */usr/share/ca-certificates* directory, make sure that it has a **.crt** extension, and run `dpkg-reconfigure ca-certificates`.

## Setup a server certificate using ACME (let’s encrypt is fine) and renewal
We want to expose our proxy endpoint using https. We could have avoided this, since the SCEP messages are already encrypted, but this way we add an additional layer of encryption which isn’t a bad thing.
Unfortunately, we cannot use a certificate signed with our internal CA, because Cloudflare wouldn’t trust it, so we’d need to use either a public trusted CA (like letsencrypt) or use a [Cloudflare signed certs](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/).
I’d rather go with let’s encrypt, as it is easier to handle renewal. So just go get one of the many ACME clients available and set it up to get and renew a certificate for your domain.
I won’t go into much detail about this, I believe that if you got to this point, you already know how to set this up.

## Set up the proxy to run as a service

Alright, this is very similar to what we’ve done with step-ca before.

1. Add a service user for the CA

```sh
useradd --system --home /etc/scepproxy --shell /bin/false scepproxy
```

2. Give the scepproxy binary low port-binding capabilities

```sh
setcap CAP_NET_BIND_SERVICE=+eip $(which scepproxy)
```

3. Set the scepproxy user as the owner of your CA configuration directory:
```sh
chown -R scepproxy:scepproxy /etc/scepproxy
```


4. Create a */etc/systemd/system/scepproxy.service* unit file and add the content of [this](https://github.com/matteoraf/freeRADIUS-Google-StepCA/blob/main/scep-proxy/scepproxy.service) file (yes, I just took step-ca’s own file and changed some bits).
You’ll have to create a ***config.env*** file and place it in the */etc/scepproxy/* directory
You can see a sample config.env file [here](https://github.com/matteoraf/freeRADIUS-Google-StepCA/blob/main/scep-proxy/config.env), adjust it according to your needs.


5. Enable and start the service

```sh
# Reload the systemd unit files
systemctl daemon-reload

# Check the current status of the scepproxy service
systemctl status scepproxy

# Enable and start the scepproxy process
systemctl enable --now scepproxy
```


## Set up fail2ban 
I won’t go into too much detail about fail2ban. It’s been around for a long time and there are plenty of docs and articles about it.
I will just point out the configuration that we need to make it work.

We’ll need to configure a filter, a jail and an action.
To briefly explain this, the **jail** is where we tell fail2ban where to look for logs, what **filter** to use to identify logs that we care about, what **action** to execute and when to execute it.

You can find a [filter](https://github.com/matteoraf/freeRADIUS-Google-StepCA/blob/main/scep-proxy/fail2ban/scep-daemon.conf) and a [jail](https://github.com/matteoraf/freeRADIUS-Google-StepCA/blob/main/scep-proxy/fail2ban/jail.local) sample file in the git repo. I put instructions and explanations in the comments. 

## Set up with Cloudflare
I’ll just spend a couple more words on the cloudflare action instead.
The included [cloudflare.conf](https://github.com/fail2ban/fail2ban/blob/master/config/action.d/cloudflare.conf) applies the IP ban at the user level, that means that it’ll apply to all zones/sites that you have under your account.
In order to only apply to a specific zone, you can edit the [_cf_api_url](https://github.com/fail2ban/fail2ban/blob/bcaf1e714e7a9006677f841af0f3802a3b5419ca/config/action.d/cloudflare.conf#L67C52-L67C56) variable from this:

`https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules`

to this (add your own ZONE_ID):

`https://api.cloudflare.com/client/v4/zones/ZONE_ID/firewall/access_rules/rules`
 
One more thing that you need to do, is to have a file containing the list of subnets which Cloudflare uses.
Luckily for us, Cloudflare publishes it’s IP list at the following two endpoints:

https://www.cloudflare.com/ips-v4

https://www.cloudflare.com/ips-v6

Getting the file we need, is as simple as running the following command:

```sh
wget -O /etc/scepproxy/cloudflareips https://www.cloudflare.com/ips-v4 && echo "" >> /etc/scepproxy/cloudflareips &&  wget -O - https://www.cloudflare.com/ips-v6 >> /etc/scepproxy/cloudflareips
```

You can set up a cron job to run this for you once a day, so that you always have the updated IPs.


## Set up your firewall to only accept connections from Cloudflare IPs
This is just a recommendation, but it is out of the scope of this document as each firewall is different.