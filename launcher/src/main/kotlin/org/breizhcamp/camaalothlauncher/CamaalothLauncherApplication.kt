package org.breizhcamp.camaalothlauncher

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.boot.runApplication

@SpringBootApplication
@EnableConfigurationProperties(CamaalothProps::class)
class CamaalothLauncherApplication

fun main(args: Array<String>) {
    runApplication<CamaalothLauncherApplication>(*args)
}
