package org.breizhcamp.camaalothlauncher.dto

import java.time.Instant

/**
 * File with some metadata
 */
data class FileMeta (
        val name: String,
        val path: String,
        val lastModified: Instant,
        val partition: Partition
)