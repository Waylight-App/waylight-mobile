package app.waylight.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.TimeText
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController

private object Routes {
    const val START = "start"
    const val PAIR_QR = "pair/qr"
    const val PAIR_MANUAL = "pair/manual"
}

/** The screens of the app; swiping right goes back, as everywhere on Wear OS. */
@Composable
fun WatchApp(viewModel: WatchViewModel = viewModel()) {
    val app by viewModel.app.collectAsStateWithLifecycle()
    val nav = rememberSwipeDismissableNavController()

    // A finished pairing leaves the pairing screens.
    LaunchedEffect(app) {
        if (app is AppState.Paired) nav.popBackStack(Routes.START, inclusive = false)
    }

    Scaffold(timeText = { TimeText() }) {
        SwipeDismissableNavHost(navController = nav, startDestination = Routes.START) {
            composable(Routes.START) {
                when (val state = app) {
                    AppState.Loading -> Unit
                    AppState.Unpaired -> UnpairedScreen(
                        onPairWithPhone = { nav.navigate(Routes.PAIR_QR) },
                        onPairManually = { nav.navigate(Routes.PAIR_MANUAL) },
                    )
                    is AppState.Paired -> PairedScreen(state.session, onSignOut = viewModel::signOut)
                }
            }
            composable(Routes.PAIR_QR) { QrPairingScreen(viewModel) }
            composable(Routes.PAIR_MANUAL) { ManualPairingScreen(viewModel) }
        }
    }
}
