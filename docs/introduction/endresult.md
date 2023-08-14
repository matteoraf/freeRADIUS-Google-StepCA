---
layout: default
title: The End Result
parent: Introduction
nav_order: 3
---

# The End Result
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---


At the end of the process, here’s what we’ll have set up:

## A key pair for our ROOT CA

The Root CA will only be used to sign or revoke Intermediate CAs.

We want this to be safe and protected, so we’ll keep it offline and we’ll pull it out from its safe box only in case we need to do something with an Intermediate Authority (create a new one or revoke an existing one).

## Intermediate CA n.1

We’ll set up an ACME endpoint on this Intermediate CA, so that it can be used to handle server certificates (for example, our RADIUS server cert, but it can then be used for any internal server).

## Intermediate CA n.2

On a separate CA, we’ll set up a SCEP endpoint.

Devices will connect to that endpoint to require their identity certificates.

## RADIUS Server

The RADIUS server will handle AAA (Authorization, Authentication, Accounting) for devices using the EAP-TLS protocol

## SCEP Proxy
<span style="text-decoration:underline;">This will be added in a future update of the document.</span>
I need devices to be able to reach the SCEP server even when they’re outside my network, but I don’t want to expose my CA, so I decided to set up an SCEP Proxy. 

My idea is that this proxy will be able to verify that the request is legitimate by verifying the device uuid together with the associated user identity against the MDM, since SCEP only relies on a static challenge password to authorize requests.
