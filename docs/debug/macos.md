---
layout: default
title: MacOS
parent: Debug
nav_order: 4
---

# MacOS
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

To make it quick, there are 3 things (listed below) you can have trouble with.

In any case, you’d want to see logs to understand what is going wrong.

MacOS has a really powerful logging system and discussing it is out of the scope of this document, but the guys at Kandji made an interesting [article](https://blog.kandji.io/mac-logging-and-the-log-command-a-guide-for-apple-admins) about it, you should definitely check it out.

The command is built like this

```sh
{% raw %}
log stream --debug --info --predicate 'your_predicate'
{% endraw %}
```

The _stream_ command is basically a “follow” command. If you replace it with _show_, it’ll show all existing logs filtered by _your_predicate_.

The _your_predicate_ piece is a filter, which you can build around these three “objects”:

- Subsystem
- Process
- Category


So for example if I want to see all log messages for the past 2 days, from the _com.apple.ManagedClient_ subsystem and CertficateService process, my command would be

```sh
{% raw %}
log show --debug --info --last 2d --predicate 'process="CertificateService" and subsystem="com.apple.ManagedClient"'
{% endraw %}
```

For each of the things that you could have trouble with, here’s a list of “objects” you should filter your logs with to get the most relevant information:

## Profiles installation

If you have troubles installing your configuration profile, these are the objects you should filter about:

Subsystem: ***com.apple.ManagedClient***

Process: ***mdmclient*** 

So, for example, if run this command before pushing your profile from MDM, you’ll see the log output in real-time

```sh
{% raw %}
log stream --debug --info --predicate 'process="mdmclient" and subsystem="com.apple.ManagedClient"'
{% endraw %}
```

## SCEP Identity Certificate

If you have issues to get your identity Certificate, you can filter with the following combination:

Subsystem: ***com.apple.ManagedClient***

Process: ***CertificateService***

If you want to see specifically what the SCEP client is doing, you could also add SCEP as a category to your predicate filter.

```sh
{% raw %}
log stream --debug --info --predicate 'process="CertificateService" and subsystem="com.apple.ManagedClient" and category="SCEP"'
{% endraw %}
```

## WiFI Auth

If you’re having trouble connecting to your WiFi, start by filtering with:

process: ***eapolclient***

You can then dig deeper by adding filters for

subsystem: c***om.apple.eapol***

category: ***Client***

or

subsystem: ***com.apple.securityd***
