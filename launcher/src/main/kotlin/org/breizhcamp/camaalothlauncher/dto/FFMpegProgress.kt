package org.breizhcamp.camaalothlauncher.dto

import java.math.BigDecimal

/**
 * Contains data retrieved from ffmpeg during conversion
 */
data class FFMpegProgress(
        val frame: Long?,
        val fps: BigDecimal?,
        val bitrate: String?, //5030.12kbits/s
        val outTimeUs: Long,
        val speed: BigDecimal?, //12.3 (= 12.3x)
        val progress: String? //"continue" or "end"
) {

    companion object {
        fun build(args: Map<String, String>): FFMpegProgress {
            //despite the name outTimeMs is not in milliseconds but in microseconds
            // a future ffmpeg patch is going to change the name of out_time_ms to out_time_us
            // https://git.videolan.org/?p=ffmpeg.git;a=commitdiff;h=26dc76324564fc572689509c2efb7f1cb8f41a45

            return FFMpegProgress(
                    args.get("frame")?.toLong(),
                    args.get("fps")?.toBigDecimal(),
                    args.get("bitrate"),
                    args.get("out_time_us")?.toLong() ?: args.get("out_time_ms")?.toLong() ?: throw IllegalStateException("No [out_time_(u|m)s] in msg"),
                    args.get("speed")?.dropLast(1)?.trim()?.toBigDecimal(),
                    args.get("progress")
            )
        }
    }

}