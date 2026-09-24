package com.madhav0637.budgetapp.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.madhav0637.budgetapp.BudgetApplication
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.CategoryDao
import com.madhav0637.budgetapp.data.Expense
import com.madhav0637.budgetapp.data.ExpenseDao
import com.madhav0637.budgetapp.domain.ExpenseService
import com.madhav0637.budgetapp.domain.HistoryFilter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant

data class HistoryUiState(
    val groups: List<HistoryFilter.DayGroup> = emptyList(),
    /** Most-used first, for the filter chips and the edit sheet. */
    val categories: List<Category> = emptyList(),
    val filter: HistoryFilter = HistoryFilter(),
    val hasAnyExpenses: Boolean = false,
    val isLoading: Boolean = true,
)

class HistoryViewModel(
    expenseDao: ExpenseDao,
    categoryDao: CategoryDao,
    private val expenseService: ExpenseService,
) : ViewModel() {
    private val filter = MutableStateFlow(HistoryFilter())

    val state: StateFlow<HistoryUiState> =
        combine(expenseDao.observeAllWithCategory(), categoryDao.observeByUsage(), filter) { expenses, categories, filter ->
            HistoryUiState(
                groups = HistoryFilter.groupByDay(filter.apply(expenses)),
                categories = categories,
                filter = filter,
                hasAnyExpenses = expenses.isNotEmpty(),
                isLoading = false,
            )
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HistoryUiState())

    fun setSearch(text: String) = filter.update { it.copy(searchText = text) }

    fun setCategory(categoryId: String?) = filter.update { it.copy(categoryId = categoryId) }

    fun delete(expense: Expense) = viewModelScope.launch { expenseService.delete(expense) }

    fun restore(expense: Expense) = viewModelScope.launch { expenseService.restore(expense) }

    fun update(
        expense: Expense, merchant: String, amount: Long, categoryId: String, date: Instant,
        onSaved: () -> Unit, onError: (String) -> Unit,
    ) = viewModelScope.launch {
        runCatching { expenseService.update(expense, merchant, amount, categoryId, date) }
            .onSuccess { onSaved() }
            .onFailure { onError(it.message ?: "Couldn't save the changes.") }
    }

    companion object {
        val Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as BudgetApplication
                HistoryViewModel(app.database.expenseDao(), app.database.categoryDao(), app.expenseService)
            }
        }
    }
}
