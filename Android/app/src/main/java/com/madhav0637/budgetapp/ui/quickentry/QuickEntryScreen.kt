package com.madhav0637.budgetapp.ui.quickentry

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.domain.digitsOnly

private enum class Step { Merchant, Amount, Category }

/**
 * A pop-up card at the top of the screen over a dimmed background: On what? → Amount → Category.
 * Tapping a category saves. Tapping outside the card cancels.
 */
@Composable
fun QuickEntryScreen(
    categories: List<Category>,
    onSave: (merchant: String, amount: Long, category: Category) -> Unit,
    onCancel: () -> Unit,
) {
    var step by rememberSaveable { mutableStateOf(Step.Merchant) }
    var merchant by rememberSaveable { mutableStateOf("") }
    var amountText by rememberSaveable { mutableStateOf("") }
    val amount = amountText.toLongOrNull()?.takeIf { it > 0 }

    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.4f))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onCancel),
    ) {
        Surface(
            shape = RoundedCornerShape(32.dp),
            color = MaterialTheme.colorScheme.surfaceContainerHigh,
            tonalElevation = 6.dp,
            modifier = Modifier
                .safeDrawingPadding()
                .padding(12.dp)
                .fillMaxWidth()
                // Swallow taps on the card so they don't reach the background and cancel.
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {},
        ) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                when (step) {
                    Step.Merchant -> {
                        val goNext = { if (merchant.isNotBlank()) step = Step.Amount }
                        BigTextBox(
                            value = merchant,
                            onValueChange = { merchant = it },
                            placeholder = "On what?",
                            keyboardOptions = KeyboardOptions(
                                capitalization = KeyboardCapitalization.Sentences,
                                imeAction = ImeAction.Next,
                            ),
                            onImeAction = goNext,
                        )
                        CancelNextRow(nextEnabled = merchant.isNotBlank(), onCancel = onCancel, onNext = goNext)
                    }

                    Step.Amount -> {
                        val goNext = { if (amount != null) step = Step.Category }
                        BigTextBox(
                            value = amountText,
                            onValueChange = { amountText = digitsOnly(it).take(9) },
                            placeholder = "Amount (₹)",
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Next),
                            onImeAction = goNext,
                        )
                        CancelNextRow(nextEnabled = amount != null, onCancel = onCancel, onNext = goNext)
                    }

                    Step.Category -> {
                        Text("Category", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.heightIn(max = 460.dp),
                        ) {
                            items(categories, key = { it.id }) { category ->
                                CategoryRow(category) { amount?.let { onSave(merchant, it, category) } }
                            }
                        }
                        FilledTonalButton(onClick = onCancel, modifier = Modifier.fillMaxWidth().height(52.dp)) {
                            Text("Cancel", fontSize = 17.sp)
                        }
                    }
                }
            }
        }
    }
}

/** The big, bold, centred box used by both text steps, so they look the same. */
@Composable
private fun BigTextBox(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardOptions: KeyboardOptions,
    onImeAction: () -> Unit,
) {
    val focus = remember { FocusRequester() }
    val style = TextStyle(
        fontSize = 34.sp,
        fontWeight = FontWeight.Bold,
        textAlign = TextAlign.Center,
        color = MaterialTheme.colorScheme.onSurface,
    )
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = style,
        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
        keyboardOptions = keyboardOptions,
        keyboardActions = KeyboardActions(onAny = { onImeAction() }),
        modifier = Modifier.fillMaxWidth().focusRequester(focus),
        decorationBox = { field ->
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceContainerHighest, RoundedCornerShape(24.dp))
                    .padding(vertical = 22.dp, horizontal = 16.dp),
            ) {
                if (value.isEmpty()) {
                    Text(placeholder, style = style.copy(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)))
                }
                field()
            }
        },
    )
    // Put the cursor in the box straight away, so the keyboard is ready.
    LaunchedEffect(placeholder) { focus.requestFocus() }
}

@Composable
private fun CancelNextRow(nextEnabled: Boolean, onCancel: () -> Unit, onNext: () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        FilledTonalButton(onClick = onCancel, modifier = Modifier.weight(1f).height(52.dp)) {
            Text("Cancel", fontSize = 17.sp)
        }
        Button(onClick = onNext, enabled = nextEnabled, modifier = Modifier.weight(1f).height(52.dp)) {
            Text("Next", fontSize = 17.sp)
        }
    }
}

@Composable
private fun CategoryRow(category: Category, onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceContainerHighest, RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
    ) {
        Text(category.emoji, fontSize = 24.sp)
        Text(category.name, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
    }
}
