package org.breizhcamp.camaalothlauncher.dto

/**
 * lsblk JSON return
 */
data class LsblkDto(val blockdevices: List<BlockDevice>) {
    data class BlockDevice(
        val name: String,
        val mountpoint: String?,
        val vendor: String?,
        val label: String?,
        val model: String?,
        val hotplug: String,
        val size: String?,
        val children: List<BlockDevice>?
    )
}