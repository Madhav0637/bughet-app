package com.madhav0637.budgetapp.data

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation
import java.time.Instant
import java.util.UUID

@Entity(tableName = "categories")
data class Category(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val emoji: String,
)

/**
 * RESTRICT makes the database itself refuse to delete a category that still has expenses,
 * matching the rule on iOS.
 */
@Entity(
    tableName = "expenses",
    foreignKeys = [
        ForeignKey(
            entity = Category::class,
            parentColumns = ["id"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [Index("date"), Index("categoryId")],
)
data class Expense(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val merchant: String,
    /** Whole rupees. */
    val amount: Long,
    val date: Instant,
    val categoryId: String,
)

/** An expense together with its category, loaded in one query. */
data class ExpenseWithCategory(
    @Embedded val expense: Expense,
    @Relation(parentColumn = "categoryId", entityColumn = "id")
    val category: Category,
)
