package org.opensmarthome.open_smart_home

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import androidx.car.app.model.Template
import androidx.car.app.validation.HostValidator
import androidx.core.graphics.drawable.IconCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/**
 * Android Auto: up to six buttons chosen in the app (the garage door, the
 * gate, a scene) on the car screen. A tap goes the same way as a Quick
 * Settings tile: queued and handed to the app, which sends it to Home
 * Assistant. Only labels and on/off are stored here, never the server.
 */
class CarService : CarAppService() {
    override fun createHostValidator(): HostValidator =
        // Debug builds also talk to the desktop head unit; release builds
        // only to Android Auto itself (Google's signed hosts).
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            HostValidator.Builder(applicationContext)
                .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
                .build()
        }

    override fun onCreateSession(): Session = object : Session() {
        override fun onCreateScreen(intent: Intent): Screen = TilesScreen(carContext)
    }
}

private class TilesScreen(context: CarContext) : Screen(context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("quick_tiles", Context.MODE_PRIVATE)

    // The app changed a label or a state (after a tap): draw again.
    private val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == "car") invalidate()
    }

    init {
        lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                prefs.registerOnSharedPreferenceChangeListener(listener)
                // Wake the app so it reports fresh states.
                Engines.ensure(carContext)
            }

            override fun onStop(owner: LifecycleOwner) {
                prefs.unregisterOnSharedPreferenceChangeListener(listener)
            }
        })
    }

    override fun onGetTemplate(): Template {
        val list = ItemList.Builder()
        val icon = CarIcon.Builder(
            IconCompat.createWithResource(carContext, R.drawable.ic_stat_home),
        ).build()
        for (index in 0 until QuickTiles.CAR_COUNT) {
            val state = QuickTiles.carState(carContext, index) ?: continue
            val item = GridItem.Builder()
                .setTitle(state.first)
                .setImage(icon, GridItem.IMAGE_TYPE_ICON)
                .setOnClickListener {
                    QuickTiles.click(carContext, QuickTiles.CAR_BASE + index)
                    CarToast.makeText(
                        carContext,
                        carContext.getString(R.string.car_sent, state.first),
                        CarToast.LENGTH_SHORT,
                    ).show()
                }
            when (state.second) {
                true -> item.setText(carContext.getString(R.string.car_on))
                false -> item.setText(carContext.getString(R.string.car_off))
                null -> {}
            }
            list.addItem(item.build())
        }
        list.setNoItemsMessage(carContext.getString(R.string.car_empty))
        return GridTemplate.Builder()
            .setTitle(carContext.getString(R.string.car_title))
            .setHeaderAction(Action.APP_ICON)
            .setSingleList(list.build())
            .build()
    }
}
