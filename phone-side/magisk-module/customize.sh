#!/system/bin/sh
# customize.sh — nhere module install
# Runs once during Magisk module installation.

ui_print "- nhere v2.1 installing"
ui_print "- generic Android / root command engine"
ui_print "- no daemons, no key watchers"

# Ensure nhere binary is executable
set_perm "$MODPATH/system/bin/nhere" root shell 0755

ui_print "- install complete"
ui_print "- reboot to activate service.sh"
