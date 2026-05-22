package com.mericucan.kampanyaradari

import android.app.Application
import com.mericucan.kampanyaradari.store.CampaignTrackingStore
import com.mericucan.kampanyaradari.store.FavoritesStore
import com.mericucan.kampanyaradari.store.MyCardsStore
import com.mericucan.kampanyaradari.store.PrefsStore
import com.mericucan.kampanyaradari.worker.ReminderScheduler

class KampanyaRadariApp : Application() {
    lateinit var favoritesStore: FavoritesStore
        private set
    lateinit var prefsStore: PrefsStore
        private set
    lateinit var myCardsStore: MyCardsStore
        private set
    lateinit var trackingStore: CampaignTrackingStore
        private set

    override fun onCreate() {
        super.onCreate()
        favoritesStore = FavoritesStore(this)
        prefsStore     = PrefsStore(this)
        myCardsStore   = MyCardsStore(this)
        trackingStore  = CampaignTrackingStore(this)
        ReminderScheduler.createChannel(this)
    }
}
