package org.breizhcamp.camaalothlauncher.services

import org.springframework.stereotype.Service
import java.nio.file.Path

/**
 * Convert output files from nageru to MP4
 */
@Service
class ConvertSrv {

    private var filesToConvert: List<Path> = emptyList()

    fun setFiles(files: List<Path>) {
        filesToConvert = ArrayList(files)
    }


}