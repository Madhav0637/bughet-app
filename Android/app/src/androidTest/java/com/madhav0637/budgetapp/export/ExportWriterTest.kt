package com.madhav0637.budgetapp.export

import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.Expense
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.ExportFormat
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/** Writes real CSV and PDF files on the emulator and checks them. Uses a throwaway folder, never the real exports. */
@RunWith(AndroidJUnit4::class)
class ExportWriterTest {
    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()
    private val directory = File(context.cacheDir, "export-test-${System.nanoTime()}")
    private val zone = ZoneId.of("Asia/Kolkata")
    private val food = Category(name = "Food", emoji = "🍔")

    @After
    fun tearDown() {
        directory.deleteRecursively()
    }

    private fun at(day: Int, hour: Int) = LocalDateTime.of(2026, 9, day, hour, 0).atZone(zone).toInstant()

    private fun expenses(count: Int) = (1..count).map { i ->
        ExpenseWithCategory(Expense(merchant = "Shop $i", amount = i * 10L, date = at(1 + i % 28, 9 + i % 12), categoryId = food.id), food)
    }

    private fun pageCount(file: File): Int =
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { PdfRenderer(it).use { r -> r.pageCount } }

    @Test
    fun writesARealCsvFile() {
        val file = ExportWriter.write(ExportFormat.Csv, expenses(3), directory, Instant.parse("2026-09-24T06:00:00Z"), zone)
        assertEquals("BudgetApp-expenses-2026-09-24.csv", file.name)
        val lines = file.readLines()
        assertEquals("Date,Merchant,Category,Amount", lines.first())
        assertEquals(4, lines.size)
    }

    @Test
    fun writesAValidPdfThatFitsOnOnePageWhenShort() {
        val file = ExportWriter.write(ExportFormat.Pdf, expenses(3), directory, Instant.parse("2026-09-24T06:00:00Z"), zone)
        assertEquals("BudgetApp-expenses-2026-09-24.pdf", file.name)
        assertTrue(file.readBytes().take(4).toByteArray().contentEquals("%PDF".toByteArray()))
        assertEquals(1, pageCount(file))
    }

    @Test
    fun longReportContinuesOnMorePages() {
        // About 34 table rows fit on the first page and about 38 on each page after, so 84 rows need 3 pages.
        val file = ExportWriter.write(ExportFormat.Pdf, expenses(84), directory, zone = zone)
        assertTrue("expected at least 3 pages, got ${pageCount(file)}", pageCount(file) >= 3)
    }

    @Test
    fun emptyReportIsStillAValidOnePagePdf() {
        val file = ExportWriter.write(ExportFormat.Pdf, emptyList(), directory, zone = zone)
        assertEquals(1, pageCount(file))
    }

    @Test
    fun exportingAgainReplacesTheOldFile() {
        val now = Instant.parse("2026-09-24T06:00:00Z")
        ExportWriter.write(ExportFormat.Csv, expenses(1), directory, now, zone)
        val file = ExportWriter.write(ExportFormat.Csv, expenses(5), directory, now, zone)
        assertEquals(6, file.readLines().size)
        assertEquals(1, directory.listFiles()!!.size)
    }
}
