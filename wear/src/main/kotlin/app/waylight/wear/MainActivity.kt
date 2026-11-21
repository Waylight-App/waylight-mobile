package app.waylight.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import app.waylight.wear.ui.WatchApp

/** The watch app's only activity; the screens are composables. */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { WaylightTheme { WatchApp() } }
    }
}
