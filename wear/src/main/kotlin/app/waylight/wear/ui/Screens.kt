package app.waylight.wear.ui

import android.app.RemoteInput
import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.ScalingLazyListScope
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.CircularProgressIndicator
import androidx.wear.compose.material.ListHeader
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TitleCard
import androidx.wear.input.RemoteInputIntentHelper
import app.waylight.wear.R
import app.waylight.wear.data.Session
import app.waylight.wear.glances.DeviceAction
import app.waylight.wear.glances.GlanceFormat
import app.waylight.wear.glances.Level
import app.waylight.wear.glances.Presence
import app.waylight.wear.glances.ServerTexts
import app.waylight.wear.glances.WatchAction
import app.waylight.wear.pairing.QrCode

/** A scrolling list of chips with the position indicator of Wear OS. */
@Composable
fun ScreenList(content: ScalingLazyListScope.() -> Unit) {
    val listState = rememberScalingLazyListState()
    Scaffold(positionIndicator = { PositionIndicator(scalingLazyListState = listState) }) {
        ScalingLazyColumn(modifier = Modifier.fillMaxSize(), state = listState, content = content)
    }
}

/** A chip as wide as the list. */
@Composable
fun ListChip(
    label: String,
    onClick: () -> Unit,
    secondary: String? = null,
    primary: Boolean = false,
    enabled: Boolean = true,
) {
    Chip(
        onClick = onClick,
        label = { Text(label) },
        secondaryLabel = if (secondary == null) null else { { Text(secondary, maxLines = 2) } },
        colors = if (primary) ChipDefaults.primaryChipColors() else ChipDefaults.secondaryChipColors(),
        enabled = enabled,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun Message(text: String, error: Boolean = false) {
    Text(
        text,
        textAlign = TextAlign.Center,
        style = MaterialTheme.typography.caption2,
        color = if (error) MaterialTheme.colors.error else MaterialTheme.colors.onBackground,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
    )
}

@Composable
fun UnpairedScreen(onPairWithPhone: () -> Unit, onPairManually: () -> Unit) {
    ScreenList {
        item { ListHeader { Text(stringResource(R.string.app_name)) } }
        item { Message(stringResource(R.string.not_paired)) }
        item { ListChip(stringResource(R.string.pair_with_phone), onPairWithPhone, primary = true) }
        item { ListChip(stringResource(R.string.pair_manually), onPairManually) }
    }
}

/** The glances: next event, compact states, my status, and their age. */
@Composable
fun PairedScreen(viewModel: WatchViewModel, session: Session, onPresence: () -> Unit) {
    val snapshot by viewModel.snapshot.collectAsStateWithLifecycle()
    val refreshing by viewModel.refreshing.collectAsStateWithLifecycle()
    val offline by viewModel.offline.collectAsStateWithLifecycle()
    val acting by viewModel.acting.collectAsStateWithLifecycle()
    val actionMessage by viewModel.actionMessage.collectAsStateWithLifecycle()
    val context = LocalContext.current
    LaunchedEffect(Unit) { viewModel.refreshIfStale() }
    ScreenList {
        item { ListHeader { Text(stringResource(R.string.app_name)) } }
        val s = snapshot
        if (s == null) {
            item { Message(stringResource(if (offline) R.string.error_unreachable else R.string.loading), error = offline) }
        } else {
            s.nextEvent?.let { event ->
                item {
                    TitleCard(
                        onClick = {},
                        title = { Text(GlanceFormat.eventWhen(context, event), color = MaterialTheme.colors.primary) },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(event.summary, maxLines = 3)
                    }
                }
            }
            actionMessage?.let { message -> item { Message(stringResource(message), error = message != R.string.action_done) } }
            s.compact.forEach { glance ->
                item {
                    GlanceChip(
                        label = GlanceFormat.compactTitle(context, glance),
                        secondary = GlanceFormat.compactDetail(context, glance),
                        level = glance.level,
                    )
                }
                // The primary action of the compact state (server #598):
                // one chip, or one per choice with the current one marked.
                glance.action?.let { action ->
                    if (action.choices.isEmpty()) {
                        item {
                            ListChip(ServerTexts.resolve(context, action.label), enabled = !acting, onClick = {
                                viewModel.act(WatchAction.Compact(action.method, action.path, action.body))
                            })
                        }
                    } else {
                        action.choices.forEach { choice ->
                            item {
                                ListChip(
                                    ServerTexts.resolve(context, choice.label),
                                    primary = choice.selected,
                                    enabled = !acting,
                                    onClick = { viewModel.act(WatchAction.Compact(action.method, action.path, choice.body)) },
                                )
                            }
                        }
                    }
                }
            }
            s.firstTodo?.let { todo ->
                item {
                    ListChip(
                        label = todo.title,
                        secondary = stringResource(R.string.todo_tick_off),
                        enabled = !acting,
                        onClick = { viewModel.act(WatchAction.CompleteTodo(todo)) },
                    )
                }
            }
            s.presence?.let { presence ->
                item {
                    ListChip(
                        label = stringResource(R.string.presence_label),
                        secondary = GlanceFormat.presence(context, presence),
                        enabled = !acting,
                        onClick = onPresence,
                    )
                }
            }
            if (s.devices.isNotEmpty()) {
                item { ListHeader { Text(stringResource(R.string.smart_home)) } }
                s.devices.forEach { device ->
                    item {
                        ListChip(
                            label = device.name,
                            secondary = if (device.action == DeviceAction.PRESS) stringResource(R.string.device_press) else device.state,
                            enabled = !acting,
                            onClick = { viewModel.act(WatchAction.SwitchDevice(device)) },
                        )
                    }
                }
            }
            item {
                Message(
                    if (offline) stringResource(R.string.offline_since, GlanceFormat.updated(context, s.fetchedAt))
                    else GlanceFormat.updated(context, s.fetchedAt),
                    error = offline,
                )
            }
        }
        item {
            ListChip(
                stringResource(if (refreshing) R.string.refreshing else R.string.refresh),
                viewModel::refresh,
                enabled = !refreshing,
            )
        }
        item { Message(stringResource(R.string.connected_to, session.server.host)) }
        item { ListChip(stringResource(R.string.sign_out), viewModel::signOut) }
    }
}

/** Sets my presence status for today (#245). */
@Composable
fun PresenceScreen(viewModel: WatchViewModel, onDone: () -> Unit) {
    val snapshot by viewModel.snapshot.collectAsStateWithLifecycle()
    val acting by viewModel.acting.collectAsStateWithLifecycle()
    val context = LocalContext.current
    ScreenList {
        item { ListHeader { Text(stringResource(R.string.presence_label)) } }
        listOf(Presence.OFFICE, Presence.HOME, Presence.AWAY, Presence.NONE).forEach { status ->
            item {
                ListChip(
                    GlanceFormat.presence(context, status),
                    primary = snapshot?.presence == status,
                    enabled = !acting,
                    onClick = {
                        viewModel.act(WatchAction.SetPresence(status))
                        onDone()
                    },
                )
            }
        }
    }
}

/** A glance as chip; attention and problem get the warning colours. */
@Composable
private fun GlanceChip(label: String, secondary: String?, level: Level) {
    val colors = when (level) {
        Level.ATTENTION -> ChipDefaults.chipColors(backgroundColor = Color(0xFF5C4300), contentColor = Color(0xFFFFDEA6))
        Level.PROBLEM -> ChipDefaults.chipColors(backgroundColor = Color(0xFF93000A), contentColor = Color(0xFFFFDAD6))
        else -> ChipDefaults.secondaryChipColors()
    }
    Chip(
        onClick = {},
        label = { Text(label, maxLines = 2) },
        secondaryLabel = if (secondary == null) null else { { Text(secondary, maxLines = 2) } },
        colors = colors,
        modifier = Modifier.fillMaxWidth(),
    )
}

/** Shows the QR code for the phone and keeps the screen on meanwhile. */
@Composable
fun QrPairingScreen(viewModel: WatchViewModel) {
    val state by viewModel.pairing.collectAsStateWithLifecycle()
    val view = LocalView.current
    DisposableEffect(Unit) {
        viewModel.startHandover()
        view.keepScreenOn = true
        onDispose {
            view.keepScreenOn = false
            viewModel.stopHandover()
        }
    }
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        when (val s = state) {
            PairingState.WaitingForWifi -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CircularProgressIndicator()
                Message(stringResource(R.string.pair_waiting_for_wifi))
            }
            PairingState.Connecting -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CircularProgressIndicator()
                Message(stringResource(R.string.pair_connecting))
            }
            is PairingState.Ready -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                // A square inside the round screen leaves room for one line
                // of text below it.
                QrCode(s.link, Modifier.fillMaxWidth(0.6f).aspectRatio(1f))
                Message(
                    stringResource(s.error ?: R.string.pair_qr_hint),
                    error = s.error != null,
                )
            }
        }
    }
}

