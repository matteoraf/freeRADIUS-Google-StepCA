---
layout: default
title: Useful SSL Commands
parent: Bonus content
nav_order: 1
---

# Useful SSL Commands
{: .no_toc }

---

Here are some commands you may find useful while dealing with certificates and related stuff

**Convert certs from PEM to DER**

```sh
openssl x509 -inform PEM -in cert.crt -outform DER -out cert.der
```

**Convert certs from DER to PEM**
```sh
openssl x509 -inform DER -in cert.der -outform PEM -out cert.pem
```

**Verify chain of trust**
```sh
openssl verify -CAfile ca.cer certificate_to_verify.crt
```

or
```sh
step certificate verify certificate_to_verify.crt --roots=ca.cer
```

**Bundle public and private key in a p12 file**
```sh
openssl pkcs12 -export -in public.crt -inkey private.key -out bundle.p12  -passin pass:<passin> -passout pass:<passout>
```

**Export certificate and key from a p12 file**
```sh
openssl pkcs12 -in bundle.p12 -out public.pem -nokeys
```

```sh
openssl pkcs12 -in bundle.p12 -out private.key -nodes -nocerts
```

**Inspect certificate (read content)**
```sh
openssl x509 -in certificate.pem -noout -text
```

or
```sh
step certificate inspect certificate.pem
```

**Get the Fingerprint hash (SHA-1 or MD5 or SHA256) of a certificate**
```sh
step certificate fingerprint --insecure --sha1 certificate.pem
```

or
```sh
openssl x509 -noout -fingerprint -sha1 -inform pem -in certificate.pem
```

or
```sh
openssl x509 -noout -fingerprint -md5 -inform pem -in certificate.pem
```

