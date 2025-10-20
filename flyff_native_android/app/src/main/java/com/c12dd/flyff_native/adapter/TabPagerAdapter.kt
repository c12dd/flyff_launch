package com.c12dd.flyff_native.adapter

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.c12dd.flyff_native.fragment.WebViewFragment
import com.c12dd.flyff_native.model.BrowserTab

class TabPagerAdapter(fragmentActivity: FragmentActivity) : FragmentStateAdapter(fragmentActivity) {
    private var tabs: List<BrowserTab> = emptyList()
    
    fun updateTabs(newTabs: List<BrowserTab>) {
        tabs = newTabs
        notifyDataSetChanged()
    }
    
    override fun getItemCount(): Int = tabs.size
    
    override fun createFragment(position: Int): Fragment {
        return WebViewFragment.newInstance(tabs[position].id, tabs[position].url)
    }
    
    override fun getItemId(position: Int): Long {
        return tabs[position].id.hashCode().toLong()
    }
    
    override fun containsItem(itemId: Long): Boolean {
        return tabs.any { it.id.hashCode().toLong() == itemId }
    }
}