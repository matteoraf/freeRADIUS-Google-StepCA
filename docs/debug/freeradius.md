---
layout: default
title: Freeradius
parent: Debug
nav_order: 1
---

# Freeradius
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

If you want to see a detailed log of what freeradius is doing, you have to run it with the -X flag.

You can either manually run it from the command line, or you can tell systemd to run it with this option by editing the file located at _/etc/default/freeradius_

```sh
{% raw %}
cat /etc/default/freeradius 
# Options passed to the FreeRADIUS deamon.
#
FREERADIUS_OPTIONS="-X"


# If FreeRADIUS is being used on a SysVinit system
# and FREERADIUS_OPTIONS has not been set and the
# following location exists, then it will be used
# for the config directory rather than the default.
#
# This option has no effect when systemd is in
# use, or if FREERADIUS_OPTIONS is set above.
#
FREERADIUS_CONF_LOCAL="/usr/local/etc/freeradius"
{% endraw %}
```

You can then follow the logs by running
```sh
{% raw %}
journalctl -f --unit=freeradius
{% endraw %}
```