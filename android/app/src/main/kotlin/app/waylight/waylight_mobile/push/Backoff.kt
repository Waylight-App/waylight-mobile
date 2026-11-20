package app.waylight.waylight_mobile.push

import kotlin.random.Random

/**
 * Exponential backoff with full jitter for reconnecting the stream, so
 * phones do not reconnect in step after the relay restarts.
 */
class Backoff(
    private val baseMillis: Long = 1_000,
    private val maxMillis: Long = 5 * 60_000,
    private val random: Random = Random.Default,
) {
    private var attempt = 0

    /** The delay before the next attempt; grows with every failure. */
    fun next(): Long {
        val ceiling = (baseMillis shl attempt.coerceAtMost(MAX_SHIFT)).coerceAtMost(maxMillis)
        attempt++
        return random.nextLong(ceiling / 2, ceiling + 1)
    }

    /** Starts over after a connection that worked. */
    fun reset() {
        attempt = 0
    }

    private companion object {
        const val MAX_SHIFT = 20
    }
}
