package com.c12dd.flyff_native.model

import android.webkit.WebView
import java.util.UUID

data class BrowserTab(
    val id: String = UUID.randomUUID().toString(),
    var title: String = "新标签页",
    val url: String,
    var webView: WebView? = null
) {
    fun updateTitle(newTitle: String) {
        title = if (newTitle.isBlank()) "新标签页" else newTitle
    }
}