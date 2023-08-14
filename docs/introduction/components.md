---
layout: default
title: The Components
parent: Introduction
nav_order: 2
---

# The Components
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

Here’s what we’ll need:

## [Smallstep step-ca](https://smallstep.com/certificates/)

Step-ca is an open source Certificate Authority which makes setting up an online PKI a breeze.

If you ever tried to do that using openssl and other tools, you know how hard it could be and how easy it is to lose control of it.

Step-ca does provide an easy to use interface (not a UI) and tools to interact with the CA and takes care of the underlying architecture to make it work, be secure and stay online.


## [FreeRADIUS](https://freeradius.org/)

If you ask about an open source RADIUS server, then freeRADIUS will be the answer.

It is a de-facto standard for open source RADIUS implementations.

It isn’t very easy to understand, but I will try to explain and document all the steps involved.

## Google Workspace

I have access to a Google Workspace instance with Enterprise licensing, so it includes Secure LDAP as a service.

This is not mandatory of course, you can just skip that part in the freeRADIUS configuration.

But in my case, I use it to both authorize users and get the VLAN they’re assigned to using a custom attributes on their profile (more about this later)

## MDM platform

This is not mandatory as well, you can manually install profiles and root certificates on your devices, but MDM makes it a lot easier and better managed and it’s the only way to make all the process transparent to the end user.

MicroMDM is an open source MDM implementation, but this is not something I will deal with in this document, so in case you don’t want to learn that, you may also consider Mosyle which is not open source but has a free tier as well.