package org.dicemetalbarbie.alpha4webgl;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
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
    private WebView webView;

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
    protected void onDestroy() {
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
