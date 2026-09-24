package com.madhav0637.budgetapp.ui.dashboard

import android.content.Intent
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.Period
import com.madhav0637.budgetapp.domain.inr
import com.madhav0637.budgetapp.ui.components.ExpenseRow
import com.madhav0637.budgetapp.ui.history.EditExpenseSheet
import com.madhav0637.budgetapp.ui.quickentry.QuickEntryActivity
import kotlinx.coroutines.launch

/** Spending for the current week, month or year: the total, each category, and the latest expenses. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(onSeeAll: () -> Unit, viewModel: DashboardViewModel = viewModel(factory = DashboardViewModel.Factory)) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var editing by remember { mutableStateOf<ExpenseWithCategory?>(null) }
    val summary = state.summary

    Scaffold(
        topBar = { TopAppBar(title = { Text("Dashboard") }) },
        snackbarHost = { SnackbarHost(snackbar) },
        floatingActionButton = {
            FloatingActionButton(onClick = { context.startActivity(Intent(context, QuickEntryActivity::class.java)) }) {
                Icon(Icons.Filled.Add, contentDescription = "Log Expense")
            }
        },
    ) { padding ->
        LazyColumn(
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(padding),
        ) {
            item { PeriodSwitcher(state.period, viewModel::setPeriod) }
            item { TotalCard(state.period, summary?.total ?: 0) }

            if (summary != null && summary.total == 0L) {
                item { EmptyPeriod(state.period) }
            } else if (summary != null) {
                item { SectionTitle("By Category") }
                item {
                    Card {
                        summary.categoryTotals.forEachIndexed { index, total ->
                            if (index > 0) HorizontalDivider(Modifier.padding(start = 56.dp))
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(14.dp),
                                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                            ) {
                                Text(total.category.emoji, fontSize = 26.sp)
                                Text(total.category.name, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                                Text(total.amount.inr(), style = MaterialTheme.typography.bodyLarge)
                            }
                        }
                    }
                }
                item {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        SectionTitle("Recent", Modifier.weight(1f))
                        TextButton(onClick = onSeeAll) { Text("See All") }
                    }
                }
                item {
                    Card {
                        summary.recent.forEachIndexed { index, item ->
                            if (index > 0) HorizontalDivider(Modifier.padding(start = 56.dp))
                            ExpenseRow(item, showsDate = true, modifier = Modifier.clickable { editing = item })
                        }
                    }
                }
            }
        }
    }

    editing?.let { item ->
        EditExpenseSheet(
            item = item,
            categories = state.categories,
            onSave = { merchant, amount, categoryId, date ->
                viewModel.update(
                    item.expense, merchant, amount, categoryId, date,
                    onSaved = { editing = null },
                    onError = { message -> scope.launch { snackbar.showSnackbar(message) } },
                )
            },
            onDismiss = { editing = null },
        )
    }
}

@Composable
private fun PeriodSwitcher(selected: Period, onSelect: (Period) -> Unit) {
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        Period.entries.forEachIndexed { index, period ->
            SegmentedButton(
                selected = period == selected,
                onClick = { onSelect(period) },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = Period.entries.size),
            ) { Text(period.title) }
        }
    }
}

@Composable
private fun TotalCard(period: Period, total: Long) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp),
        ) {
            Text("Spent ${period.phrase}", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onPrimaryContainer)
            // Slides the number when the total or period changes.
            AnimatedContent(targetState = total, label = "total") { value ->
                Text(value.inr(), fontSize = 48.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimaryContainer)
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(text, style = MaterialTheme.typography.titleMedium, modifier = modifier.padding(start = 4.dp))
}

@Composable
private fun EmptyPeriod(period: Period) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(vertical = 48.dp, horizontal = 24.dp),
    ) {
        Text("₹", fontSize = 48.sp, color = MaterialTheme.colorScheme.outline)
        Text("No Expenses ${titleCase(period.phrase)}", style = MaterialTheme.typography.titleLarge)
        Text(
            "Use the Log Expense tile, shortcut or icon to add one.",
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/** "this month" → "This Month". */
private fun titleCase(text: String): String = text.split(" ").joinToString(" ") { word -> word.replaceFirstChar(Char::uppercase) }
