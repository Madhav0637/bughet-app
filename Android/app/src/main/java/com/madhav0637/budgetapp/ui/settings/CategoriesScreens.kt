package com.madhav0637.budgetapp.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.CategoryWithCount
import com.madhav0637.budgetapp.domain.CategoryError
import com.madhav0637.budgetapp.domain.CategoryRules
import kotlinx.coroutines.launch

private fun expenses(count: Int) = "$count ${if (count == 1) "expense" else "expenses"}"

/** All categories, most-used first, with how many expenses each has. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoriesScreen(viewModel: CategoriesViewModel, onBack: () -> Unit, onOpen: (Category) -> Unit) {
    val categories by viewModel.categories.collectAsStateWithLifecycle()
    var adding by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Categories") }, navigationIcon = { BackButton(onBack) }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { adding = true }) { Icon(Icons.Filled.Add, contentDescription = "Add Category") }
        },
    ) { padding ->
        LazyColumn(contentPadding = PaddingValues(bottom = 96.dp), modifier = Modifier.padding(padding)) {
            items(categories, key = { it.category.id }) { item ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                    modifier = Modifier.fillMaxWidth().clickable { onOpen(item.category) }.padding(horizontal = 16.dp, vertical = 14.dp),
                ) {
                    Text(item.category.emoji, fontSize = 26.sp)
                    Text(item.category.name, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    Text(expenses(item.expenseCount), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null)
                }
                HorizontalDivider(Modifier.padding(start = 56.dp))
            }
        }
    }

    if (adding) {
        AddCategoryDialog(
            onAdd = { name, emoji, onError -> viewModel.add(name, emoji, onDone = { adding = false }, onError = onError) },
            onDismiss = { adding = false },
        )
    }
}

@Composable
private fun AddCategoryDialog(
    onAdd: (name: String, emoji: String, onError: (String) -> Unit) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by rememberSaveable { mutableStateOf("") }
    var emoji by rememberSaveable { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    val canSave = name.isNotBlank() && CategoryRules.isValidEmoji(emoji)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New Category") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                CategoryFields(name, { name = it; error = null }, emoji, { emoji = it; error = null })
                Text(
                    error ?: "Tap Emoji, then use the 🙂 key on the keyboard to pick one.",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (error != null) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        confirmButton = { TextButton(onClick = { onAdd(name, emoji) { error = it } }, enabled = canSave) { Text("Save") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

/** Name and emoji fields, shared by adding and editing. The emoji box always keeps exactly one character. */
@Composable
private fun CategoryFields(name: String, onName: (String) -> Unit, emoji: String, onEmoji: (String) -> Unit) {
    OutlinedTextField(
        value = name,
        onValueChange = onName,
        label = { Text("Name") },
        placeholder = { Text("e.g. Rent") },
        singleLine = true,
        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
        modifier = Modifier.fillMaxWidth(),
    )
    OutlinedTextField(
        value = emoji,
        onValueChange = { onEmoji(CategoryRules.lastCharacter(it)) },
        label = { Text("Emoji") },
        placeholder = { Text("🙂") },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
    )
}

/** Edit a category's name and emoji, move all its expenses elsewhere, or delete it once it's empty. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoryDetailScreen(categoryId: String, viewModel: CategoriesViewModel, onBack: () -> Unit) {
    val all by viewModel.categories.collectAsStateWithLifecycle()
    val item = all.firstOrNull { it.category.id == categoryId }
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val showError: (String) -> Unit = { message -> scope.launch { snackbar.showSnackbar(message) } }

    Scaffold(
        topBar = { TopAppBar(title = { Text(item?.category?.name ?: "") }, navigationIcon = { BackButton(onBack) }) },
        snackbarHost = { SnackbarHost(snackbar) },
    ) { padding ->
        if (item == null) return@Scaffold // just deleted; onBack has already been called
        val category = item.category
        val others = all.filter { it.category.id != categoryId }.map { it.category }

        var name by rememberSaveable(category.id) { mutableStateOf(category.name) }
        var emoji by rememberSaveable(category.id) { mutableStateOf(category.emoji) }
        var moveTarget by remember { mutableStateOf<Category?>(null) }
        var moveMenuOpen by remember { mutableStateOf(false) }
        var confirmingDelete by remember { mutableStateOf(false) }

        val changed = name.trim() != category.name || emoji != category.emoji
        val canSave = changed && name.isNotBlank() && CategoryRules.isValidEmoji(emoji)
        val deleteBlockedReason = when {
            item.expenseCount > 0 -> CategoryError.InUse(item.expenseCount).message
            others.isEmpty() -> CategoryError.LastCategory.message
            else -> null
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.padding(padding).padding(horizontal = 16.dp, vertical = 8.dp),
        ) {
            CategoryFields(name, { name = it }, emoji, { emoji = it })
            Button(
                onClick = { viewModel.update(category, name, emoji, onDone = {}, onError = showError) },
                enabled = canSave,
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) { Text("Save Changes") }

            if (item.expenseCount > 0) {
                Box {
                    OutlinedButton(
                        onClick = { moveMenuOpen = true },
                        enabled = others.isNotEmpty(),
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                    ) { Text("Move all ${expenses(item.expenseCount)} to…") }
                    DropdownMenu(expanded = moveMenuOpen, onDismissRequest = { moveMenuOpen = false }) {
                        others.forEach { target ->
                            DropdownMenuItem(
                                text = { Text("${target.emoji}  ${target.name}") },
                                onClick = {
                                    moveTarget = target
                                    moveMenuOpen = false
                                },
                            )
                        }
                    }
                }
            }

            OutlinedButton(
                onClick = { confirmingDelete = true },
                enabled = deleteBlockedReason == null,
                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) { Text("Delete Category") }
            deleteBlockedReason?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        moveTarget?.let { target ->
            AlertDialog(
                onDismissRequest = { moveTarget = null },
                title = { Text("Move ${expenses(item.expenseCount)}?") },
                text = { Text("From ${category.emoji} ${category.name} to ${target.emoji} ${target.name}.") },
                confirmButton = {
                    TextButton(onClick = {
                        moveTarget = null
                        viewModel.moveAll(category, target, onDone = {}, onError = showError)
                    }) { Text("Move") }
                },
                dismissButton = { TextButton(onClick = { moveTarget = null }) { Text("Cancel") } },
            )
        }

        if (confirmingDelete) {
            AlertDialog(
                onDismissRequest = { confirmingDelete = false },
                title = { Text("Delete ${category.emoji} ${category.name}?") },
                confirmButton = {
                    TextButton(onClick = {
                        confirmingDelete = false
                        viewModel.delete(category, onDone = onBack, onError = showError)
                    }) { Text("Delete", color = MaterialTheme.colorScheme.error) }
                },
                dismissButton = { TextButton(onClick = { confirmingDelete = false }) { Text("Cancel") } },
            )
        }
    }
}

@Composable
private fun BackButton(onBack: () -> Unit) {
    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
}
