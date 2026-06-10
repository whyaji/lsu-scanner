package com.srs.sampletrack

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channels = listOf(
            Triple(
                "sampletrack_notifications",
                "SampleTrack Notifications",
                R.raw.notification,
            ),
            Triple(
                "sampletrack_notifications_2",
                "SampleTrack Notifications (Alt)",
                R.raw.notification2,
            ),
        )

        for ((channelId, channelName, soundResId) in channels) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH,
            )
            val soundUri =
                Uri.parse("android.resource://$packageName/$soundResId")
            channel.setSound(soundUri, audioAttributes)
            manager.createNotificationChannel(channel)
        }
    }
}
