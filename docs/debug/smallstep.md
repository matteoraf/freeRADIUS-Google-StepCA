---
layout: default
title: Smallstep
parent: Debug
nav_order: 3
---

# Smallstep
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

When run in foreground, step-ca by default logs to stderr/stdout, so unless you still have the shell open, you won’t see any logging anywhere.

But, when you configure step to run as a daemon, systemd-journald will take care of saving logs, which you’ll be able to follow along by running:

```sh
journalctl -f --unit=step-ca
```

By default, smallstep doesn’t have debugging enabled, to do so, you have to set an environment variable before starting it.
 
```sh
export STEPDEBUG=1
```
