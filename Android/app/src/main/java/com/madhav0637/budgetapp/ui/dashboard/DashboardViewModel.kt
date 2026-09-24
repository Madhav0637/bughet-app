package com.madhav0637.budgetapp.ui.dashboard

import android.content.SharedPreferences
import androidx.core.content.edit
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
import com.madhav0637.budgetapp.domain.Period
import com.madhav0637.budgetapp.domain.PeriodCalculator
import com.madhav0637.budgetapp.domain.SpendingSummary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.Instant

data class DashboardUiState(
    val period: Period = Period.Month,
    val summary: SpendingSummary? = null,
    val categories: List<Category> = emptyList(),
)

class DashboardViewModel(
    expenseDao: ExpenseDao,
    categoryDao: CategoryDao,
    private val expenseService: ExpenseService,
    private val prefs: SharedPreferences,
) : ViewModel() {
    /** Remembered between launches, like iOS. Starts on Month. */
    private val period = MutableStateFlow(
        Period.entries.firstOrNull { it.name == prefs.getString(PERIOD_KEY, null) } ?: Period.Month,
    )

    val state: StateFlow<DashboardUiState> =
        combine(expenseDao.observeAllWithCategory(), categoryDao.observeByUsage(), period) { expenses, categories, period ->
            DashboardUiState(
                period = period,
                summary = SpendingSummary(expenses, PeriodCalculator().range(period)),
                categories = categories,
            )
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DashboardUiState(period = period.value))

    fun setPeriod(value: Period) {
        period.value = value
        prefs.edit { putString(PERIOD_KEY, value.name) }
    }

    fun update(
        expense: Expense, merchant: String, amount: Long, categoryId: String, date: Instant,
        onSaved: () -> Unit, onError: (String) -> Unit,
    ) = viewModelScope.launch {
        runCatching { expenseService.update(expense, merchant, amount, categoryId, date) }
            .onSuccess { onSaved() }
            .onFailure { onError(it.message ?: "Couldn't save the changes.") }
    }

    companion object {
        private const val PERIOD_KEY = "dashboardPeriod"

        val Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as BudgetApplication
                DashboardViewModel(
                    app.database.expenseDao(),
                    app.database.categoryDao(),
                    app.expenseService,
                    app.getSharedPreferences("settings", android.content.Context.MODE_PRIVATE),
                )
            }
        }
    }
}
