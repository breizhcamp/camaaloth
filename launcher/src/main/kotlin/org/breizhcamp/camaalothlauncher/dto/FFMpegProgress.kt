package org.breizhcamp.camaalothlauncher.dto

import java.math.BigDecimal

/**
 * Contains data retrieved from ffmpeg during conversion
 */
data class FFMpegProgress(
        val frame: Long?,
        val fps: BigDecimal?,
        val bitrate: String?, //5030.12kbits/s
        val outTimeMs: Long,
        val speed: String?, //12.3x
        val progress: String? //"continue" or "end"
) {

    companion object {
        fun build(args: Map<String, String>): FFMpegProgress {
            return FFMpegProgress(
                    args.get("frame")?.toLong(),
                    args.get("fps")?.toBigDecimal(),
                    args.get("bitrate"),
                    args.get("out_time_ms")?.toLong() ?: throw IllegalStateException("No [out_time_ms] in msg"),
                    args.get("speed"),
                    args.get("progress")
            )
        }
    }

}