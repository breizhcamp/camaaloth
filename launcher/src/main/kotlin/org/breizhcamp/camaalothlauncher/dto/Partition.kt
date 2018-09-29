package org.breizhcamp.camaalothlauncher.dto

/**
 * A mounted partition and metadata
 */
data class Partition(
        val mountpoint: String,
        val deviceName: String,
        val label: String?,
        val model: String?,
        val vendor: String?,
        val size: String?
)