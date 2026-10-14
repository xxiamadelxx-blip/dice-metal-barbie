package com.adeldice.filamentlab

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.view.Choreographer
import android.view.Gravity
import android.view.PixelCopy
import android.view.SurfaceView
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.filament.Filament
import com.google.android.filament.utils.ModelViewer
import java.nio.ByteBuffer
import java.security.MessageDigest
import org.json.JSONObject
import java.io.File

/**
 * Completely native Android renderer lab using Google's Filament PBR engine.
 * NO WebView, Godot, copied BlenderKit textures or preselected dice outcomes.
 * GLB is chosen privately via Android Documents provider. The renderer
 * preserves the original glTF PBR materials and does not upload any bytes.
 */
class MainActivity : Activity() {
    companion object {
        private const val PICK_GLB = 721
        private const val AUTHENTIC_D20 =
            "60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39"
    }
    private lateinit var surface: SurfaceView
    private lateinit var status: TextView
    private lateinit var viewer: ModelViewer
    private var active = false
    private var frames = 0L
    private var lastTick = 0L
    private var drawStart = 0L

    private val ticker = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            if (!active) return
            if (viewer.render(frameTimeNanos)) frames += 1
            if (lastTick == 0L) lastTick = frameTimeNanos
            if (frameTimeNanos - lastTick > 2_000_000_000L) {
                val seconds = (frameTimeNanos-lastTick) / 1_000_000_000.0
                val approx = frames/seconds
                // Presentation-cadence diagnostic, NOT GPU benchmark without
                // actual on-device profiling and thermal control.
                if (viewer.asset != null) {
                    status.text = "Filament native • кадры ~%.1f/с • PBR GLB загружен".format(approx)
                }
                frames = 0
                lastTick = frameTimeNanos
            }
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Filament.init()
        val page = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(8,13,11))
            setPadding(12,22,12,8)
        }
        status = TextView(this).apply {
            text = "Google Filament Native · Android • материал из вашего GLB"
            setTextColor(Color.rgb(232,216,176))
            textSize = 15f
            setPadding(0,0,0,12)
        }
        val chooser = Button(this).apply {
            text = "Выбрать локальный GLB"
            setOnClickListener { openModel() }
        }
        val capture = Button(this).apply {
            text = "PNG реального кадра"
            setOnClickListener { captureFrame() }
        }
        surface = SurfaceView(this)
        surface.layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,0,1f)
        page.addView(status)
        page.addView(chooser)
        page.addView(surface)
        page.addView(capture)
        setContentView(page)

        // Default Filament Android backend, independent of WebView and Godot.
        viewer = ModelViewer(surface, manipulator = null)
        viewer.autoPlayAnimations = false
        viewer.camera.lookAt(0.0, 4.0, -4.0, 0.0,0.0,-4.0, 0.0,0.0,-1.0)
    }

    private fun openModel() {
        val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*" // .glb MIME varies among Android file managers
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(picker,PICK_GLB)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode,resultCode,data)
        if (requestCode != PICK_GLB || resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        try {
            val dataBytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: error("GLB file cannot be read")
            require(dataBytes.size >= 20) {"GLB file is empty"}
            val header = ByteBuffer.wrap(dataBytes).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            require(header.int == 0x46546c67) {"Not glTF GLB binary"}
            require(header.int == 2) {"Not glTF 2.0"}
            require(header.int == dataBytes.size) {"Corrupt GLB length"}
            val (tris,gold) = geometryInspection(dataBytes)
            val sha = MessageDigest.getInstance("SHA-256").digest(dataBytes)
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
            val authentic = sha == AUTHENTIC_D20 && tris==500000 && gold==20
            val direct = ByteBuffer.allocateDirect(dataBytes.size).apply {
                put(dataBytes);flip()
            }
            viewer.loadModelGlb(direct)
            viewer.transformToUnitCube()
            // STRICTLY overhead camera instead of a free orbit manipulator.
            viewer.camera.lookAt(0.0,4.0,-4.0,0.0,0.0,-4.0,0.0,0.0,-1.0)
            status.text = if(authentic)
                "Проверен оригинальный 500k D20 • Filament PBR"
            else
                "Другой GLB: $tris треугольников / $gold золотых частей"
            android.util.Log.i("DICE_FILAMENT_NATIVE","GLB_SHA=$sha tris=$tris gold=$gold authentic=$authentic")
        } catch (error: Exception) {
            status.text = "Не удалось прочитать GLB: ${error.message}"
            android.util.Log.e("DICE_FILAMENT_NATIVE","GLB source failed",error)
        }
    }

    private fun geometryInspection(bytes:ByteArray): Pair<Int,Int> {
        val header = ByteBuffer.wrap(bytes).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        val jsonLength=header.getInt(12)
        require(header.getInt(16)==0x4E4F534A && jsonLength>0 && 20+jsonLength<=bytes.size)
        val json=JSONObject(String(bytes,20,jsonLength,Charsets.UTF_8))
        val accessors=json.getJSONArray("accessors")
        val meshes=json.getJSONArray("meshes")
        val nodes=json.getJSONArray("nodes")
        var triangles=0
        var goldMeshes=0
        for (i in 0 until nodes.length()) {
            val n=nodes.getJSONObject(i)
            if (!n.has("mesh"))continue
            val mesh=meshes.getJSONObject(n.getInt("mesh"))
            val primitives=mesh.getJSONArray("primitives")
            for (j in 0 until primitives.length()) {
                val prim=primitives.getJSONObject(j)
                require(prim.optInt("mode",4)==4) {"Non-triangle primitive"}
                val idx=if(prim.has("indices"))prim.getInt("indices")
                    else prim.getJSONObject("attributes").getInt("POSITION")
                val count=accessors.getJSONObject(idx).getInt("count")
                require(count%3==0)
                triangles+=count/3
            }
            if(n.optString("name","").startsWith("Gold_"))goldMeshes++
        }
        return Pair(triangles,goldMeshes)
    }

    private fun captureFrame() {
        if(!surface.holder.surface.isValid){
            status.text="Сначала откройте 3D-модель";return
        }
        val image = Bitmap.createBitmap(
            surface.width.coerceAtLeast(1),surface.height.coerceAtLeast(1),Bitmap.Config.ARGB_8888)
        PixelCopy.request(surface,image,{result->
            if(result==PixelCopy.SUCCESS){
                try{
                    val folder=getExternalFilesDir(Environment.DIRECTORY_PICTURES)!!
                    val target=File(folder,"REAL_FILAMENT_NATIVE_D20_${System.currentTimeMillis()}.png")
                    target.outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }
                    status.text="Исходный кадр записан: ${target.name}"
                }catch(e:Exception){status.text="PNG: ${e.message}"}
            }else status.text="PixelCopy не получил GPU-кадр: $result"
            image.recycle()
        },Handler(Looper.getMainLooper()))
    }

    override fun onResume() {
        super.onResume()
        if (::viewer.isInitialized) {
            active = true
            Choreographer.getInstance().postFrameCallback(ticker)
        }
    }
    override fun onPause() {
        active=false
        Choreographer.getInstance().removeFrameCallback(ticker)
        super.onPause()
    }
    override fun onDestroy() {
        active=false
        Choreographer.getInstance().removeFrameCallback(ticker)
        if(::viewer.isInitialized)viewer.destroy()
        super.onDestroy()
    }
}
