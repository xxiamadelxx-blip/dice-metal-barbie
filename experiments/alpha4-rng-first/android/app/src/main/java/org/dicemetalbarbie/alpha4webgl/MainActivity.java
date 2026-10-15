package org.dicemetalbarbie.alpha4webgl;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.webkit.ValueCallback;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebChromeClient.FileChooserParams;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.webkit.WebViewAssetLoader;

/**
 * Standalone offline Android WebView container, not Godot/Jolt.
 * WebViewAssetLoader gives WebCrypto a secure HTTPS origin WITHOUT network IO.
 * Bundled Three.js shader/runtime is served from app assets, no CDN.
 */
public final class MainActivity extends Activity {
    private static final String TAG = "AlphaWebGL";
    private static final String LOCAL = "https://appassets.androidplatform.net/assets/exp/index.html";
    private static final int PICK_PRIVATE_GLB = 2026;
    private WebView webView;
    private ValueCallback<Uri[]> pendingFile;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(0xff101116);
        getWindow().setNavigationBarColor(0xff101116);

        WebViewAssetLoader localLoader = new WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
            .build();

        webView = new WebView(this);
        webView.setBackgroundColor(0xff101116);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(false);
        webView.getSettings().setAllowFileAccess(false);
        webView.getSettings().setAllowContentAccess(false);
        webView.getSettings().setMediaPlaybackRequiresUserGesture(true);
        webView.getSettings().setSupportZoom(false);
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> files,
                FileChooserParams params) {
                // System document picker: no storage permissions or network.
                // Only the user's existing private GLB is read on this phone.
                if (pendingFile != null) pendingFile.onReceiveValue(null);
                pendingFile = files;
                Intent pick = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                pick.addCategory(Intent.CATEGORY_OPENABLE);
                pick.setType("*/*");
                pick.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                try {
                    startActivityForResult(pick, PICK_PRIVATE_GLB);
                    return true;
                } catch (Exception e) {
                    Log.e(TAG,"Private GLB file chooser unavailable",e);
                    pendingFile.onReceiveValue(null);
                    pendingFile = null;
                    return false;
                }
            }
            @Override
            public boolean onConsoleMessage(ConsoleMessage message) {
                Log.i(TAG,"WEBGL_JS "+message.messageLevel()+" "+message.message());
                return true;
            }
        });
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view,
                WebResourceRequest request) {
                return localLoader.shouldInterceptRequest(request.getUrl());
            }
            @Override
            public void onPageFinished(WebView view, String url) {
                if (!LOCAL.equals(url)) {
                    Log.e(TAG,"Unexpected origin: "+url);
                    return;
                }
                // The built-in QA handshake reports actual secure RNG/WebGL
                // after the page's bundled shaders are loaded on Android.
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    if (webView == null) return;
                    webView.evaluateJavascript(
                        "(function(){var q=window.__DICE_QA__;return JSON.stringify({"+
                        "secure:window.isSecureContext,ready:Boolean(q&&q.ready),"+
                        "faces:q?q.faces:0,webgl2:q?q.WebGL:false,"+
                        "noGodot:q?!q.usesGodot:false,noJolt:q?!q.usesJolt:false"+
                        "});})()",
                        value -> Log.i(TAG,"ALPHA4_WEBGL_QA "+value));
                },2500);
            }
        });
        setContentView(webView);
        webView.loadUrl(LOCAL);
    }
    @Override
    protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != PICK_PRIVATE_GLB || pendingFile == null) return;
        Uri[] files = result == RESULT_OK && data != null && data.getData() != null
            ? new Uri[]{data.getData()} : null;
        pendingFile.onReceiveValue(files);
        pendingFile = null;
    }
    @Override
    protected void onDestroy() {
        if (pendingFile != null) {pendingFile.onReceiveValue(null);pendingFile = null;}
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
