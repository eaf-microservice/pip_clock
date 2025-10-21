package com.eafmicroservice.pip_oclock;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.Notification;
import android.app.NotificationManager;
import android.text.format.DateFormat;

import androidx.core.app.NotificationCompat;

import java.util.Calendar;

public class TimeTickReceiver extends BroadcastReceiver {
    private static final String CHANNEL_ID = "pip_clock_channel";
    // Use the same ID as the foreground notification so we update it instead of duplicating.
    private static final int NOTIFICATION_ID = 2000;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) return;
        if (!Intent.ACTION_TIME_TICK.equals(intent.getAction())) return;

        Calendar now = Calendar.getInstance();
        String hh = DateFormat.format("HH", now).toString();
        String mm = DateFormat.format("mm", now).toString();
        String title = "Pip Clock • " + hh + ":" + mm;

        Notification notification = new NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText("Tap to open")
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setSmallIcon(R.mipmap.ic_launcher)
                .build();

        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            nm.notify(NOTIFICATION_ID, notification);
        }
    }
}

