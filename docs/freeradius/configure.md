---
layout: default
title: Configure Freeradius
parent: Radius
nav_order: 3
---

# Configure Freeradius
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Configure Clients

<span style="text-decoration:underline;">/etc/freeradius/clients.conf</span>

The only really required settings (in a standard configuration) are the ip address(es) for your NAS (Network Access Server, for example it could be your access point) and the secret.

```
{% raw %}
client <name> {
        ipaddr = <CIDR for your subnet or specific IP>
        secret = <a strong password>
}
{% endraw %}
```


## Configure radiusd

<span style="text-decoration:underline;">/etc/freeradius/radiusd.conf</span>

The only change that we’ll do to this file, is to disable proxying requests, since we don’t need that.

```
{% raw %}
#
#  To disable proxying, change the "yes" to "no", and comment the
#  $INCLUDE line.
#
#  allowed values: {no, yes}
#
proxy_requests  = no
#$INCLUDE proxy.conf
{% endraw %}
```



## Configure Modules and Site

### Modules and Sites to enable

For our use case, this is the list of modules and sites needed.

```
{% raw %}
/etc/freeradius/
|-- mods-enabled
|   |-- always -> ../mods-available/always
|   |-- attr_filter -> ../mods-available/attr_filter
|   |-- cache_auth -> ../mods-available/cache_auth
|   |-- date -> ../mods-available/date
|   |-- detail -> ../mods-available/detail
|   |-- detail.log -> ../mods-available/detail.log
|   |-- eap -> ../mods-available/eap
|   |-- expr -> ../mods-available/expr
|   |-- ldap_google -> ../mods-available/ldap_google
|   |-- linelog -> ../mods-available/linelog
|   |-- preprocess -> ../mods-available/preprocess
|   |-- unpack -> ../mods-available/unpack
|   `-- utf8 -> ../mods-available/utf8
|-- sites-enabled
|   `-- default -> ../sites-available/default
|   
[...]
{% endraw %}
```

To enable a module or a site, you simply create a symbolic link in either the mods-enabled/ or sites-enabled/ directory.

For example, to enable the eap module, run this from within the ***mods-enabled/*** directory:

```sh
{% raw %}
ln -s ../mods-available/eap eap
{% endraw %}
```


### Configure eap module

<span style="text-decoration:underline;">/etc/freeradius/mods-available/eap</span>

We only need eap-tls, so the first thing we do is:

```
{% raw %}
set default_eap_type = tls
{% endraw %}
```

You can delete (or comment out) all other eap types (md5, pwd, gtc, ecc). Just leave tls.

The next thing we have to do is to configure some tls details.

We need to tell the module where our server certificate and key are located and what is the password to decrypt the key (we set it within /etc/freeradius/certs/server.cnf).

By default, freeradius uses the same file (server.pem) to store both the certificate and the key.

In our case, the key is in a separate file (server.key)

```
{% raw %}
private_key_password = mystrongkeypassword
private_key_file = ${certdir}/server.key
certificate_file = ${certdir}/server.pem
{% endraw %}
```

Comment out the *ca_file* variable, we’ll have openssl look for all certificates stored in *ca_path* (by default is */etc/freeradius/certs* for debian).

```
{% raw %}
#ca_file = ${cadir}/ca.pem
ca_path = ${cadir}
{% endraw %}
```

In case you have properly set up Active Revocation with CRL, you can set freeradius to check CRL for expired certificates by setting 
```
{% raw %}
check_crl = yes
check_all_crl = yes
{% endraw %}
```

Be careful with this, if radius cannot reach your CRL or if your CRL expires, it will reject all your clients.


### Configure ldap_google module

<span style="text-decoration:underline;">/etc/freeradius/mods-available/ldap_google</span>

We will use this module only to authorize our users, not to authenticate them.

There’s a subtle difference. 

Within the authorize section, we will only check if the user exists in our Google Directory and retrieve some information.

The ldap authentication process instead requires the user to provide their password and use the provided credentials to bind as the user. 

We don’t need to authenticate the users using ldap, we already know that we can trust the username stored in the certificate that they offer. The only way they can obtain a certificate is to connect to our SCEP server and the only way to connect is to have a configuration profile that we have pushed which includes their username.

So the only thing we need is to check that the user still exists in our directory and retrieve the information we need (for example, the VLAN id).

