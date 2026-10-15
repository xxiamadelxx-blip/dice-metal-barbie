package app.adeldice.weblab;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.content.ActivityNotFoundException;
import android.net.Uri;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.graphics.Color;
import android.util.Log;
import android.util.Base64;
import java.io.InputStream;
import java.io.IOException;
import android.webkit.ConsoleMessage;

/** Offline WebGL2 renderer benchmark, not the signed production Dice Roller. */
public final class MainActivity extends Activity {
    private static final int FILE_PICKER_REQUEST = 7301;
    private WebView webView;
    private ValueCallback<Uri[]> pendingFiles;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(10, 11, 16));
        getWindow().setNavigationBarColor(Color.rgb(10, 11, 16));
        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(10, 11, 16));
        webView.setLayerType(WebView.LAYER_TYPE_HARDWARE, null);
        WebSettings config = webView.getSettings();
        config.setJavaScriptEnabled(true);
        config.setDomStorageEnabled(true);
        config.setAllowFileAccess(true);
        config.setAllowContentAccess(true);
        config.setAllowFileAccessFromFileURLs(false);
        config.setAllowUniversalAccessFromFileURLs(false);
        webView.setWebViewClient(new WebViewClient() {
            @Override public void onPageFinished(WebView view, String url) {
                // Verify the *actual* Android WebView GPU context, not a mock or source assertion.
                view.evaluateJavascript("Boolean(window.DiceExperimentalQA && document.getElementById('canvas').getContext('webgl2') && window.crypto && window.crypto.getRandomValues)",
                    result -> Log.i("AlphaWebGLLab", "ALPHA_WEBGL_LAB_QA " + result));
                // Test-only synthetic fixture: original owner GLB is never packaged or published.
                if ((getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
                        && getIntent().getBooleanExtra("qa_fixture", false)) {
                    loadPublicQaFixture(view);
                }
            }
        });
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onConsoleMessage(ConsoleMessage message) {
                Log.i("AlphaWebGLLab", "JS " + message.message());
                return true;
            }
            @Override public boolean onShowFileChooser(WebView source, ValueCallback<Uri[]> callback,
                                                       FileChooserParams params) {
                if (pendingFiles != null) pendingFiles.onReceiveValue(null);
                pendingFiles = callback;
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("*/*");
                // The SAF MIME database commonly does not map .glb to glTF.
                // Deliberately do not set EXTRA_MIME_TYPES: allow the user to select .glb.
                // The WebGL loader subsequently checks the glTF 2.0 magic/version.
                try {
                    startActivityForResult(intent, FILE_PICKER_REQUEST);
                    return true;
                } catch (ActivityNotFoundException error) {
                    pendingFiles = null;
                    callback.onReceiveValue(null);
                    return false;
                }
            }
        });
        setContentView(webView);
        webView.loadUrl("file:///android_asset/viewer.html");
    }

    /** Instrumented debug launch only: exercise the real GLB parser, GPU and pixels. */
    private void loadPublicQaFixture(WebView view) {
        try (InputStream file = getAssets().open("qa_fixture.glb")) {
            byte[] data = file.readAllBytes();
            if (data.length < 100 || data.length > 100_000) throw new IOException("Fixture length invalid");
            String source = Base64.encodeToString(data, Base64.NO_WRAP);
            String js = "(async()=>{try{"
                    + "const binary=atob('" + source + "');"
                    + "const bytes=Uint8Array.from(binary,c=>c.charCodeAt(0));"
                    + "const loaded=await window.DiceExperimentalQA.loadGLB(bytes.buffer,'PUBLIC_SYNTHETIC_QA');"
                    + "window.DiceExperimentalQA.setTarget(11);"
                    + "await new Promise(done=>requestAnimationFrame(()=>requestAnimationFrame(done)));"
                    + "const qa=window.DiceExperimentalQA;"
                    + "const canvas=document.getElementById('canvas');"
                    + "const gpu=canvas.getContext('webgl2');"
                    + "const image=new Uint8Array(128*128*4);"
                    + "gpu.readPixels(296,296,128,128,gpu.RGBA,gpu.UNSIGNED_BYTE,image);"
                    + "let bright=0;for(let k=0;k<image.length;k+=4)"
                    + "if(image[k]>70||image[k+1]>70)bright++;"
                    + "const normals=[...qa.goldFaces()].map(([v,n])=>[v,qa.rotatedNormal(v)[2]]).sort((a,b)=>b[1]-a[1]);"
                    + "const report={ready:qa.state.ready,face:qa.state.visibleFace,"
                    + "front:normals[0][0],triangles:qa.state.triangles,parts:qa.state.parts,"
                    + "bright:bright,glError:qa.getGLError()};"
                    + "console.info('ALPHA_ANDROID_MODEL_QA '+JSON.stringify(report));"
                    + "if(!report.ready||report.face!==11||report.front!==11||report.parts!==21||"
                    + "report.bright<16||report.glError!==0)"
                    + "console.error('ALPHA_ANDROID_MODEL_QA_FAIL '+JSON.stringify(report));"
                    + "}catch(e){console.error('ALPHA_ANDROID_MODEL_QA_FAIL '+String(e))}})();";
            view.evaluateJavascript(js, result -> Log.i("AlphaWebGLLab", "Synthetic QA submitted"));
        } catch (IOException e) {
            Log.e("AlphaWebGLLab", "ALPHA_ANDROID_MODEL_QA_FAIL fixture not found", e);
        }
    }

    @Override protected void onActivityResult(int request, int code, Intent data) {
        super.onActivityResult(request, code, data);
        if (request != FILE_PICKER_REQUEST || pendingFiles == null) return;
        Uri[] chosen = null;
        if (code == Activity.RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) chosen = new Uri[]{uri};
        }
        pendingFiles.onReceiveValue(chosen);
        pendingFiles = null;
    }

    @Override protected void onDestroy() {
        if (pendingFiles != null) { pendingFiles.onReceiveValue(null); pendingFiles = null; }
        if (webView != null) { webView.destroy(); webView = null; }
        super.onDestroy();
    }
}