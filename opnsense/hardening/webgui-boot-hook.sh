#!/bin/sh
# Bounded asynchronous rebind; does not block the native boot sequence.
exec /usr/sbin/daemon -f /bin/sh /conf/opnsense-hardening/ensure-webgui.sh
