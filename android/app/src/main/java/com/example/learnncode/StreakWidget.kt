package com.example.learnncode

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.GradientDrawable.Orientation
import android.graphics.Canvas
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import com.example.learnncode.R

class StreakWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.streak_widget).apply {
                // Set gradient background
                val gradient = GradientDrawable(
                    Orientation.TL_BR, // Changed from TOP_LEFT to TL_BR
                    intArrayOf(
                        Color.parseColor("#26A69A"), // Teal
                        Color.parseColor("#66BB6A")  // Green
                    )
                )
                gradient.cornerRadius = 32f
                setInt(R.id.widget_container, "setBackgroundResource", 0)
                setImageViewBitmap(R.id.widget_container, gradient.toBitmap(300, 100))

                // Set streak data
                val streak = widgetData.getString("streak_count", "0")
                setTextViewText(R.id.streak_count, "$streak Day Streak!")

                val message = widgetData.getString("streak_message", "Start your streak!")
                setTextViewText(R.id.streak_message, message)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// Helper extension to convert GradientDrawable to Bitmap
fun GradientDrawable.toBitmap(width: Int, height: Int): android.graphics.Bitmap {
    val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    setBounds(0, 0, width, height)
    draw(canvas)
    return bitmap
}