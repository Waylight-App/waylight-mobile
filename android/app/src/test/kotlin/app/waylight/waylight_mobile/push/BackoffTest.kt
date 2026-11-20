package app.waylight.waylight_mobile.push

import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class BackoffTest {
    @Test
    fun growsWithJitterUpToTheMaximum() {
        val backoff = Backoff(baseMillis = 1_000, maxMillis = 8_000, random = Random(1))
        val delays = List(6) { backoff.next() }
        assertTrue(delays[0] in 500..1_000)
        assertTrue(delays[2] in 2_000..4_000)
        assertTrue(delays.all { it <= 8_000 })
        assertTrue(delays.last() >= 4_000)
    }

    @Test
    fun startsOverAfterReset() {
        val backoff = Backoff(baseMillis = 1_000, maxMillis = 60_000, random = Random(2))
        repeat(5) { backoff.next() }
        backoff.reset()
        assertTrue(backoff.next() <= 1_000)
    }
}
