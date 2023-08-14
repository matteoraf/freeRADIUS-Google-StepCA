---
layout: default
title: Run Step as a Daemon
parent: Smallstep
nav_order: 4
---

# Run Step as a Daemon
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

Running step as a daemon is a recommended approach for production environments.

Running in foreground is ok for testing and debugging, but once you’re ready to deploy, you should really go the systemd way.

The guys at smallstep already explained everything [on the documentation](https://smallstep.com/docs/step-ca/certificate-authority-server-production/#running-step-ca-as-a-daemon), I will just copy-paste everything here for convenience.

## Add a service user for the CA

```sh
{% raw %}
useradd --system --home /etc/step-ca --shell /bin/false step
{% endraw %}
```
## Give the step-ca binary low port-binding capabilities

```sh
{% raw %}
setcap CAP_NET_BIND_SERVICE=+eip $(which step-ca)
{% endraw %}
```
## Move your CA configuration into a system-wide location

```sh
{% raw %}
mv $(step path) /etc/step-ca
{% endraw %}
```
Make sure your CA password is located in _/etc/step-ca/password.txt_, so that it can be read upon server startup.

## Edit your config files to reflect the new steppath.

```sh
{% raw %}
sed -i "s|$(step path)|/etc/step-ca|g" /etc/step-ca/config/ca.json
sed -i "s|$(step path)|/etc/step-ca|g" /etc/step-ca/config/default.json
{% endraw %}
```
## Set the step user as the owner of your CA configuration directory:

```sh
{% raw %}
chown -R step:step /etc/step-ca
{% endraw %}
```
## Create a _/etc/systemd/system/step-ca.service_ unit file and add the content of [this](https://github.com/smallstep/certificates/blob/master/systemd/step-ca.service) file

## Enable and start the service

```sh
{% raw %}
# Rescan the systemd unit files
systemctl daemon-reload

# Check the current status of the step-ca service
systemctl status step-ca

# Enable and start the `step-ca` process
systemctl enable --now step-ca
{% endraw %}
```