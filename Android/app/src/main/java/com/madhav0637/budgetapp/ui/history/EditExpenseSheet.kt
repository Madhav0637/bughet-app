package com.madhav0637.budgetapp.ui.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.digitsOnly
import java.time.Instant
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

private val dateLabel = DateTimeFormatter.ofPattern("EEE, d MMM yyyy", Locale.ENGLISH)
private val timeLabel = DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH)

/** Edit an expense's merchant, amount, category, date and time. Save stays disabled until everything is valid. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditExpenseSheet(
    item: ExpenseWithCategory,
    categories: List<Category>,
    onSave: (merchant: String, amount: Long, categoryId: String, date: Instant) -> Unit,
    onDismiss: () -> Unit,
) {
    val zone = ZoneId.systemDefault()
    val original = item.expense.date.atZone(zone).toLocalDateTime()

    var merchant by rememberSaveable { mutableStateOf(item.expense.merchant) }
    var amountText by rememberSaveable { mutableStateOf(item.expense.amount.toString()) }
    var categoryId by rememberSaveable { mutableStateOf(item.category.id) }
    var day by rememberSaveable { mutableStateOf(original.toLocalDate()) }
    var time by rememberSaveable { mutableStateOf(original.toLocalTime().withSecond(0).withNano(0)) }
    var pickingDate by remember { mutableStateOf(false) }
    var pickingTime by remember { mutableStateOf(false) }
    var categoryMenuOpen by remember { mutableStateOf(false) }

    val amount = amountText.toLongOrNull()?.takeIf { it > 0 }
    val category = categories.firstOrNull { it.id == categoryId } ?: item.category
    val canSave = merchant.isNotBlank() && amount != null

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 16.dp).navigationBarsPadding().imePadding(),
        ) {
            Text("Edit Expense", style = MaterialTheme.typography.titleLarge)

            OutlinedTextField(
                value = merchant,
                onValueChange = { merchant = it },
                label = { Text("On what?") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = amountText,
                onValueChange = { amountText = digitsOnly(it).take(9) },
                label = { Text("Amount (₹)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
            )

            Box {
                OutlinedButton(onClick = { categoryMenuOpen = true }, modifier = Modifier.fillMaxWidth().height(52.dp)) {
                    Text("Category: ${category.emoji} ${category.name}")
                }
                DropdownMenu(expanded = categoryMenuOpen, onDismissRequest = { categoryMenuOpen = false }) {
                    categories.forEach { option ->
                        DropdownMenuItem(
                            text = { Text("${option.emoji}  ${option.name}") },
                            onClick = {
                                categoryId = option.id
                                categoryMenuOpen = false
                            },
                        )
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = { pickingDate = true }, modifier = Modifier.weight(1.4f).height(52.dp)) {
                    Text(dateLabel.format(day))
                }
                OutlinedButton(onClick = { pickingTime = true }, modifier = Modifier.weight(1f).height(52.dp)) {
                    Text(timeLabel.format(time))
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                FilledTonalButton(onClick = onDismiss, modifier = Modifier.weight(1f).height(52.dp)) { Text("Cancel") }
                Button(
                    onClick = { amount?.let { onSave(merchant, it, category.id, LocalDateTime.of(day, time).atZone(zone).toInstant()) } },
                    enabled = canSave,
                    modifier = Modifier.weight(1f).height(52.dp),
                ) { Text("Save") }
            }
        }
    }

    if (pickingDate) {
        // The date picker works in UTC midnights, so convert to and from a plain calendar date.
        val state = rememberDatePickerState(initialSelectedDateMillis = day.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli())
        DatePickerDialog(
            onDismissRequest = { pickingDate = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { day = Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate() }
                    pickingDate = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickingDate = false }) { Text("Cancel") } },
        ) { DatePicker(state = state) }
    }

    if (pickingTime) {
        val state = rememberTimePickerState(initialHour = time.hour, initialMinute = time.minute)
        AlertDialog(
            onDismissRequest = { pickingTime = false },
            confirmButton = {
                TextButton(onClick = {
                    time = LocalTime.of(state.hour, state.minute)
                    pickingTime = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickingTime = false }) { Text("Cancel") } },
            text = { TimePicker(state = state) },
        )
    }
}
