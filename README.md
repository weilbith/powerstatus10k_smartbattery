# Powerstatus10k SmartBattery Segment

Subscription version of the default battery segment. Instead of using a fixed
interval to update the segment, this subscribes to changes of the system class
files. Thereby it is much more precise in displaying accurate information on
point.

**This required `inotifywait` to be installed**.
On _ArchLinux_ this can be installed via the `inotify-tools` package.
