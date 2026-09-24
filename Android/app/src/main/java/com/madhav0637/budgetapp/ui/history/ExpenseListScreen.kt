package com.madhav0637.budgetapp.ui.history

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
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.madhav0637.budgetapp.BudgetApplication
import com.madhav0637.budgetapp.data.ExpenseDao
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.inr
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

class ExpenseListViewModel(dao: ExpenseDao) : ViewModel() {
    val expenses: StateFlow<List<ExpenseWithCategory>> = dao.observeAllWithCategory()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    companion object {
        val Factory = viewModelFactory {
            initializer { ExpenseListViewModel((this[APPLICATION_KEY] as BudgetApplication).database.expenseDao()) }
        }
    }
}

/** Milestone A1: a plain list to confirm quick entry saves. Becomes the History tab in A3. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpenseListScreen(viewModel: ExpenseListViewModel = viewModel(factory = ExpenseListViewModel.Factory)) {
    val expenses by viewModel.expenses.collectAsStateWithLifecycle()

    Scaffold(topBar = { TopAppBar(title = { Text("Expenses") }) }) { padding ->
        if (expenses.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding).padding(32.dp), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("₹", fontSize = 48.sp, color = MaterialTheme.colorScheme.outline)
                    Text("No Expenses Yet", style = MaterialTheme.typography.titleLarge)
                    Text(
                        "Swipe down from the top and tap the Log Expense tile, or long-press the app icon.",
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        } else {
            LazyColumn(contentPadding = PaddingValues(bottom = 24.dp), modifier = Modifier.padding(padding)) {
                items(expenses, key = { it.expense.id }) { item ->
                    ExpenseRow(item)
                    HorizontalDivider(Modifier.padding(start = 64.dp))
                }
            }
        }
    }
}

private val timeFormat = DateTimeFormatter.ofPattern("d MMM, h:mm a", Locale.forLanguageTag("en-IN"))

@Composable
private fun ExpenseRow(item: ExpenseWithCategory) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Text(item.category.emoji, fontSize = 26.sp)
        Column(Modifier.weight(1f)) {
            Text(item.expense.merchant, style = MaterialTheme.typography.bodyLarge)
            Text(
                timeFormat.format(item.expense.date.atZone(ZoneId.systemDefault())),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Text(item.expense.amount.inr(), style = MaterialTheme.typography.bodyLarge)
    }
}
