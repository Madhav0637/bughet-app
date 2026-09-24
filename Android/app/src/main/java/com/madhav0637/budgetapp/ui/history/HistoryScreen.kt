package com.madhav0637.budgetapp.ui.history

import android.content.Intent
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.HistoryFilter
import com.madhav0637.budgetapp.ui.components.ExpenseRow
import com.madhav0637.budgetapp.ui.quickentry.QuickEntryActivity
import kotlinx.coroutines.launch

/** Every expense, grouped by day. Search by merchant, filter by category, swipe to delete (with Undo), tap to edit. */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HistoryScreen(viewModel: HistoryViewModel = viewModel(factory = HistoryViewModel.Factory)) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    // The search text lives here (not in the ViewModel's combined state) so typing never lags or jumps.
    var query by rememberSaveable { mutableStateOf("") }
    LaunchedEffect(query) { viewModel.setSearch(query) }
    var editing by remember { mutableStateOf<ExpenseWithCategory?>(null) }

    fun deleteWithUndo(item: ExpenseWithCategory) {
        viewModel.delete(item.expense)
        scope.launch {
            snackbar.currentSnackbarData?.dismiss()
            val result = snackbar.showSnackbar("Deleted ${item.expense.merchant}", actionLabel = "Undo", duration = SnackbarDuration.Long)
            if (result == SnackbarResult.ActionPerformed) viewModel.restore(item.expense)
        }
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("History") }) },
        snackbarHost = { SnackbarHost(snackbar) },
        floatingActionButton = {
            FloatingActionButton(onClick = { context.startActivity(Intent(context, QuickEntryActivity::class.java)) }) {
                Icon(Icons.Filled.Add, contentDescription = "Log Expense")
            }
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                placeholder = { Text("Search merchants") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                trailingIcon = {
                    if (query.isNotEmpty()) {
                        IconButton(onClick = { query = "" }) { Icon(Icons.Filled.Clear, contentDescription = "Clear search") }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(28.dp),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            )
            CategoryChips(state, onSelect = viewModel::setCategory)

            when {
                state.isLoading -> Unit
                !state.hasAnyExpenses -> EmptyMessage("No Expenses Yet", "Use the Log Expense tile, shortcut or icon to add one.")
                state.groups.isEmpty() -> EmptyMessage("No Matching Expenses", "Try a different search or category.")
                else -> LazyColumn(contentPadding = PaddingValues(bottom = 96.dp)) {
                    state.groups.forEach { group ->
                        stickyHeader(key = "day-${group.day}") { DayHeader(group) }
                        items(group.expenses, key = { it.expense.id }) { item ->
                            SwipeToDeleteRow(item, onDelete = { deleteWithUndo(item) }, onClick = { editing = item })
                            HorizontalDivider(Modifier.padding(start = 56.dp))
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CategoryChips(state: HistoryUiState, onSelect: (String?) -> Unit) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 4.dp),
    ) {
        FilterChip(selected = state.filter.categoryId == null, onClick = { onSelect(null) }, label = { Text("All") })
        state.categories.forEach { category ->
            val selected = state.filter.categoryId == category.id
            FilterChip(
                selected = selected,
                // Tapping the selected chip again clears the filter.
                onClick = { onSelect(if (selected) null else category.id) },
                label = { Text("${category.emoji} ${category.name}") },
            )
        }
    }
}

@Composable
private fun DayHeader(group: HistoryFilter.DayGroup) {
    Text(
        HistoryFilter.title(group.day),
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToDeleteRow(item: ExpenseWithCategory, onDelete: () -> Unit, onClick: () -> Unit) {
    val dismissState = rememberSwipeToDismissBoxState()
    LaunchedEffect(dismissState.currentValue) {
        if (dismissState.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onDelete()
            // The list remembers each row's swipe state by expense id. Reset it now, or an expense brought back
            // by Undo (same id) would reappear already swiped away and be deleted again straight away.
            dismissState.snapTo(SwipeToDismissBoxValue.Settled)
        }
    }
    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                contentAlignment = Alignment.CenterEnd,
                modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.errorContainer).padding(horizontal = 24.dp),
            ) {
                Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.onErrorContainer)
            }
        },
    ) {
        ExpenseRow(item, modifier = Modifier.background(MaterialTheme.colorScheme.surface).clickable(onClick = onClick))
    }
}

@Composable
private fun EmptyMessage(title: String, detail: String) {
    Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("₹", fontSize = 48.sp, color = MaterialTheme.colorScheme.outline)
            Text(title, style = MaterialTheme.typography.titleLarge)
            Text(detail, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
