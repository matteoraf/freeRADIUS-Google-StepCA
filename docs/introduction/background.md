---
layout: default
title: Background
parent: Introduction
nav_order: 1
---

# Background
{: .no_toc }

---

I started putting this together for my personal usage, to note down important things while I was working on this. But in the end I decided to try to make it a bit clearer (this is a nice way to say that you may find some mistakes) and share it with the community.

It wasn’t easy to collect information about all the pieces involved to get this project up and running. There’s not much discussion about PKIs and SCEP, most products are just offered As a Service, so you just have to pay someone to do that for you, without knowing what is happening under the hood.
Most businesses rely on Microsoft AD as their IdP which couples with NDES (Microsoft’s own SCEP implementation), but I live in a sort of “MS free” environment and I believe that many others do as well, so I wanted something different.

FreeRADIUS, which is what we’ll use as a RADIUS server, isn’t very easy to understand. Most of the documentation is written inside the configuration files and, to me at least, it’s very hard to read and understand.
So, I decided to put this together not to just give step-by-step instructions, but to try to add a bit more information on what each step does and why it works like that.

Indeed, you shouldn’t use this as a step-by-step guide to just follow without understanding what you’re doing, use this as a guidance but try to understand what each piece does and why.


Of course, some basic knowledge of what we are going to deal with is required.

If you have zero knowledge about PKI and public key cryptography, you’d probably not be here, but just in case, take a look at this [interesting article](https://smallstep.com/blog/everything-pki/) and try to understand the key concepts before going on.


{: .disclaimer }

This document has been written for informational purposes. I take no responsibility for whatever damage you may cause by following this.
Use this as a guidance to learn and understand what you're doing, don't do stuff that you don't understand. 