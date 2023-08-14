---
layout: default
title: Start
nav_order: 1
description: ""
permalink: /
---
# Home

The purpose of this document is to describe the process of setting up an online PKI with an SCEP server and having Apple devices to get their identity certificates and use those for 802.1X authentication against a RADIUS server that also does an authorization check against Google Workspace LDAP, all by using free and open source products and requiring zero user interaction.

The use case for this project is having Google Workspace as your IdP, having Apple devices assigned 1:1, using an MDM solution which supports this kind of assignment and needing something which is completely transparent to end users.

In case you’re ok to have some user interaction, there are other options which we may discuss later.