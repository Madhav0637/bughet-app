package com.madhav0637.budgetapp.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.inr
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val timeOnly = DateTimeFormatter.ofPattern("h:mm a", Locale.ENGLISH)
private val dateAndTime = DateTimeFormatter.ofPattern("d MMM, h:mm a", Locale.ENGLISH)

/** One expense in a list: category emoji, merchant, when, and amount. Shared by History and the Dashboard. */
@Composable
fun ExpenseRow(item: ExpenseWithCategory, modifier: Modifier = Modifier, showsDate: Boolean = false) {
    val time = item.expense.date.atZone(ZoneId.systemDefault())
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Text(item.category.emoji, fontSize = 26.sp)
        Column(Modifier.weight(1f)) {
            Text(item.expense.merchant, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(
                (if (showsDate) dateAndTime else timeOnly).format(time),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Text(item.expense.amount.inr(), style = MaterialTheme.typography.bodyLarge)
    }
}
