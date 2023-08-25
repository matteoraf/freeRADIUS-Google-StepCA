---
layout: default
title: Create the root key pair on an offline device
parent: Smallstep
nav_order: 2
---

# Create the root key pair on an offline device
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

I used a debian live image to do this, so that nothing is stored permanently.

When I shut it down, everything is gone. Of course, I will backup my keys somewhere safe.

You’re free to use whatever you prefer as your root CA, it can even be a completely separate and existing CA, but in this case we’ll do that using the step CLI tool.

Let’s start, here’s a list of the steps involved:

1. Install the step CLI tool (see previous step)
2. Create the template for our root certificate
3. Generate the certificate and the private key
4. Backup the private key and the certificate


## Create the template for our root certificate

{: .ref }
[Configure step-ca with an RSA certificate chain](https://smallstep.com/docs/tutorials/rsa-chain/#instructions)

Run this command to create the file:

```sh
{% raw %}
cat <<EOF > rsa_root_ca.tpl
{
	"subject": {{ toJson .Subject }},
	"issuer": {{ toJson .Subject }},
	"keyUsage": ["certSign", "crlSign"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 1
	}
	{{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
  	, "signatureAlgorithm": "SHA256-RSAPSS"
	{{- end }}
}
EOF
{% endraw %}
```

Let’s quickly go through the options here, but you can learn more about those [here](https://pkg.go.dev/go.step.sm/crypto/x509util#Certificate).



* _<span style="text-decoration:underline;">Subject</span>_: this is quite self explanatory, it’s the “entity” owning the certificate. A must have property for our use case is the Common Name. Other details are optionals (more info later on).
* _<span style="text-decoration:underline;">Issuer</span>_: since this is our Root CA, it is the same as the subject (Hint: root certs are self signed).
* _<span style="text-decoration:underline;">keyUsage</span>_: this tells what this certificate can be used for (in our case, to sign other certificates and to sign certificate revocation lists)
* _<span style="text-decoration:underline;">isCA</span>_: yes, this is a certificate authority, so we set this to true
* _<span style="text-decoration:underline;">maxPathLen</span>_: this tells how many levels of CA below us are allowed to exists. In this case, only one level is admitted, so we can have one layer of intermediate CAs below the root, but they are not allowed to sign other CA below them.

The last bit, as explained within the link at the beginning of this chapter, tells our CA to sign using the RSA key type, specifically using the _RSASSA-PSS key with a SHA256 digest._

{: .warning }

> It seems that MacOS and apple devices in general have some troubles dealing with certificates signed with RSASSA-PSS.
>
> In case your clients are using macOS (which I believe they are, if you’re reading this tutorial) then just use the default root-ca profile from step or remove the whole if statement from the custom template, it’ll sign the certificate using the RSASSA with SHA-256 scheme.


## Generate root CA Certificate

{: .ref }
[step certificate create](https://smallstep.com/docs/step-cli/reference/certificate/create/#options)

Let’s first put our very complex password (usa a password manager or _[/dev/urandom](https://cjbarker.com/blog/creating-high-entropy-passwords-on-linux/)_ to generate it), which will be used to encrypt the private key, on a file (eg. _password-file.txt_). We can then move this file to our CA and feed it to the step tool as follows.

```sh
{% raw %}
step certificate create "Example Root CA" \
    root_ca.crt \
    root_ca.key \
    --template rsa_root_ca.tpl \
    --password-file password_file.txt \
    --kty RSA \
    --not-after 87660h \
    --size 3072
{% endraw %}
```

Let’s briefly go through the options:



* The first (mandatory) one is our **_<span style="text-decoration:underline;">subject</span>_**, the name of our CA. In this case it is set to “Example Root CA”.
* Second and third (both mandatory) are the paths to store the **_<span style="text-decoration:underline;">public</span>_** and the **_<span style="text-decoration:underline;">private</span>_** keys.
* With the (optional) **_<span style="text-decoration:underline;">--template</span>_** option, we set the template to use for our certificate.
    * If you want to use one of the bundled templates you can use the **_<span style="text-decoration:underline;"> --profile</span>_** option instead, and then specify the profile name (eg. _--profile root-ca_)
* We then provide the password to encrypt the private key through a **_<span style="text-decoration:underline;">--password-file</span>_**.
* After, we tell it to use RSA as our key type with **_<span style="text-decoration:underline;">--kty</span>_** (we need this for SCEP).
* The last two options are the duration (**_<span style="text-decoration:underline;">--not-after</span>_**), which in this case is set to 10 years (expressed in hours) and the key **_<span style="text-decoration:underline;">--size</span>_**, which we set to 3072 bits.


## Bonus: add additional information

You are of course free to make it “nicer” by providing additional information, such as Country, Organization, etc.

To do so, you first need to add the required keys to your template.

```sh
{% raw %}
cat <<EOF > rsa_root_ca_xt.tpl
{
	"subject": {
	    "country": {{ toJson .Insecure.User.country }},
	    "organization": {{ toJson .Insecure.User.organization }},
	    "commonName": {{ toJson .Subject.CommonName }}
        },
	"issuer": {
        "country": {{ toJson .Insecure.User.country }},
        "organization": {{ toJson .Insecure.User.organization }},
        "commonName": {{ toJson .Subject.CommonName }}
        },
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 1
	},
	"keyUsage": ["certSign", "crlSign"]
	{{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
  	, "signatureAlgorithm": "SHA256-RSAPSS"
	{{- end }}
}
EOF
{% endraw %}
```

{: .note }

for the same reasons mentioned above, delete these 3 lines from the template if you’re using Apple devices

```sh
{% raw %}
	{{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
  	, "signatureAlgorithm": "SHA256-RSAPSS"
	{{- end }}
{% endraw %}
```

You then need to add the **_<span style="text-decoration:underline;">--set key=value</span>_** options to the **_<span style="text-decoration:underline;">create</span>_** command.


```sh
{% raw %}
step certificate create "Example Root CA" \
    root_ca.crt \
    root_ca.key \
    --template rsa_root_ca_xt.tpl \
    --password-file password_file.txt \
    --kty RSA \
    --not-after 87660h \
    --size 3072 \
    --set organization="Acme Corp" \
    --set country="US"
{% endraw %}
```



## Backup private key offline

Now we have our root certificate and private key.

Download and store the private key somewhere very very very [...] safe.

You cannot afford to lose it and you cannot afford to have someone else getting their hands on it.

Once we are done and we have signed our intermediates, we will shut down our vm or whatever you are using and will not touch it again until it’s time to renew or revoke an Intermediate CA or to create a new one.

Don’t forget to backup the password you used to encrypt the private key as well (possibly, not together with the key itself).