package org.breizhcamp.camaalothlauncher

import org.springframework.boot.context.properties.ConfigurationProperties

/**
 * Properties for camaalooth
 */
@ConfigurationProperties("camaaloth")
class CamaalothProps {

    lateinit var recordingDir: String
    val nageru = Nageru()

    class Nageru {
        lateinit var startScript: String
    }

}