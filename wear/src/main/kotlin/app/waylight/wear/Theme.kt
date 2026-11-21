package app.waylight.wear

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme

// The amber seed of the phone app (app_theme.dart) on the dark watch face;
// Wear OS apps are always dark.
private val colors = Colors(
    primary = Color(0xFFF2B441),
    onPrimary = Color(0xFF1A1206),
    secondary = Color(0xFFF2B441),
    onSecondary = Color(0xFF1A1206),
)

/** The app's Material theme for Wear OS. */
@Composable
fun WaylightTheme(content: @Composable () -> Unit) {
    MaterialTheme(colors = colors, content = content)
}
