package app.waylight.waylight_mobile.push

import android.content.Context
import app.waylight.waylight_mobile.BuildConfig
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions

/**
 * Initialises Firebase from the build-time values (ADR 0008) instead of a
 * google-services.json, so the repository holds no Firebase project.
 */
object FirebaseSetup {
    /** Whether this build was given Firebase values at all. */
    val configured: Boolean
        get() = listOf(BuildConfig.FCM_PROJECT_ID, BuildConfig.FCM_APP_ID, BuildConfig.FCM_API_KEY, BuildConfig.FCM_SENDER_ID)
            .all { it.isNotEmpty() }

    /** Starts Firebase once; returns false when the build has no values. */
    fun ensure(context: Context): Boolean {
        if (!configured) return false
        if (FirebaseApp.getApps(context).isEmpty()) {
            val options = FirebaseOptions.Builder()
                .setProjectId(BuildConfig.FCM_PROJECT_ID)
                .setApplicationId(BuildConfig.FCM_APP_ID)
                .setApiKey(BuildConfig.FCM_API_KEY)
                .setGcmSenderId(BuildConfig.FCM_SENDER_ID)
                .build()
            FirebaseApp.initializeApp(context.applicationContext, options)
        }
        return true
    }
}
