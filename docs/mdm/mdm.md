---
layout: default
title: MDM
nav_order: 5
has_children: false
permalink: /docs/mdm
---

# MDM

With all the infrastructure up and running, now it’s time to deploy everything to your devices.

I’m taking the MDM approach, but of course you can just manually install any configuration profile on your devices.

The only catch if you decide to not use an MDM (besides needing to have the devices in your hands) is that the root certificate needs to be manually trusted, while deploying it via MDM makes it trusted automatically.

Anyway, we simply need to do these things:

1. Deploy the Root CA
2. Deploy the SCEP configuration together with the WiFi one

If you’re using an MDM, they will probably allow you to build configuration profiles within their own environment.

But you are free to build your own configuration profile using tools like [Apple Configurator](https://apps.apple.com/it/app/apple-configurator/id1037126344?mt=12), [iMazing profile editor](https://imazing.com/profile-editor), or even with a plain text editor.

**Deploy Root CA cert to your device**

There’s no need to deploy the SCEP Intermediate CA cert, your device will download it from the SCEP server together with the identity certificate.

Put this in its own profile, don’t put this together with the SCEP and WiFi/VPN payloads, it will make things easier to manage when you’ll need to make some changes to your deployment.

We will use a Certificate profile, specifically with the [com.apple.security.root](https://support.apple.com/en-us/guide/deployment/dep91d2eb26/1/web/1.0) payload

Actually, there’s not much to configure for this profile.

You just give it a name, load in your root certificate and you’re done.

**Deploy the SCEP + WiFi profile to your device**

In this case, we’ll load both payloads into a single configuration profile.

The reason for this, is to be able to tell the WiFi config to pick up the identity from the SCEP payload. You won’t be able to do this if you put the two payloads into two separate profiles.

<span style="text-decoration:underline;">Let’s start with the [SCEP payload](https://support.apple.com/en-us/guide/deployment/dep495a6d79/1/web/1.0).</span>

See [here](https://developer.apple.com/documentation/devicemanagement/scep#3908435) an example of this payload.

Here are the important bits to set:

-<span style="text-decoration:underline;">URL</span>: the url to the SCEP endpoint

https://&lt;url-to-scep-ca>/scep/&lt;scep-provisioner-name>

-<span style="text-decoration:underline;">Subject</span>:

This is important, because that is where we get the username to check against Google LDAP.

Depending on your MDM provider, you may be able to use some variables, check their documentation for that.

For example, if you use Mosyle, you could set this to: _CN=%Email%_ to have the email of the user whom this device is assigned to as the Common Name of the identity certificate.

With Meraki System Manager, you’d instead use $OWNEREMAIL.

Check your MDM documentation for more information.

You are free to add any additional information like Country, Organization etc.

Just make sure that your Common Name is set to your user’s email.

-<span style="text-decoration:underline;">Challenge</span>: the password you set to the SCEP provisioner

-<span style="text-decoration:underline;">Keysize</span>: set this to 2048 bits

-<span style="text-decoration:underline;">Key Type</span>: you can only set this to RSA, as this is the only type supported by SCEP

-<span style="text-decoration:underline;">Key Usage</span>: set this to both Signing and Encryption

-<span style="text-decoration:underline;">CAFingerprint</span>: set this to the SHA1 or MD5 fingerprint of your SCEP CA

-<span style="text-decoration:underline;">KeyIsExtractable</span>: I’d recommend NOT to allow (it is allowed by default) the export of the key, otherwise users would be able to move their identity to whatever device they want.

Then we have our [Wifi Payload](https://support.apple.com/en-us/guide/deployment/dep1c4b37ac2/1/web/1.0)

See [here](https://developer.apple.com/documentation/devicemanagement/wifi#3915150) an example of this profile.

<span style="text-decoration:underline;">SSID_STR</span>: the name of your SSID

<span style="text-decoration:underline;">EncryptionType</span>: you want to set this to WPA2 or WPA3 (the former allows both WPA2 and 3, the latter just WPA3)

<span style="text-decoration:underline;">DisableAssociationMACRandomization</span>: I prefer to enable this, so that it’s easier to track devices on your network

<span style="text-decoration:underline;">EAPClientConfiguration</span>: this is the section where we set up EAP-TLS authentication

<span style="text-decoration:underline;">AcceptEAPTypes</span>: set this to 13 to enable EAP-TLS

<span style="text-decoration:underline;">TLSTrustedServerNames</span>: set this to the CommonName of your radius server cert

<span style="text-decoration:underline;">PayloadCertificateUUID</span>: this is where we put the UUID of the SCEP payload within the same profile, so that the eapol client knows what identity to use when connecting.