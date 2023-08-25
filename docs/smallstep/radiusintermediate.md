---
layout: default
title: Create Intermediate CA for Server Certificates (eg. Radius Server)
grand_parent: Smallstep
nav_order: 1
parent: Intermediate CAs
permalink: /docs/smallstep/intermediate/server
---

# Create Intermediate CA for Server Certificates (eg. Radius Server)
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

What we will do, in order:



1. Install step CLI tool and step-ca (see first page)
2. Initialize PKI
3. Remove both root and intermediate keys and certificates
4. Copy our existing root certificate to the our PKI (not the private key, just the cert)
5. Generate a CSR (Certificate Signing Request) for the new Intermediate CA, to be signed by our offline root, with the settings and parameters that we need (RSA key signing, Active revocation with CRL, etc)
6. Set up Active Revocation
7. Set up Policies


## Inizialize PKI

{: .ref }
> [step ca init](https://smallstep.com/docs/step-cli/reference/ca/init/)
>
> [Getting started](https://smallstep.com/docs/step-ca/getting-started/#initialize-your-certificate-authority-ca)

After having installed the required tools, it's time to init our CA.
This will create a boilerplate which we'll use as our base to build our CA.

```sh
{% raw %}
step ca init \
--deployment-type=standalone \
--name="Example Intermediate CA" \
--dns="ca.example.com" \
--address=":443" \
--provisioner="admin@example.com" \
--provisioner-password-file=<file> \
--password-file=<file>
{% endraw %}
```


Let’s go through all required informations:



* **_<span style="text-decoration:underline;">--deployment-type=standalone</span>_** we don’t need to connect to any cloud services, so we select this mode
* **_<span style="text-decoration:underline;">--name=name</span>_** The name of the new PKI.
* **_<span style="text-decoration:underline;">--dns=name</span>_** The DNS name or IP address of the new CA. Use the '--dns' flag multiple times to configure multiple DNS names.
* **_<span style="text-decoration:underline;">--address=address</span>_** The address that the new CA will listen at.
* **_<span style="text-decoration:underline;">--provisioner=name</span>_** The name of the first provisioner (JWT).
* **_<span style="text-decoration:underline;">--provisioner-password-file=file</span>_** The path to the file containing the password to encrypt the JWT provisioner key.
* **_<span style="text-decoration:underline;">--password-file=file</span>_** The path to the file containing the password to encrypt the keys. We can skip this in this case, since we’ll delete these keys and re-generate the intermediate key after


## Remove both root and intermediate keys and certificates

As said, we just need the boilerplate to be in place, we don’t need any of the certs and keys generated here. We already have our own root, so we’ll delete everything.

```sh
{% raw %}
rm ~/.step/certs/* ~/.step/secrets/*
{% endraw %}
```


## Copy our existing root certificate to the our PKI (not the private key, just the cert)

I will use the scp command from my workstation, but you are free to use your preferred tool.

```sh
{% raw %}
scp user@root-ca:</path/to/your/existing/root.crt> user@intermediate-ca:/<path/to/step>/certs/
{% endraw %}
```

## Generate a CSR (Certificate Signing Request) for the new Intermediate CA

Generate a CSR (Certificate Signing Request) for the new Intermediate CA, to be signed by our offline root, with the settings and parameters that we need (RSA key signing, Active revocation with CRL, policies).

{: .ref }
[Intermediate CA, the Secure Way](https://smallstep.com/docs/tutorials/intermediate-ca-new-ca/#the-secure-way)

Let’s put together a template with all parameters that we need.

{: .ref }
[Configure step-ca with an RSA certificate chain](https://smallstep.com/docs/tutorials/rsa-chain/#instructions)

Note that we added the CRL distribution endpoint in our Intermediate CA configuration, read below for more information.

```sh
{% raw %}
cat <<EOF > rsa_intermediate_ca.tpl
{
	"subject": {{ toJson .Subject }},
	"keyUsage": ["certSign", "crlSign"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
      "crlDistributionPoints": ["https://ca.example.com/crl"]
}
EOF
{% endraw %}
```

{: .note }
From now on, we’ll skip the signatureAlgorithm statement from templates, if you need to use different algorithms, you know how do to it.

Now we are ready to create our CSR (certificate signing request), notice the _--csr_ option


```sh
{% raw %}
step certificate create "Example Intermediate CA" \
    intermediate_ca.csr \
    $(step path)/secrets/intermediate_ca_key \
    --csr \
    --template rsa_intermediate_ca.tpl \
    --password-file password_file.txt \
    --kty RSA \
    --size 3072
{% endraw %}
```


We can now move this CSR to our root and sign it.

In order to have all the X509v3 extensions, we have to move over the template as well (or we could recreate it on our root).

So once you have moved over everything, run this command from the environment where your root key pair lives.

{: .ref }
[step certificate sign](https://smallstep.com/docs/step-cli/reference/certificate/sign/index.html)


```sh
{% raw %}
step certificate sign \
    intermediate_ca.csr \
    <path_to_root_crt>/root.crt \
    <path_to_root_key>/root.key \
    --template rsa_intermediate_ca.tpl \
    --password-file password_file.txt \
    --not-after 87660h \
    > intermediate_ca.crt
{% endraw %}
```


We can now move back the signed certificate to our intermediate CA.

```sh
{% raw %}
scp user@root-ca:<path>/intermediate_ca.crt user@intermediate-ca:/root/.step/certs/
{% endraw %}
```

## Set up Active Revocation

Now it’s time to configure active revocation.

{: .ref }
[Enable active revocation on your intermediate ca](https://smallstep.com/docs/step-ca/certificate-authority-server-production/#enable-active-revocation-on-your-intermediate-ca) &lt;- this doc is outdated, you can find more details [here](https://github.com/smallstep/certificates/discussions/1422) while we wait for it to be updated

We have already set in the intermediate ca template, our CRL distribution point at "[http://ca.example.com/crl](http://ca.example.com/crl)".

The only thing you need to do, in order to enable the CRL, is to edit your ca.json file and add the following configuration:

```json
{% raw %}
"crl": { "enabled": true }
{% endraw %}
```

There are a few more options you can add, for sure I’d suggest you to enable the _GenerateOnRevoke_ option. The other options are dependent on your specific needs.

Check [this post](https://github.com/smallstep/certificates/issues/1423#issuecomment-1581568312) for more information.

**_GenerateOnRevoke:_** if set to true, the CRL is generated any time you revoke a certificate

**_CacheDuration:_** set the validity of the CRL (default to 24h)

**_RenewPeriod:_** set how frequently to renew the CRL (default to 16h)

**_IDPurl:_** (Issuing Distribution Point), it’s the url to reach the CRL, by default it will use your first DNS Name and make it available at the <span style="text-decoration:underline;">/crl</span> endpoint


## Run your CA

This is as easy as:
```sh
{% raw %}
step-ca $(step path)/config/ca.json
{% endraw %}
```

## Set up Polices

We may want to limit certificate issuance to a specific domain or IP, in this case we can set this as a policy on our intermediate.

{: .ref }
[Policies](https://smallstep.com/docs/step-ca/policies/#domain-names)

If you have enabled the [remote management](https://smallstep.com/docs/step-ca/provisioners/#remote-provisioner-management), you can run the following commands:

```sh
{% raw %}
step ca policy authority x509 allow dns "step" 
step ca policy authority x509 allow dns "*.local.example.com"
step ca policy authority x509 allow ip 10.0.0.0/24
{% endraw %}
```

Notice the first line, the purpose of this policy is to avoid locking you out, in fact the default name for the first JWT provisioner (which is created when you _init_ your step-ca) is indeed _step_.

Otherwise you can go the old school way, [manually editing the ca.json configuration file](https://smallstep.com/docs/step-ca/policies/#policy-in-configuration-file).

The “policy” object sits inside the “authority” object (policies can only be set at authority level and not at provisioner level):

```json
{% raw %}
"policy": {
    "x509": {
        "allow": {
            "dns": ["*.local.example.com"],
            "ip": ["10.0.0.0/24"]
        },
        "deny": {
            "dns": ["forbidden.local.example.com"],
            "ip": ["192.168.1.153"]
        },
        "allowWildcardNames": false,
    }
}
{% endraw %}
```