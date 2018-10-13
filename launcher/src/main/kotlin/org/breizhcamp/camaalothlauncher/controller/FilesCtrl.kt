package org.breizhcamp.camaalothlauncher.controller

import org.breizhcamp.camaalothlauncher.dto.FileMeta
import org.breizhcamp.camaalothlauncher.services.FilesSrv
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

/**
 * Handle partitions, files, etc...
 */
@RestController("/files")
class FilesCtrl(private val filesSrv: FilesSrv) {

    /**
     * @return List of all *.ug.zip files on removable devices
     */
    @GetMapping
    fun listAllUgFiles() : List<FileMeta> {
        val partitions = filesSrv.readPartitions()
        return filesSrv.getFilesFromPartitions(partitions, "*.ug.zip")
    }


}