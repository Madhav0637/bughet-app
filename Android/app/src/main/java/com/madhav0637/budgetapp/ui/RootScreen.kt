package com.madhav0637.budgetapp.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import com.madhav0637.budgetapp.ui.dashboard.DashboardScreen
import com.madhav0637.budgetapp.ui.history.HistoryScreen

private enum class Tab(val label: String, val icon: ImageVector) {
    Dashboard("Dashboard", Icons.Filled.Home),
    History("History", Icons.AutoMirrored.Filled.List),
}

/** The app's tabs. Settings joins in milestone A5. */
@Composable
fun RootScreen() {
    var tab by rememberSaveable { mutableStateOf(Tab.Dashboard) }

    Scaffold(
        // Each tab draws its own top bar, so only the bottom tab bar's space is handled here.
        contentWindowInsets = WindowInsets(0),
        bottomBar = {
            NavigationBar {
                Tab.entries.forEach { item ->
                    NavigationBarItem(
                        selected = tab == item,
                        onClick = { tab = item },
                        icon = { Icon(item.icon, contentDescription = null) },
                        label = { Text(item.label) },
                    )
                }
            }
        },
    ) { padding ->
        // The tab bar already covers the phone's navigation bar, so stop the tabs adding that space again.
        Box(Modifier.padding(padding).consumeWindowInsets(WindowInsets.navigationBars)) {
            when (tab) {
                Tab.Dashboard -> DashboardScreen(onSeeAll = { tab = Tab.History })
                Tab.History -> HistoryScreen()
            }
        }
    }
}
