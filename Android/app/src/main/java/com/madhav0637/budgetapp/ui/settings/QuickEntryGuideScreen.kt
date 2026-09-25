package com.madhav0637.budgetapp.ui.settings

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.madhav0637.budgetapp.R
import com.madhav0637.budgetapp.tile.QuickEntryTileService
import com.madhav0637.budgetapp.ui.quickentry.QuickEntryActivity

/** How to open the Log Expense pop-up quickly, with one-tap buttons for the tile and a home-screen icon. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickEntryGuideScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Set Up Quick Entry") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } },
            )
        },
    ) { padding ->
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(padding).verticalScroll(rememberScrollState()).padding(16.dp),
        ) {
            Text(
                "Log an expense in a few seconds without opening the app. Pick any of these — they all open the same pop-up.",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            GuideCard(
                emoji = "⚡",
                title = "Quick Settings tile — works on every phone",
                steps = "Swipe down from the top twice, tap the pencil (Edit), and drag “Log Expense” into your tiles.",
            ) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Button(onClick = { requestTile(context) }, modifier = Modifier.fillMaxWidth().height(48.dp)) {
                        Text("Add the tile for me")
                    }
                }
            }

            GuideCard(
                emoji = "📌",
                title = "Home-screen icon — works on every phone",
                steps = "Long-press the BudgetApp icon and tap “Log Expense”, or drag it onto your home screen.",
            ) {
                if (ShortcutManagerCompat.isRequestPinShortcutSupported(context)) {
                    OutlinedButton(onClick = { pinShortcut(context) }, modifier = Modifier.fillMaxWidth().height(48.dp)) {
                        Text("Put a Log Expense icon on my home screen")
                    }
                }
            }

            GuideCard(
                emoji = "👆",
                title = "Your phone's own gesture",
                steps = "Most phones can open an app with a gesture. Set it to open “Log Expense”:\n\n" +
                    "• Samsung: Settings → Advanced features → Side button → Double press → Open app\n" +
                    "• Google Pixel: Settings → System → Gestures → Quick Tap → Open app\n" +
                    "• Other brands: search Settings for “gesture” or “quick launch”",
            )
        }
    }
}

@Composable
private fun GuideCard(emoji: String, title: String, steps: String, action: @Composable () -> Unit = {}) {
    Card(Modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(16.dp)) {
            Text("$emoji  $title", style = MaterialTheme.typography.titleMedium)
            Text(steps, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            action()
        }
    }
}

/** Android 13+ can show a system prompt that adds our tile to Quick Settings in one tap. */
private fun requestTile(context: Context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
    context.getSystemService(StatusBarManager::class.java).requestAddTileService(
        ComponentName(context, QuickEntryTileService::class.java),
        context.getString(R.string.log_expense),
        Icon.createWithResource(context, R.drawable.ic_log_expense),
        context.mainExecutor,
    ) { }
}

/** Asks the launcher to pin a separate "Log Expense" icon that opens the pop-up. */
private fun pinShortcut(context: Context) {
    val shortcut = ShortcutInfoCompat.Builder(context, "log_expense_pinned")
        .setShortLabel(context.getString(R.string.log_expense))
        .setLongLabel(context.getString(R.string.log_expense_long))
        .setIcon(IconCompat.createWithResource(context, R.mipmap.ic_launcher))
        .setIntent(Intent(context, QuickEntryActivity::class.java).setAction(Intent.ACTION_VIEW))
        .build()
    ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
}
