package com.c12dd.flyff_native.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.c12dd.flyff_native.model.BrowserTab

class BrowserViewModel : ViewModel() {
    private val _tabs = MutableLiveData<MutableList<BrowserTab>>(mutableListOf())
    val tabs: LiveData<MutableList<BrowserTab>> = _tabs
    
    private val _currentTabIndex = MutableLiveData<Int>(0)
    val currentTabIndex: LiveData<Int> = _currentTabIndex
    
    fun addNewTab(url: String) {
        val newTab = BrowserTab(url = url)
        val currentTabs = _tabs.value ?: mutableListOf()
        currentTabs.add(newTab)
        _tabs.value = currentTabs
        _currentTabIndex.value = currentTabs.size - 1
    }
    
    fun closeTab(index: Int) {
        val currentTabs = _tabs.value ?: return
        if (index < 0 || index >= currentTabs.size) return
        
        // 销毁WebView
        currentTabs[index].webView?.destroy()
        currentTabs.removeAt(index)
        
        if (currentTabs.isEmpty()) {
            // 如果没有标签页了，会在MainActivity中自动创建新的
            _currentTabIndex.value = 0
        } else {
            // 调整当前标签页索引
            val currentIndex = _currentTabIndex.value ?: 0
            when {
                index < currentIndex -> _currentTabIndex.value = currentIndex - 1
                index == currentIndex && index >= currentTabs.size -> {
                    _currentTabIndex.value = currentTabs.size - 1
                }
            }
        }
        
        _tabs.value = currentTabs
    }
    
    fun switchToTab(index: Int) {
        val currentTabs = _tabs.value ?: return
        if (index >= 0 && index < currentTabs.size) {
            _currentTabIndex.value = index
        }
    }
    
    fun updateTabTitle(index: Int, title: String) {
        val currentTabs = _tabs.value ?: return
        if (index >= 0 && index < currentTabs.size) {
            currentTabs[index].updateTitle(title)
            _tabs.value = currentTabs
        }
    }
    
    fun reloadTab(index: Int) {
        val currentTabs = _tabs.value ?: return
        if (index >= 0 && index < currentTabs.size) {
            currentTabs[index].webView?.reload()
        }
    }
    
    fun getCurrentTab(): BrowserTab? {
        val currentTabs = _tabs.value ?: return null
        val currentIndex = _currentTabIndex.value ?: return null
        return if (currentIndex >= 0 && currentIndex < currentTabs.size) {
            currentTabs[currentIndex]
        } else null
    }
    
    override fun onCleared() {
        super.onCleared()
        // 清理所有WebView
        _tabs.value?.forEach { tab ->
            tab.webView?.destroy()
        }
    }
}