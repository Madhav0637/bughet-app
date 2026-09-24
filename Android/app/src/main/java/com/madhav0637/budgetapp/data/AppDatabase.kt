package com.madhav0637.budgetapp.data

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.sqlite.db.SupportSQLiteDatabase
import com.madhav0637.budgetapp.domain.DefaultCategories
import java.time.Instant
import java.util.UUID

class Converters {
    @TypeConverter
    fun fromInstant(value: Instant): Long = value.toEpochMilli()

    @TypeConverter
    fun toInstant(value: Long): Instant = Instant.ofEpochMilli(value)
}

/** The single on-device store, shared by the app's screens and the quick-entry pop-up. */
@Database(entities = [Category::class, Expense::class], version = 1)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun categoryDao(): CategoryDao
    abstract fun expenseDao(): ExpenseDao

    companion object {
        fun create(context: Context): AppDatabase =
            Room.databaseBuilder(context, AppDatabase::class.java, "budget.db")
                .addCallback(SeedDefaults)
                .build()
    }

    /**
     * Inserts the default categories when the database file is first created, before any screen can read it,
     * so quick entry always has categories even if the main app was never opened.
     */
    private object SeedDefaults : Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            for (item in DefaultCategories.all) {
                val row = ContentValues().apply {
                    put("id", UUID.randomUUID().toString())
                    put("name", item.name)
                    put("emoji", item.emoji)
                }
                db.insert("categories", SQLiteDatabase.CONFLICT_ABORT, row)
            }
        }
    }
}
