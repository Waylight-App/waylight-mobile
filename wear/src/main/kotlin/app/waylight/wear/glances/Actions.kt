package app.waylight.wear.glances

import android.content.Context
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import app.waylight.wear.data.ApiException
import app.waylight.wear.data.SessionStore
import app.waylight.wear.data.WaylightApi
import java.io.IOException
import java.net.URLEncoder
import org.json.JSONObject

/** Something the watch changes on the server (#245). */
sealed interface WatchAction {
    /** Ticks off a to-do. */
    data class CompleteTodo(val todo: OpenTodo) : WatchAction

    /** Sets my presence status for today. */
    data class SetPresence(val status: Presence) : WatchAction

    /** The request of a compact state's action or one of its choices. */
    data class Compact(val method: String, val path: String, val body: String?) : WatchAction

    /** Switches or presses a smart home entity. */
    data class SwitchDevice(val device: Device) : WatchAction
}

/** The HTTP request of an action. */
data class ActionRequest(val method: String, val path: String, val body: String?)

/** The outcome of an action. */
enum class ActionResult { DONE, FAILED, OFFLINE, SIGNED_OUT }

/** Runs actions with the watch's session and refreshes the glances afterwards. */
object Actions {
    /** The request for [action]; pure, so it is tested without a server. */
    fun request(action: WatchAction): ActionRequest = when (action) {
        is WatchAction.CompleteTodo -> ActionRequest(
            "PUT",
            "/api/todos/${encode(action.todo.id)}",
            JSONObject().apply {
                put("title", action.todo.title)
                put("due", action.todo.due)
                put("done", true)
                // Version 0 is a to-do of a server from before #80.
                if (action.todo.version > 0) put("version", action.todo.version)
            }.toString(),
        )
        is WatchAction.SetPresence -> ActionRequest(
            "PUT",
            "/api/presence/me",
            // The server clears the status with an empty value.
            JSONObject().put("status", if (action.status == Presence.NONE) "" else action.status.name.lowercase())
                .put("returnOn", "").toString(),
        )
        is WatchAction.Compact -> ActionRequest(action.method, action.path, action.body)
        is WatchAction.SwitchDevice -> ActionRequest("POST", "/api/smarthome/entities/${encode(action.device.id)}/action", null)
    }

    /** Sends [action] and refreshes the glances. Blocks; call it off the main thread. */
    fun run(context: Context, action: WatchAction): ActionResult {
        val session = SessionStore(context).load() ?: return ActionResult.SIGNED_OUT
        val req = request(action)
        val result = try {
            WaylightApi(session.server, session.token).send(req.method, req.path, req.body)
            ActionResult.DONE
        } catch (e: ApiException) {
            if (e.status == 401) {
                Refresh.signOutLocally(context)
                return ActionResult.SIGNED_OUT
            }
            ActionResult.FAILED
        } catch (e: IOException) {
            return ActionResult.OFFLINE
        }
        // Also after a refused action: the glances may be out of date.
        Refresh.run(context)
        return result
    }

    /**
     * Ticks off [todo] in the background, for the tile, which cannot wait
     * for the network. Repeated taps collapse into one request.
     */
    fun completeTodoSoon(context: Context, todo: OpenTodo) {
        val request = OneTimeWorkRequestBuilder<TodoWorker>()
            .setInputData(Data.Builder().putString(TodoWorker.TODO, todo.toJson().toString()).build())
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork("todo-${todo.id}", ExistingWorkPolicy.KEEP, request)
    }

    private fun encode(segment: String): String = URLEncoder.encode(segment, Charsets.UTF_8.name()).replace("+", "%20")
}

/** Ticks off the to-do tapped on the tile. */
class TodoWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val todo = inputData.getString(TODO)?.let { OpenTodo.fromJson(JSONObject(it)) } ?: return Result.failure()
        return when (Actions.run(applicationContext, WatchAction.CompleteTodo(todo))) {
            ActionResult.OFFLINE -> Result.retry()
            ActionResult.DONE, ActionResult.FAILED, ActionResult.SIGNED_OUT -> Result.success()
        }
    }

    companion object {
        const val TODO = "todo"
    }
}
