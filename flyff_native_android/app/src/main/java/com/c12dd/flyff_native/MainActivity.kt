package com.c12dd.flyff_native

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.webkit.WebView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import androidx.viewpager2.widget.ViewPager2
import com.c12dd.flyff_native.adapter.TabPagerAdapter
import com.c12dd.flyff_native.databinding.ActivityMainBinding
import com.c12dd.flyff_native.model.BrowserTab
import com.c12dd.flyff_native.viewmodel.BrowserViewModel
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: BrowserViewModel
    private lateinit var tabPagerAdapter: TabPagerAdapter
    
    companion object {
        private const val DEFAULT_URL = "https://universe.flyff.com/play"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 设置全屏模式
        enableFullscreenMode()
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // WebView调试模式
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(true)
        }
        
        setupViewModel()
        setupUI()
        setupObservers()
        
        // 创建第一个标签页
        if (viewModel.tabs.value.isNullOrEmpty()) {
            viewModel.addNewTab(DEFAULT_URL)
        }
    }
    
    private fun setupViewModel() {
        viewModel = ViewModelProvider(this)[BrowserViewModel::class.java]
    }
    
    private fun setupUI() {
        // 设置ViewPager2
        tabPagerAdapter = TabPagerAdapter(this)
        binding.viewPager.adapter = tabPagerAdapter
        // 禁用左右滑动
        binding.viewPager.isUserInputEnabled = false
        
        // 连接TabLayout和ViewPager2
        TabLayoutMediator(binding.tabLayout, binding.viewPager) { tab, position ->
            val browserTab = viewModel.tabs.value?.get(position)
            tab.text = browserTab?.title ?: "新标签页"
        }.attach()
        
        // 添加新标签页按钮
        binding.fabAddTab.setOnClickListener {
            viewModel.addNewTab(DEFAULT_URL)
        }
        
        // 自动点击按钮
        binding.fabAutoClick.setOnClickListener {
            showAutoClickDialog()
        }
    }
    
    private fun setupObservers() {
        viewModel.tabs.observe(this) { tabs ->
            tabPagerAdapter.updateTabs(tabs)
            
            // 如果没有标签页了，创建一个新的
            if (tabs.isEmpty()) {
                viewModel.addNewTab(DEFAULT_URL)
            }
        }
        
        viewModel.currentTabIndex.observe(this) { index ->
            if (index >= 0 && index < (viewModel.tabs.value?.size ?: 0)) {
                binding.viewPager.currentItem = index
            }
        }
    }
    
    private fun showAutoClickDialog() {
        AlertDialog.Builder(this)
            .setTitle("自动点击功能")
            .setMessage("要使用自动点击功能，需要开启无障碍服务权限。")
            .setPositiveButton("去设置") { _, _ ->
                openAccessibilitySettings()
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            enableFullscreenMode()
        }
    }
    
    private fun enableFullscreenMode() {
        try {
            // 设置全屏标志
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
            )
            
            // 隐藏系统UI（沉浸式模式）
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(false)
                try {
                    window.insetsController?.let { controller ->
                        controller.hide(android.view.WindowInsets.Type.statusBars() or android.view.WindowInsets.Type.navigationBars())
                        controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    }
                } catch (e: Exception) {
                    // 如果新API失败，回退到旧方法
                    @Suppress("DEPRECATION")
                    window.decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    )
                }
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
            }
        } catch (e: Exception) {
            // 如果全屏设置失败，至少尝试隐藏状态栏
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN
        }
    }

}