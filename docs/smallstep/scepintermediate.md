---
layout: default
title: Create Intermediate for SCEP
grand_parent: Smallstep
nav_order: 2
parent: Intermediate CAs
permalink: /docs/smallstep/intermediate/scep
---

# Create Intermediate for SCEP
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

The process is very similar to the previous one.

Here’s what we will do, in order:



1. Initialize PKI
2. Remove both root and intermediate keys and certificates
3. Copy our existing root certificate to the our PKI (not the private key, just the cert)
4. Generate a CSR (Certificate Signing Request) for the new Intermediate CA, to be signed by our offline root, with the settings and parameters that we need (RSA key signing, Active revocation with CRL, policies)
5. Set up Active Revocation
6. Set up Policies
7. Add SCEP Provisioner

Steps 1 to 6 are exactly the same as per the other Intermediate, so I will not copy-paste everything here.

There is just one IMPORTANT difference, that’s the ***keyUsage*** of the CA.

You can read more about that [here](https://github.com/smallstep/certificates/issues/746#issuecomment-971118574).
The important thing to know is that we’ll need a slightly different template for the SCEP CA.

Notice the difference in the **_<span style="text-decoration:underline;">keyUsage</span>_** key.


```sh
{% raw %}
cat <<EOF > rsa_SCEP_intermediate_ca.tpl
{
	"subject": {{ toJson .Subject }},
	"keyUsage": ["certSign", "crlSign", "digitalSignature", "keyEncipherment"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
      "crlDistributionPoints": ["http://ca.example.com/crl"]
}
EOF
{% endraw %}
```


Let me just quote the explanation for this requirement:

*<<Since the client is expected to perform signature verification and optionally encryption using the CA certificate, the keyUsage extension in the CA certificate MUST indicate that it is valid for digitalSignature and keyEncipherment (if the key is to be used for en/decryption) alongside the usual CA usages of keyCertSign and/or cRLSign.>>*

So, just use this template for the intermediate CA and follow steps from 1 to 6 as per the previous chapter, then come back for policies and provisioners.


## Set up Policies

We may want to limit certificate issuance to a specific email domain, in this case we can set this as a policy on our intermediate.

{: .ref }
[Policies](https://smallstep.com/docs/step-ca/policies/#domain-names)

If you have enabled the [remote management](https://smallstep.com/docs/step-ca/provisioners/#remote-provisioner-management), you can do:

```sh
{% raw %}
step ca policy authority x509 allow dns "step"
step ca policy authority x509 allow email "@example.com"
{% endraw %}
```

Otherwise you have to [manually edit the ca.json configuration file](https://smallstep.com/docs/step-ca/policies/#policy-in-configuration-file).

The “policy” object sits inside the “authority” object:

```json
{% raw %}
"policy": {
    "x509": {
        "allow": {
            "email": ["@example.com"]
        },
        "deny": {
            "email": ["@forbidden.example.com"],
        },
        "allowWildcardNames": false,
    }
}
{% endraw %}
```

## Add SCEP Provisioner

{: .ref }
[Configure SCEP Provisioner](https://smallstep.com/docs/step-ca/provisioners/#scep)

With provisioners (unlike policies), you can use the step ca command locally even if remote-management is not enabled:

```sh
{% raw %}
step ca provisioner add my_scep_provisioner \
  --include-root \
  --force-cn \
  --type SCEP \
  --challenge "secret1234" \
  --encryption-algorithm-identifier 2
{% endraw %}
```

It is very important to set the *--include-root* key if we need to use this with Apple devices. 

[Here's](https://smallstep.com/docs/step-cli/reference/ca/provisioner/add/) the list of available options for this command

```sh
{% raw %}
step ca provisioner add <name> --type=SCEP [--force-cn] [--challenge=<challenge>]
[--capabilities=<capabilities>] [--include-root] [--min-public-key-length=<length>]
[--encryption-algorithm-identifier=<id>]
[--admin-cert=<file>] [--admin-key=<file>]
[--admin-subject=<subject>] [--admin-provisioner=<name>] [--admin-password-file=<file>]
[--ca-url=<uri>] [--root=<file>] [--context=<name>] [--ca-config=<file>]
{% endraw %}
```

But we even still can manually edit the _ca.json_ configuration file:
```json
{% raw %}
{
    "type": "SCEP",
    "name": "my_scep_provisioner",
    "forceCN": true,
    "challenge": "secret1234",
    "minimumPublicKeyLength": 2048,
    "includeRoot": true,
    "encryptionAlgorithmIdentifier": 2,
}
{% endraw %}
```

You can find all the details about the available options on the page linked above, but anyway, here’s a brief explanation from step documentation:



* The <span style="text-decoration:underline;">forceCN</span> parameter is optional. If true, forces one of the SANs to become the Common Name, if a common name is not provided. It defaults to false.
* <span style="text-decoration:underline;">challenge</span> is the secret shared between the provisioner and SCEP clients. By default no secret is used. Hint: use a very strong key for this, as anyone guessing this key could be able to obtain a certificate from your CA.
* The <span style="text-decoration:underline;">minimumPublicKeyLength</span> parameter can be used to set the minimum length of public keys submitted by a client. Defaults to 2048.
* When <span style="text-decoration:underline;">includeRoot</span> is set to true, the root CA certificate will be returned in responses to GetCACert requests in addition to the intermediate CA certificate. This option was added to support a specific use case for the macOS SCEP client (see [certificates#746](https://github.com/smallstep/certificates/issues/746) for more details). Defaults to false.
* The <span style="text-decoration:underline;">encryptionAlgorithmIdentifier</span> parameter can be used to change the [encryption algorithm](https://github.com/smallstep/pkcs7/blob/33d05740a3526e382af6395d3513e73d4e66d1cb/encrypt.go#L63) used for encrypting the request content. Defaults to 0: DES-CBC for legacy compatibility.

In case your SCEP client uses HTTP (and does not support HTTPS), we need to add an additional bit on our CA configuration, to enable the “insecure” endpoint to be served.

This is not a big deal, since all PKIOperations messages are encrypted, but it’s good to have another layer of encryption on top if you can afford it.

```
 {% raw %}
        ...
        "insecureAddress": ":8080",
        ...
 {% endraw %}
```

Let’s now create a template for our SCEP profile

```
{% raw %}
{
	"subject": {
    "commonName": {{ toJson .Subject.CommonName }},
    "country": {{ toJson .country }},
    "organization": {{ toJson .organization }}
  },
  "emailAddresses": {{ toJson .Insecure.CR.EmailAddresses }},
	"sans": {{ toJson .SANs }},
	"keyUsage": ["keyEncipherment", "digitalSignature"],
	"extKeyUsage": ["clientAuth"]
}
{% endraw %}
```

And add it to the options for the existing scep provisioner 

```sh
{% raw %}
step ca provisioner update my_scep_provisioner --x509-template="$(step path)/templates/certs/default_scep_leaf.tpl" --x509-template-data="{ "organization": Corp, "country": US}"
{% endraw %}
```

If you want to manually edit config, here’s the schema:

```json
{% raw %}
  "options": {
    "x509": {
      "templateFile": "templates/certs/x509/default_scep_leaf.tpl",
      "templateData": {
        "organization": "Corp",
        "country": "US",
      }
    },
{% endraw %}
```

Organization and Country are not mandatory, it's just a nice addition.

You can now start (or reload) your CA.