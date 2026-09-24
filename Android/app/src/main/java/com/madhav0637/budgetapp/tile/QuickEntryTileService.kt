package com.madhav0637.budgetapp.tile

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.madhav0637.budgetapp.ui.quickentry.QuickEntryActivity

/** The "Log Expense" tile in Quick Settings (swipe down from the top). Works on every Android phone. */
class QuickEntryTileService : TileService() {
    override fun onStartListening() {
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        val intent = Intent(this, QuickEntryActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val open = {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val pending = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
                startActivityAndCollapse(pending)
            } else {
                @Suppress("DEPRECATION")
                startActivityAndCollapse(intent)
            }
        }
        // Quick entry only works on an unlocked phone, like on iOS: ask to unlock first.
        if (isLocked) unlockAndRun { open() } else open()
    }
}
