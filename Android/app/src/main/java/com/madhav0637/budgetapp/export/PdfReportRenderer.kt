package com.madhav0637.budgetapp.export

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.TextPaint
import android.text.TextUtils
import com.madhav0637.budgetapp.domain.ReportContent
import java.io.OutputStream

/**
 * Draws a [ReportContent] as an A4 PDF using Android's built-in [PdfDocument].
 * Long tables continue onto new pages, with the column headings repeated and a page number at the bottom.
 * The page is always white with dark text, whatever the phone's theme, so it prints properly.
 */
object PdfReportRenderer {
    private const val PAGE_WIDTH = 595 // A4 in points
    private const val PAGE_HEIGHT = 842
    private const val MARGIN = 40f
    private const val ROW = 20f
    private const val RIGHT = PAGE_WIDTH - MARGIN

    // Table columns: where each starts and how wide it may be. Amount is right-aligned to the margin.
    private const val DATE_X = MARGIN
    private const val MERCHANT_X = MARGIN + 125
    private const val CATEGORY_X = MARGIN + 330
    private const val MERCHANT_WIDTH = 195f
    private const val CATEGORY_WIDTH = 110f

    private val black = Color.rgb(0x11, 0x11, 0x11)
    private val grey = Color.rgb(0x6B, 0x6B, 0x70)
    private val stripe = Color.rgb(0xF2, 0xF2, 0xF7)
    private val separator = Color.rgb(0xD1, 0xD1, 0xD6)

    fun render(content: ReportContent, out: OutputStream) {
        val document = PdfDocument()
        var pageNumber = 0
        var page: PdfDocument.Page? = null
        var y = 0f

        fun canvas(): Canvas = page!!.canvas

        fun finishPage() {
            page?.let {
                text(it.canvas, "Page $pageNumber", 9f, grey, RIGHT, PAGE_HEIGHT - MARGIN + 18, align = Paint.Align.RIGHT)
                document.finishPage(it)
            }
        }

        fun newPage() {
            finishPage()
            pageNumber++
            page = document.startPage(PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, pageNumber).create())
            y = MARGIN
        }

        /** Starts a new page if the next [height] points wouldn't fit. Returns true if it did. */
        fun ensureSpace(height: Float): Boolean {
            if (y + height <= PAGE_HEIGHT - MARGIN) return false
            newPage()
            return true
        }

        fun tableHeader() {
            val c = canvas()
            text(c, "Date", 10f, grey, DATE_X, y + 13, bold = true)
            text(c, "Merchant", 10f, grey, MERCHANT_X, y + 13, bold = true)
            text(c, "Category", 10f, grey, CATEGORY_X, y + 13, bold = true)
            text(c, "Amount", 10f, grey, RIGHT, y + 13, bold = true, align = Paint.Align.RIGHT)
            y += ROW
            c.drawRect(MARGIN, y - 3, RIGHT, y - 2.5f, Paint().apply { color = separator })
        }

        newPage()

        // Title, subtitle and total
        text(canvas(), content.title, 24f, black, MARGIN, y + 24, bold = true)
        y += 34
        text(canvas(), content.subtitle, 11f, grey, MARGIN, y + 11, maxWidth = RIGHT - MARGIN)
        y += 30
        text(canvas(), "Total spent", 12f, grey, MARGIN, y + 12)
        y += 18
        text(canvas(), content.total, 28f, black, MARGIN, y + 28, bold = true)
        y += 52

        // By category
        text(canvas(), "By Category", 15f, black, MARGIN, y + 15, bold = true)
        y += 26
        for (row in content.categoryRows) {
            ensureSpace(ROW)
            text(canvas(), row.label, 11f, black, MARGIN, y + 14, maxWidth = 300f)
            text(canvas(), row.share, 11f, grey, MARGIN + 400, y + 14, align = Paint.Align.RIGHT)
            text(canvas(), row.amount, 11f, black, RIGHT, y + 14, align = Paint.Align.RIGHT)
            y += ROW
        }
        y += 24

        // Every expense, oldest first
        ensureSpace(60f)
        text(canvas(), "All Expenses", 15f, black, MARGIN, y + 15, bold = true)
        y += 26
        tableHeader()
        content.expenseRows.forEachIndexed { index, row ->
            if (ensureSpace(ROW)) tableHeader()
            val c = canvas()
            if (index % 2 == 0) c.drawRect(MARGIN - 4, y - 2, RIGHT + 4, y + ROW - 2, Paint().apply { color = stripe })
            text(c, row.date, 10f, black, DATE_X, y + 13)
            text(c, row.merchant, 10f, black, MERCHANT_X, y + 13, maxWidth = MERCHANT_WIDTH)
            text(c, row.category, 10f, black, CATEGORY_X, y + 13, maxWidth = CATEGORY_WIDTH)
            text(c, row.amount, 10f, black, RIGHT, y + 13, align = Paint.Align.RIGHT)
            y += ROW
        }

        finishPage()
        document.writeTo(out)
        document.close()
    }

    /** One line of text at a baseline, cut off with "…" if it's wider than [maxWidth]. */
    private fun text(
        canvas: Canvas, value: String, size: Float, color: Int, x: Float, baseline: Float,
        bold: Boolean = false, align: Paint.Align = Paint.Align.LEFT, maxWidth: Float? = null,
    ) {
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size
            this.color = color
            textAlign = align
            typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        val shown = maxWidth?.let { TextUtils.ellipsize(value, paint, it, TextUtils.TruncateAt.END).toString() } ?: value
        canvas.drawText(shown, x, baseline, paint)
    }
}