/** Server address and pairing code typed on the watch (or on the phone's keyboard). */
@Composable
fun ManualPairingScreen(viewModel: WatchViewModel) {
    val state by viewModel.manual.collectAsStateWithLifecycle()
    val serverLabel = stringResource(R.string.manual_server)
    val codeLabel = stringResource(R.string.manual_code)
    val askServer = rememberTextInput(serverLabel, viewModel::setManualServer)
    val askCode = rememberTextInput(codeLabel, viewModel::setManualCode)
    val unset = stringResource(R.string.manual_unset)
    ScreenList {
        item { ListHeader { Text(stringResource(R.string.pair_manually)) } }
        item { ListChip(serverLabel, askServer, secondary = state.server.ifEmpty { unset }) }
        // The code is a credential; show only that it is set.
        item { ListChip(codeLabel, askCode, secondary = if (state.code.isEmpty()) unset else "••••••") }
        item {
            ListChip(
                stringResource(if (state.busy) R.string.pair_connecting else R.string.manual_connect),
                viewModel::pairManually,
                primary = true,
                enabled = !state.busy && state.server.isNotEmpty() && state.code.isNotEmpty(),
            )
        }
        state.error?.let { error -> item { Message(stringResource(error), error = true) } }
    }
}

/** Opens the system's text input for [label] and passes the result to [onText]. */
@Composable
private fun rememberTextInput(label: String, onText: (String) -> Unit): () -> Unit {
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val data = result.data ?: return@rememberLauncherForActivityResult
        RemoteInput.getResultsFromIntent(data)?.getCharSequence(INPUT_KEY)?.let { onText(it.toString()) }
    }
    return {
        val intent: Intent = RemoteInputIntentHelper.createActionRemoteInputIntent()
        RemoteInputIntentHelper.putRemoteInputsExtra(intent, listOf(RemoteInput.Builder(INPUT_KEY).setLabel(label).build()))
        launcher.launch(intent)
    }
}

private const val INPUT_KEY = "text"
