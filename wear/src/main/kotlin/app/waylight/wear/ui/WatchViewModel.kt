package app.waylight.wear.ui

import android.app.Application
import android.os.Build
import android.provider.Settings
import androidx.annotation.StringRes
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.waylight.wear.R
import app.waylight.wear.data.ApiException
import app.waylight.wear.data.ServerAddress
import app.waylight.wear.data.Session
import app.waylight.wear.data.SessionStore
import app.waylight.wear.data.WaylightApi
import app.waylight.wear.pairing.HandoverKey
import app.waylight.wear.pairing.HandoverServer
import app.waylight.wear.pairing.wifiAddress
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Where the app stands: still reading the store, not paired, or paired. */
sealed interface AppState {
    data object Loading : AppState

    data object Unpaired : AppState

    data class Paired(val session: Session) : AppState
}

/** The QR code pairing screen. */
sealed interface PairingState {
    data object WaitingForWifi : PairingState

    /** The QR code is shown; [error] is the outcome of a failed attempt. */
    data class Ready(val link: String, @StringRes val error: Int? = null) : PairingState

    data object Connecting : PairingState
}

/** The screen of the typed pairing. */
data class ManualState(
    val server: String = "",
    val code: String = "",
    val busy: Boolean = false,
    @StringRes val error: Int? = null,
)

/** The outcome of redeeming a pairing code, with the status the phone gets. */
private enum class Outcome(val status: Int, @StringRes val message: Int?) {
    PAIRED(204, null),
    INVALID_SERVER(422, R.string.error_invalid_server),
    REJECTED(401, R.string.error_rejected),
    UNREACHABLE(502, R.string.error_unreachable),
    SERVER_ERROR(502, R.string.error_server),
}

/** State and actions of the watch app. */
class WatchViewModel(application: Application) : AndroidViewModel(application) {
    private val store = SessionStore(application)

    private val _app = MutableStateFlow<AppState>(AppState.Loading)
    val app: StateFlow<AppState> = _app.asStateFlow()

    private val _pairing = MutableStateFlow<PairingState>(PairingState.WaitingForWifi)
    val pairing: StateFlow<PairingState> = _pairing.asStateFlow()

    private val _manual = MutableStateFlow(ManualState())
    val manual: StateFlow<ManualState> = _manual.asStateFlow()

    private var handover: Job? = null

    init {
        viewModelScope.launch {
            val session = withContext(Dispatchers.IO) { store.load() }
            _app.value = if (session == null) AppState.Unpaired else AppState.Paired(session)
        }
    }

    /**
     * Shows a QR code and waits for the phone's handover while the pairing
     * screen is open; a new Wi-Fi address gets a new listener and key.
     */
    fun startHandover() {
        if (handover?.isActive == true) return
        handover = viewModelScope.launch {
            wifiAddress(getApplication()).collectLatest { address ->
                if (address == null) {
                    _pairing.value = PairingState.WaitingForWifi
                    return@collectLatest
                }
                val key = HandoverKey.generate()
                val server = withContext(Dispatchers.IO) { HandoverServer(address) }
                val link = key.link(server.address)
                _pairing.value = PairingState.Ready(link)
                coroutineScope {
                    // accept() does not react to cancellation; closing the
                    // socket ends it when the screen closes.
                    val closer = launch {
                        try {
                            awaitCancellation()
                        } finally {
                            server.close()
                        }
                    }
                    withContext(Dispatchers.IO) {
                        server.serve { body ->
                            val handoverMessage = key.open(body) ?: return@serve 400
                            _pairing.value = PairingState.Connecting
                            val outcome = redeem(handoverMessage.server, handoverMessage.code)
                            if (outcome != Outcome.PAIRED) _pairing.value = PairingState.Ready(link, outcome.message)
                            outcome.status
                        }
                    }
                    closer.cancel()
                }
            }
        }
    }

    /** Stops listening when the pairing screen closes. */
    fun stopHandover() {
        handover?.cancel()
        handover = null
    }

    fun setManualServer(text: String) {
        _manual.value = _manual.value.copy(server = text.trim(), error = null)
    }

    fun setManualCode(text: String) {
        _manual.value = _manual.value.copy(code = text.trim(), error = null)
    }

    /** Pairs with the typed server address and pairing code. */
    fun pairManually() {
        val input = _manual.value
        if (input.busy || input.server.isEmpty() || input.code.isEmpty()) return
        _manual.value = input.copy(busy = true, error = null)
        viewModelScope.launch {
            val outcome = withContext(Dispatchers.IO) { redeem(input.server, input.code) }
            _manual.value = if (outcome == Outcome.PAIRED) ManualState() else input.copy(busy = false, error = outcome.message)
        }
    }

    /**
     * Ends the session on the server and forgets it. Without a connection the
     * token is deleted anyway; the session then runs out on the server or is
     * revoked under Settings → Apps.
     */
    fun signOut() {
        val state = _app.value as? AppState.Paired ?: return
        _app.value = AppState.Unpaired
        viewModelScope.launch(Dispatchers.IO) {
            try {
                WaylightApi(state.session.server, state.session.token).logout()
            } catch (e: IOException) {
                // Offline: see above.
            }
            store.clear()
        }
    }

    /** Redeems [code] on [serverText] and stores the session. Blocks. */
    private fun redeem(serverText: String, code: String): Outcome {
        val server = (ServerAddress.parse(serverText) as? ServerAddress.Parsed.Valid)?.address
            ?: return Outcome.INVALID_SERVER
        val token = try {
            WaylightApi(server).redeemPairingCode(deviceName(), code)
        } catch (e: ApiException) {
            return if (e.status == 401 || e.status == 422) Outcome.REJECTED else Outcome.SERVER_ERROR
        } catch (e: IOException) {
            return Outcome.UNREACHABLE
        }
        val session = Session(server, token)
        store.save(session)
        _app.value = AppState.Paired(session)
        return Outcome.PAIRED
    }

    /** The name the session gets under Settings → Apps on the server. */
    private fun deviceName(): String {
        val name = Settings.Global.getString(getApplication<Application>().contentResolver, Settings.Global.DEVICE_NAME)
            ?.takeIf { it.isNotBlank() }
            ?: "${Build.MANUFACTURER} ${Build.MODEL}"
        return name.take(MAX_DEVICE_NAME)
    }

    override fun onCleared() {
        stopHandover()
    }

    private companion object {
        // The server accepts device names of up to 80 characters.
        const val MAX_DEVICE_NAME = 80
    }
}
