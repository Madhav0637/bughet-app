package com.madhav0637.budgetapp.ui.quickentry

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.madhav0637.budgetapp.ui.theme.BudgetAppTheme

/**
 * The quick-entry pop-up. Its window is see-through, so it floats over whatever app was on screen.
 * Opened by the Quick Settings tile, the launcher shortcut, or the separate "Log Expense" launcher entry
 * (which brand gestures such as Samsung's side-button double press can be set to open).
 */
class QuickEntryActivity : ComponentActivity() {
    private val viewModel: QuickEntryViewModel by viewModels { QuickEntryViewModel.Factory }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BudgetAppTheme {
                val categories by viewModel.categories.collectAsStateWithLifecycle()
                QuickEntryScreen(
                    categories = categories,
                    onSave = { merchant, amount, category ->
                        viewModel.save(
                            merchant, amount, category,
                            onSaved = ::finish, // silent save, like iOS
                            onError = { Toast.makeText(this, it, Toast.LENGTH_LONG).show() },
                        )
                    },
                    onCancel = ::finish,
                )
            }
        }
    }
}
