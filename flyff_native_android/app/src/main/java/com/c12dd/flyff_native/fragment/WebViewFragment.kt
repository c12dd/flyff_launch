package com.c12dd.flyff_native.fragment

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.c12dd.flyff_native.databinding.FragmentWebviewBinding
import com.c12dd.flyff_native.viewmodel.BrowserViewModel

class WebViewFragment : Fragment() {
    private var _binding: FragmentWebviewBinding? = null
    private val binding get() = _binding!!
    
    private lateinit var viewModel: BrowserViewModel
    private var tabId: String? = null
    private var initialUrl: String? = null
    
    companion object {
        private const val ARG_TAB_ID = "tab_id"
        private const val ARG_URL = "url"
        
        fun newInstance(tabId: String, url: String): WebViewFragment {
            return WebViewFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_TAB_ID, tabId)
                    putString(ARG_URL, url)
                }
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            tabId = it.getString(ARG_TAB_ID)
            initialUrl = it.getString(ARG_URL)
        }
        viewModel = ViewModelProvider(requireActivity())[BrowserViewModel::class.java]
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentWebviewBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupWebView()
        loadUrl()
    }
    
    private fun setupWebView() {
        binding.webView.apply {
            // WebView设置
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                databaseEnabled = true
                cacheMode = WebSettings.LOAD_DEFAULT
                mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                mediaPlaybackRequiresUserGesture = false
                allowFileAccess = true
                allowContentAccess = true
                setSupportZoom(true)
                builtInZoomControls = true
                displayZoomControls = false
                useWideViewPort = true
                loadWithOverviewMode = true
                
                // 性能优化
                setRenderPriority(WebSettings.RenderPriority.HIGH)
                cacheMode = WebSettings.LOAD_DEFAULT
            }
            
            // WebViewClient
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    // 页面加载完成后更新标题
                    view?.title?.let { title ->
                        updateTabTitle(title)
                    }
                }
            }
            
            // WebChromeClient
            webChromeClient = object : WebChromeClient() {
                override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    title?.let { updateTabTitle(it) }
                }
                
                override fun onProgressChanged(view: WebView?, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    binding.progressBar.apply {
                        if (newProgress < 100) {
                            visibility = View.VISIBLE
                            progress = newProgress
                        } else {
                            visibility = View.GONE
                        }
                    }
                }
            }
        }
        
        // 将WebView保存到对应的Tab中
        saveWebViewToTab()
    }
    
    private fun loadUrl() {
        initialUrl?.let { url ->
            binding.webView.loadUrl(url)
        }
    }
    
    private fun updateTabTitle(title: String) {
        val tabs = viewModel.tabs.value ?: return
        val tabIndex = tabs.indexOfFirst { it.id == tabId }
        if (tabIndex >= 0) {
            viewModel.updateTabTitle(tabIndex, title)
        }
    }
    
    private fun saveWebViewToTab() {
        val tabs = viewModel.tabs.value ?: return
        val tab = tabs.find { it.id == tabId }
        tab?.webView = binding.webView
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        // 清理WebView引用
        val tabs = viewModel.tabs.value ?: return
        val tab = tabs.find { it.id == tabId }
        tab?.webView = null
        
        _binding = null
    }
}