package app.waylight.wear.glances

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class ActionsTest {
    @Test
    fun `ticks off a to-do with its due date and version`() {
        val req = Actions.request(WatchAction.CompleteTodo(OpenTodo("a b", "Milk", "2026-11-21", 4)))
        assertEquals("PUT", req.method)
        assertEquals("/api/todos/a%20b", req.path)
        val body = JSONObject(req.body!!)
        assertEquals("Milk", body.getString("title"))
        assertEquals("2026-11-21", body.getString("due"))
        assertEquals(true, body.getBoolean("done"))
        assertEquals(4, body.getInt("version"))
    }

    @Test
    fun `leaves out the version of old servers`() {
        val req = Actions.request(WatchAction.CompleteTodo(OpenTodo("1", "Milk", "", 0)))
        assertFalse(JSONObject(req.body!!).has("version"))
    }

    @Test
    fun `sets and clears my status`() {
        val office = Actions.request(WatchAction.SetPresence(Presence.OFFICE))
        assertEquals("PUT /api/presence/me", "${office.method} ${office.path}")
        assertEquals("office", JSONObject(office.body!!).getString("status"))
        assertEquals("", JSONObject(office.body!!).getString("returnOn"))
        val none = Actions.request(WatchAction.SetPresence(Presence.NONE))
        assertEquals("", JSONObject(none.body!!).getString("status"))
    }

    @Test
    fun `switches a device and sends compact actions as they are`() {
        val device = Device("switch.coffee", "Coffee", "off", DeviceAction.TOGGLE)
        assertEquals(
            ActionRequest("POST", "/api/smarthome/entities/switch.coffee/action", null),
            Actions.request(WatchAction.SwitchDevice(device)),
        )
        assertEquals(
            ActionRequest("POST", "/api/focus/start", """{"minutes":25}"""),
            Actions.request(WatchAction.Compact("POST", "/api/focus/start", """{"minutes":25}""")),
        )
    }

    @Test
    fun `reads compact actions and refuses requests outside the API`() {
        val json = JSONObject(
            """{"id":"presence.set","label":{"key":"k","text":"Status"},"method":"put","path":"/api/presence/me",
               "choices":[{"id":"office","label":{"text":"Office"},"body":{"status":"office"},"selected":true}]}""",
        )
        val action = GlanceAction.fromJson(json)!!
        assertEquals("PUT", action.method)
        assertEquals(GlanceChoice("office", GlanceText("Office"), """{"status":"office"}""", true), action.choices.single())
        assertEquals(action, GlanceAction.fromJson(action.toJson()))

        assertNull(GlanceAction.fromJson(JSONObject("""{"method":"POST","path":"https://evil.example/x"}""")))
        assertNull(GlanceAction.fromJson(JSONObject("""{"method":"GET","path":"/api/todos"}""")))
        assertNull(GlanceAction.fromJson(JSONObject("""{"method":"POST","path":"/api/../auth/logout"}""")))
    }
}
