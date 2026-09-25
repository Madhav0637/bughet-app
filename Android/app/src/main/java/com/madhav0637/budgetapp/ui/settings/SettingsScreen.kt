package com.madhav0637.budgetapp.ui.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel

/**
 * The Settings tab. It has its own small back stack: Settings → Categories → one category.
 * CSV/PDF export and the quick-entry guide join in milestone A6.
 */
@Composable
fun SettingsTab() {
    // "settings", "categories", or the id of the category being edited.
    var screen by rememberSaveable { mutableStateOf(SETTINGS) }
    val categoriesViewModel: CategoriesViewModel = viewModel(factory = CategoriesViewModel.Factory)

    BackHandler(enabled = screen != SETTINGS) {
        screen = if (screen == CATEGORIES) SETTINGS else CATEGORIES
    }

    when (screen) {
        SETTINGS -> SettingsScreen(onCategories = { screen = CATEGORIES })
        CATEGORIES -> CategoriesScreen(
            viewModel = categoriesViewModel,
            onBack = { screen = SETTINGS },
            onOpen = { screen = it.id },
        )
        else -> CategoryDetailScreen(
            categoryId = screen,
            viewModel = categoriesViewModel,
            onBack = { screen = CATEGORIES },
        )
    }
}

private const val SETTINGS = "settings"
private const val CATEGORIES = "categories"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsScreen(onCategories: () -> Unit) {
    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        Column(Modifier.padding(padding)) {
            SettingsRow(emoji = "🏷️", title = "Categories", detail = "Add, rename, move or delete categories", onClick = onCategories)
        }
    }
}

@Composable
internal fun SettingsRow(emoji: String, title: String, detail: String, onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 16.dp),
    ) {
        Text(emoji, fontSize = 24.sp)
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            Text(detail, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null)
    }
}
