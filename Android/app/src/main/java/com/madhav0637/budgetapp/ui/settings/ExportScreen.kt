package com.madhav0637.budgetapp.ui.settings

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
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
import com.madhav0637.budgetapp.domain.ExportFormat
import com.madhav0637.budgetapp.export.ExportWriter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class ExportViewModel(expenseDao: ExpenseDao) : ViewModel() {
    val expenses: StateFlow<List<ExpenseWithCategory>?> = expenseDao.observeAllWithCategory()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    companion object {
        val Factory = viewModelFactory {
            initializer { ExportViewModel((this[APPLICATION_KEY] as BudgetApplication).database.expenseDao()) }
        }
    }
}

/** Choose how to export: a CSV spreadsheet or a PDF report. The file is written, then opened in the share sheet. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExportScreen(onBack: () -> Unit, viewModel: ExportViewModel = viewModel(factory = ExportViewModel.Factory)) {
    val expenses by viewModel.expenses.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    val count = expenses?.size ?: 0

    fun export(format: ExportFormat) {
        val items = expenses ?: return
        scope.launch {
            runCatching { withContext(Dispatchers.IO) { ExportWriter.write(format, items, exportDirectory(context)) } }
                .onSuccess { share(context, it, format) }
                .onFailure { snackbar.showSnackbar("Couldn't create the file: ${it.message}") }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Export Data") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") } },
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { padding ->
        Column(Modifier.padding(padding)) {
            Text(
                "Choose a format",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            )
            SettingsRow(
                emoji = "📊",
                title = "Spreadsheet (CSV)",
                detail = "Every expense as rows. Opens in Excel, Numbers or Google Sheets.",
                enabled = count > 0,
                onClick = { export(ExportFormat.Csv) },
            )
            SettingsRow(
                emoji = "📄",
                title = "Report (PDF)",
                detail = "A printable summary: total, spending by category, and every expense.",
                enabled = count > 0,
                onClick = { export(ExportFormat.Pdf) },
            )
            Text(
                if (count == 0) {
                    "Nothing to export yet."
                } else {
                    "Includes all $count ${if (count == 1) "expense" else "expenses"}. " +
                        "Your data lives only on this phone, so an export is also your backup."
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            )
        }
    }
}

/** Exports go in the app's cache folder, which [FileProvider] is allowed to share (see res/xml/file_paths.xml). */
private fun exportDirectory(context: Context) = File(context.cacheDir, "export")

private fun share(context: Context, file: File, format: ExportFormat) {
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    val send = Intent(Intent.ACTION_SEND).apply {
        type = format.mimeType
        putExtra(Intent.EXTRA_STREAM, uri)
        putExtra(Intent.EXTRA_SUBJECT, file.name)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(Intent.createChooser(send, "Export ${file.name}"))
}
