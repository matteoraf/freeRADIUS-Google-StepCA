---
layout: default
title: Certificates
parent: Radius
nav_order: 2
---

# Certificates
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

The next step is to set up certificates.

We won’t use freeradius bundled openssl to generate our PKI, we already have our own.

Here are all the steps involved:

1. Add and configure the ACME provisioner to the Intermediate CA
2. Install step cli tool on the freeradius instance and “connect” it to our intermediate
3. Create a template for the server certificate
4. Request a certificate using ACME
5. Set up [automated renewal](https://smallstep.com/docs/step-ca/renewal/#automated-renewal) with systemd timers

Before we start, we need to provide our radius server the “full chain of trust”, that means providing all the intermediates to build back the chain until the root CA.

In short, we need to copy over the certs for our **root CA**, the **intermediate CA** which will sign the radius server cert and the **intermediate CA** used for **SCEP** client certificates.

Put all these certs in the */etc/freeradius/certs/* folder.


## Add and configure the ACME provisioner to the Intermediate CA

Let’s now set up the ACME provisioner on our intermediate CA.

We are going to use the most simple challenge available (http-01), which is safe enough since we are on an internal domain and we are controlling DNS.

What that means is that our radius server, to prove its identity, needs to make a specific file available at a specific location on its web server. 

The step client will take care of this by itself.

Here’s our command on the intermediate:

```sh
{% raw %}
step ca provisioner add <name> --type=ACME --force-cn --challenge=http-01
{% endraw %}
```

Here’s the[ schema](https://smallstep.com/docs/step-ca/provisioners/#acme) if you prefer to manually edit your ca.json file.


## Install step cli tool on the freeradius instance and “connect” it to our intermediate

Now let’s head over to our radius server and install the step command tool (check for the latest version available first and adjust the command accordingly).

```sh
{% raw %}
wget https://github.com/smallstep/cli/releases/download/v0.24.4/step-cli_0.24.4_amd64.deb
dpkg -i step-cli_0.24.4_amd64.deb
{% endraw %}
```

Let’s [bootstrap](https://smallstep.com/docs/step-cli/reference/ca/bootstrap/) the connection with the CA 
```sh
{% raw %}
step ca bootstrap --ca-url [CA URL] --fingerprint [CA fingerprint]
{% endraw %}
```


## Create a template for the server certificate

Head back to your intermediate CA and create the _$STEPPATH/templates/certs/x509_ directory. 

When you’re into the selected directory, run:
```sh
{% raw %}
cat <<EOF > server_leaf.tpl
{
	"subject": {
        "country": "US",
        "organization": "My Org",
        "commonName": {{ toJson .Subject.CommonName }}
        },
	"sans": {{ toJson .SANs }},
	"keyUsage": ["keyEncipherment", "digitalSignature"],
	"extKeyUsage": ["serverAuth", "clientAuth"],
	"policyIdentifiers" : ["1.3.6.1.4.1.40808.1.3.2"]
}
EOF
{% endraw %}
```

Notice that we leave both the serverAuth and clientAuth keys, otherwise we won’t be able to renew this cert as the ACME client will use that same cert to authenticate as a CLIENT to the ACME server. If we only authorize this as a server certificate, the ACME server will refuse to establish a TLS connection with the client and won’t renew the certificate.

To know more about the policyIdentifiers object that we added, read [here](https://github.com/FreeRADIUS/freeradius-server/blob/master/raddb/certs/xpextensions).

Country and Organization are not mandatory, I just like to have them there, but feel free to skip them or to add more properties. Just be aware that the ACME provisioner doesn’t support the *–set* and *–set-file* keys, so you can’t set those variables with the request.

Now we need to add this template to our provisioner
```sh
{% raw %}
step ca provisioner update acme --x509-template=$(step path)/templates/certs/x509/server_leaf.tpl
{% endraw %}
```

Otherwise you can, as usually, edit the ca.json config file. Find the options key inside the ACME provisioner and edit it to look like this:
```json
{% raw %}
"options": {
    "x509": {
        "templateFile": "templates/certs/x509/server_leaf.tpl"
    },
    "ssh": {}
}
{% endraw %}
```

Just be aware that in this case, all servers using this provisioner, will get a certificate based upon this template.


## Request a certificate using ACME

Ok, it’s time to get our certificate. Head back to your freeradius server and put the password you’ve chosen (a strong one, as always) for your private key in a txt file.

Now run the following command.
```sh
{% raw %}
step ca certificate <common_name> \
/etc/freeradius/certs/server.pem \
/etc/freeradius/certs/server.key \
--provisioner=acme --kty=RSA \
--password-file password_file.txt
{% endraw %}
```

Use your FQDN as commonName for this cert.

And now we have obtained a server.pem certificate for our radius server.

There are just two steps that we need to take:

Adjust the file permissions:
```sh
{% raw %}
chmod g+r server.pem server.key
{% endraw %}
```

Create symbolic links for all your certs using their hashed values as file names. This is as simple as running the c_rehash command:
```sh
{% raw %}
c_rehash /etc/freeradius/certs/
{% endraw %}
```

The purpose of this is to allow the ssl library to find the required public_key in the certificate folder whenever it needs to verify a chain.


## Renew a Certificate using ACME

Renewing a certificate is done with the following command
```sh
{% raw %}
step ca renew /etc/freeradius/certs/server.pem /etc/freeradius/certs/server.key -f
{% endraw %}
```

After this we’d have to rehash the certificate and restart freeradius.

Of course we don’t really want to bother doing this manually every time, let’s follow the [smallstep guide](https://smallstep.com/docs/step-ca/renewal/#automated-renewal) to automate all of this using systemd timers.

First of all, the cert renewer service.

Head to ***/etc/systemd/system/*** and create the ***cert-renewer@.service*** file

Put [this](https://github.com/smallstep/cli/blob/master/systemd/cert-renewer%40.service) in your file and save it.

Next step is to create an override file specific for freeradius.

Let’s first create the ***/etc/systemd/system/cert-renewer@freeradius.service.d/*** directory.

Create an override.conf file in that directory and add this content to the file.
```sh
{% raw %}
[Service]
Environment=CERT_LOCATION=/etc/freeradius/certs/server.pem \
            KEY_LOCATION=/etc/freeradius/certs/server.key

ExecStartPost=
ExecStartPost=/usr/bin/c_rehash /etc/freeradius/certs/
ExecStartPost=/usr/bin/env sh -c "! systemctl --quiet is-active %i.service || systemctl restart %i"
{% endraw %}
```

In case your files are in a different directory or have a different name, adjust the file accordingly. Be sure to check STEPPATH as well, in my case it was in my home directory.

The reason why we are restarting the freeradius service is to pick up the new certificate. A simple reload (SIGHUP) won’t load the certificate.

Last step is to create and start the timer.

Create the ***/etc/systemd/system/cert-renewer@.timer*** file and paste [this](https://github.com/smallstep/cli/blob/master/systemd/cert-renewer%40.timer) in.

Now save the file and run this command to enable the timer for our service:

```sh
{% raw %}
systemctl enable --now cert-renewer@freeradius.timer
{% endraw %}
```

And, we’re done. Our server certificate (which by default is valid for 24hours only) will automatically renew around 8 hours before its expiration.

