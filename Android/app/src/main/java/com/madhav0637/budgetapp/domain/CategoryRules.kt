package com.madhav0637.budgetapp.domain

import java.text.BreakIterator

sealed class CategoryError(message: String) : Exception(message) {
    data object EmptyName : CategoryError("Please enter a name.")
    data object DuplicateName : CategoryError("A category with that name already exists.")
    data object InvalidEmoji : CategoryError("Please choose one emoji.")
    data class InUse(val expenseCount: Int) : CategoryError(
        "Used by $expenseCount ${if (expenseCount == 1) "expense" else "expenses"}. Move them to another category first.",
    )
    data object LastCategory : CategoryError("You need at least one category.")
    data object SameCategory : CategoryError("Choose a different category to move the expenses to.")
}

object CategoryRules {
    /**
     * Returns the trimmed name, or throws if it is empty or already used by another category (ignoring case).
     * [otherNames] should not include the category being renamed, so it can change its own capitalisation.
     */
    fun validated(name: String, emoji: String, otherNames: Collection<String>): String {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) throw CategoryError.EmptyName
        if (!isValidEmoji(emoji)) throw CategoryError.InvalidEmoji
        if (otherNames.any { it.equals(trimmed, ignoreCase = true) }) throw CategoryError.DuplicateName
        return trimmed
    }

    /** True for exactly one emoji, including ones built from several characters like 🧑🏽‍🍳, ❤️ or 🇮🇳. */
    fun isValidEmoji(text: String): Boolean {
        if (text.isEmpty() || graphemeCount(text) != 1) return false
        val first = text.codePointAt(0)
        val hasVariationSelector = text.contains('️')
        return when {
            first in 0x1F000..0x1FAFF -> true // pictographs, faces, food, flags, ...
            first in emojiPresentationSymbols -> true // ☕ ⚡ ⭐ ✅ ... drawn as emoji even without FE0F
            // Older symbols (❤ ☀ ✈ ...) count only when written in emoji style with FE0F.
            // Digits and # are left out on purpose: Unicode classes them as emoji too.
            hasVariationSelector && (first in 0x2000..0x2BFF || first in 0x3000..0x33FF) -> true
            else -> false
        }
    }

    /** Counts user-visible characters, so an emoji made of several code points counts once. */
    private fun graphemeCount(text: String): Int {
        val iterator = BreakIterator.getCharacterInstance()
        iterator.setText(text)
        var count = 0
        while (iterator.next() != BreakIterator.DONE) count++
        return count
    }

    private val emojiPresentationSymbols: Set<Int> = (
        listOf(0x231A, 0x231B, 0x23F0, 0x23F3, 0x25FD, 0x25FE, 0x2614, 0x2615, 0x267F, 0x2693, 0x26A1,
            0x26AA, 0x26AB, 0x26BD, 0x26BE, 0x26C4, 0x26C5, 0x26CE, 0x26D4, 0x26EA, 0x26F2, 0x26F3, 0x26F5,
            0x26FA, 0x26FD, 0x2705, 0x270A, 0x270B, 0x2728, 0x274C, 0x274E, 0x2753, 0x2754, 0x2755, 0x2757,
            0x2795, 0x2796, 0x2797, 0x27B0, 0x27BF, 0x2B1B, 0x2B1C, 0x2B50, 0x2B55) +
            (0x23E9..0x23EC) + (0x2648..0x2653)
        ).toSet()
}
