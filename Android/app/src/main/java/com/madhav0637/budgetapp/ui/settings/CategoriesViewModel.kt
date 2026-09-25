package com.madhav0637.budgetapp.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.madhav0637.budgetapp.BudgetApplication
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.CategoryDao
import com.madhav0637.budgetapp.data.CategoryWithCount
import com.madhav0637.budgetapp.domain.CategoryService
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** Every change goes through [CategoryService], so the same rules apply as everywhere else. */
class CategoriesViewModel(categoryDao: CategoryDao, private val service: CategoryService) : ViewModel() {
    /** Most-used first, with each category's expense count. */
    val categories: StateFlow<List<CategoryWithCount>> = categoryDao.observeByUsageWithCounts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun add(name: String, emoji: String, onDone: () -> Unit, onError: (String) -> Unit) =
        run(onDone, onError) { service.add(name, emoji) }

    fun update(category: Category, name: String, emoji: String, onDone: () -> Unit, onError: (String) -> Unit) =
        run(onDone, onError) { service.update(category, name, emoji) }

    fun moveAll(from: Category, to: Category, onDone: () -> Unit, onError: (String) -> Unit) =
        run(onDone, onError) { service.moveAllExpenses(from, to) }

    fun delete(category: Category, onDone: () -> Unit, onError: (String) -> Unit) =
        run(onDone, onError) { service.delete(category) }

    private fun run(onDone: () -> Unit, onError: (String) -> Unit, action: suspend () -> Unit) = viewModelScope.launch {
        runCatching { action() }
            .onSuccess { onDone() }
            .onFailure { onError(it.message ?: "Something went wrong.") }
    }

    companion object {
        val Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as BudgetApplication
                CategoriesViewModel(app.database.categoryDao(), app.categoryService)
            }
        }
    }
}
