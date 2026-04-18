package app.aura.story.bridge

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VisibleProgressTest {
    @Test
    fun `trailing whitespace does not count as fresh progress`() {
        val progress = computeVisibleProgress(
            previousEffectiveVisible = "你好，旅行者",
            currentVisible = "你好，旅行者   \n\n",
        )

        assertEquals("你好，旅行者", progress.effectiveVisible)
        assertEquals("", progress.delta)
        assertFalse(progress.madeProgress)
    }

    @Test
    fun `newline becomes visible once substantive text follows`() {
        val progress = computeVisibleProgress(
            previousEffectiveVisible = "第一段",
            currentVisible = "第一段\n第二段",
        )

        assertEquals("第一段\n第二段", progress.effectiveVisible)
        assertEquals("\n第二段", progress.delta)
        assertTrue(progress.madeProgress)
    }
}