To do this, we have to [set up an ldap client](https://support.google.com/a/topic/9173976) from our Google Admin console, save our credentials and download the certificate-key pair, which freeradius will use to authenticate and bind as admin to Google’s ldap instance.

We then go to set up the connection: 

```
{% raw %}
       #  The server URL is standard, no need to chance it
        server = 'ldaps://ldap.google.com:636/'

        #  Google LDAP client username and password as generated during
        #  client creation.
        identity = 'Username'
        password = 'Password'

        #  The primary domain of your organization (let's say is domain.com)
        base_dn = 'dc=domain,dc=com'
{% endraw %}
```

Let’s go down to the *tls* section now to tell it where to find our certificate-key pair

```
{% raw %}
        tls {
                #  By default ${certdir} is raddb/certs/.  You can
                #  please these files anywhere you want. The only
                #  requirement is that they are readable by
                #  FreeRADIUS, and NOT readable by anyone else on the
                #  system!
                #
                certificate_file = ${certdir}/google/certificate.crt
                private_key_file = ${certdir}/google/key.key
                require_cert    = 'allow'
        }
{% endraw %}
```

Now we can configure any attributes that we need to retrieve from ldap.

In my case, I set a custom attribute for each user where I store the VLAN id. I called this attribute _vlan-id_.

This is how you retrieve this attribute. I added this to the [*control* list](https://wiki.freeradius.org/guide/List-Usage), because I want to cache this attribute, so that after we can retrieve it and add it to the _reply_ list. I strongly recommend to cache ldap responses, because Google’s ldap is not fast (see below).

```
{% raw %}
        update {
                control:Tunnel-Private-Group-ID := 'vlan-id'
                control:                        += 'radiusControlAttribute'
                request:                        += 'radiusRequestAttribute'
                reply:                          += 'radiusReplyAttribute'
        }
{% endraw %}
```

### Configure cache_auth module

<span style="text-decoration:underline;">/etc/freeradius/mods-available/cache_auth</span>

So, this module will help us to cache ldap responses.

This way, after the first bind, freeradius won’t need to contact Google again to authorize the user and retrieve any attributes and this will make the whole process A LOT faster.

Look for the _cache_auth_accept_ section and set the attributes that you want to be cached after a successful bind in the _update_ section.

```
{% raw %}
cache cache_auth_accept {
        driver = "rlm_cache_rbtree"
        key = "%{md5:%{%{Stripped-User-Name}:-%{User-Name}}%{User-Password}}"
        ttl = 7200
        update {
            &control:Tunnel-Private-Group-Id := &control:Tunnel-Private-Group-Id
        }
}
{% endraw %}
```

### Configure default site

<span style="text-decoration:underline;">/etc/freeradius/sites-available/default</span>

It’s now time to configure our site. You can use the default site and edit it.

There are 4 sections we care about for our use case:

- listen
- authorize
- authenticate
- post-auth


The **listen** section tells the server what to listen and where to listen for it.

You can keep the settings as in the default site.

The **authorize** section is where we check if we want to keep going with the client and we set the authentication method.
```
{% raw %}
autorize {
        
       #  Sanitize username and request content
       filter_username
       preprocess

       #  Split up user names in the form user@domain
       split_username_nai

	#
	#  Check the authentication cache to see if this user
	#  recently sucessfully authenticated
	#
	update control {
		&Cache-Status-Only := 'yes'
	}
	cache_auth_accept

	#
	#  If there's a cached User-Name, we can skip ldap
	#  Otherwise, we go through it (and cache the result)
	#
	if (notfound) {
                ldap_google
                if (updated) {
                        cache_auth_accept
                }
	}

        #  Reject if user doesn't exist
        if (notfound) {
                reject
        }

        #  We can do additional checks on the user domain
	if (&Stripped-User-Domain != 'domain.com') {
		reject
	}

       #
       #  If we got here, it means that the user exists and
       #  is authorized. Let's go on with eap.
       #  
       eap {
               ok = return
               updated = return
       }
}
{% endraw %}
```

Next is the **authentication** section. It’s very easy, we just need to enable eap authentication and the server will know what to do
```
{% raw %}
authenticate {
	#  Allow EAP authentication.
	eap
}
{% endraw %}
```

In **post-auth** we do some final checks, cache (or retrieve) user information and update the reply to set the VLAN id.

Anything after the *update reply* block is the existing post-auth section content for the default site.

```
{% raw %}
post-auth {
        #
        #  Reject packets where User-Name != TLS-Client-Cert-Common-Name
        #  There is no reason for users to lie about their names.
        #
        verify_tls_client_common_name

        #
        #  Retrieve/Cache info
        #
        cache_auth_accept
        
#
        #  Update reply with VLAN information
        #
        update reply {
                Tunnel-Type := 13
                Tunnel-Medium-Type := 6
                # In case no VLAN is assigned from ldap or from cache,  we assign a guest VLAN
                &reply:Tunnel-Private-Group-ID = "%{%{control:Tunnel-Private-Group-Id}:-100}"
        }


	#
	#  The session-state attributes are automatically deleted after
	#  an Access-Reject or Access-Accept is sent.
	#
		if (session-state:User-Name && reply:User-Name && request:User-Name && (reply:User-Name == request:User-Name)) {
		update reply {
			&User-Name !* ANY
		}
	}
	update {
		&reply: += &session-state:
	}

	#  Remove reply message if the response contains an EAP-Message
	remove_reply_message_if_eap

	
	Post-Auth-Type REJECT {
		attr_filter.access_reject
		eap
		remove_reply_message_if_eap
	}

	
	Post-Auth-Type Challenge {
#		remove_reply_message_if_eap
#		attr_filter.access_challenge.post-auth
	}

	
	#  If the client sends EAP-Key-Name in the request,
	#  then echo the real value back in the reply.
	#
	if (EAP-Key-Name && &reply:EAP-Session-Id) {
		update reply {
			&EAP-Key-Name := &reply:EAP-Session-Id
		}
	}
}
{% endraw %}
```

There are other sections which are a bit less critical for our use case, leave them there like this.

```
{% raw %}
#
#  Pre-accounting.  Decide which accounting type to use.
#
preacct {
        preprocess
        #
        #  Ensure that we have a semi-unique identifier for every
        #  request, and many NAS boxes are broken.
        acct_unique
}
#
#  Accounting.  Log the accounting data.
#
accounting {
        detail
        #  Filter attributes from the accounting response.
        attr_filter.accounting_response
}
session {
}
{% endraw %}
```