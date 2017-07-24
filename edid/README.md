#  EDID for Doctor HDMI

These EDID files can be loaded into Doctor HDMI device to constraint the HDMI output of a computer.
It's then far easier to grab the output with a BlackMagic capture card as it removes the need to choose the right definition.

Each file contains exactly one and only one timing definition, so attached computer has no choice at all.

Frame rate is either 50Hz or 25Hz to match frame rate of European broadcast standard. Because we removed 60Hz from the EDID, they are not conforming with the EIA/CEA-861 standard (they don't offer "required" mode found in the HDTV standard).

## Online documentation

Some links to documentation used to create these EDID:

* https://en.wikipedia.org/wiki/Extended_Display_Identification_Data
* HDTV have official modeline (from Linux kernel sources): https://github.com/torvalds/linux/blob/deac8429d62ca19c1571853e2a18f60e760ee04c/drivers/gpu/drm/drm_edid.c
