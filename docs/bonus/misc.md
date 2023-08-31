---
layout: default
title: Misc
parent: Bonus content
nav_order: 4
---

# Misc
{: .no_toc }

---

I left this last page as a "catch all".
I will add here notes that don't really belong in the previous pages and don't deserve a separate one.

## Skip SCEP

Ok, this won't be a long step by step, since I haven't set this up.
But since I started by saying that there are easy alternatives if you don't need/want to automate all of this and you don't care about requiring user interaction.

Well, in this case, my recommendation would be to skip the SCEP server and instead set up a script (or maybe some UI) to have the users get their identity certificate by logging in with your IdP using the [OIDC](https://smallstep.com/docs/step-ca/provisioners/#oauthoidc-single-sign-on) provisioner.

The downside is that you have no control on the devices getting the certificate, as long as the user can sign in, it will get a certificate. 
The other downside is that the user would have to select the correct certificate when connecting to your network for the first time.
The last downside, is that while this should be quite easy for MacOS, I believe it wouldn't be much easy on iOS and iPadOS.

## SCEP Renewal

So, since Apple [doesn't support](https://support.apple.com/en-us/HT204836) automatic renewal for SCEP certificates, we'll have to think a way to automate this.

The command to renew a SCEP certificate pushed with a configuration profile is `profiles renew -type configuration -identifier <profile_identifier>` 

The problem with this command is that the old profile will be left in the keychain, no cleanup is done.
So we need to work on something that will clean up expired or soon-to-expire certificates.

So, I came up with a script that checks for certificate approaching expiration, renews it and cleans up the leftover one(s).

You can find this script [here](https://github.com/matteoraf/freeRADIUS-Google-StepCA/blob/main/scripts/scep_renew_cleanup.sh).

Just set the  `PROFILE_IDENTIFIER`, `EXP_TRESHOLD` and `CN` variables and you're ready to go.

You can then push this script to devices at regular intervals with your MDM or just set up a cron on your device if you don't have access to an MDM platform.