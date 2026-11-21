package app.waylight.wear.glances

/**
 * A module's compact endpoint as `GET /api/modules` lists it (server #634):
 * the [path] to fetch and the query [params] it takes. Endpoints with
 * params (the smart home device) depend on a widget's settings, which the
 * watch does not have, so it leaves them out.
 */
data class CompactEndpoint(val module: String, val path: String, val params: List<String> = emptyList())

/**
 * What the status tile shows (#247): the compact states that have
 * something to say, the most urgent first. Pure, so it is tested without a
 * watch.
 */
object StatusOverview {
    /** How many states fit on the round screen with their module names. */
    const val MAX_ROWS = 3

    /**
     * The states of [compact] without the empty ones, problems first, then
     * attention, ok and none; the server's order within a level.
     */
    fun rows(compact: List<CompactGlance>, limit: Int = MAX_ROWS): List<CompactGlance> =
        compact.filterNot { it.empty }.sortedByDescending { it.level.ordinal }.take(limit)

    /** How many states ask for a look (attention or problem). */
    fun needingLook(compact: List<CompactGlance>): Int =
        compact.count { !it.empty && (it.level == Level.ATTENTION || it.level == Level.PROBLEM) }
}
