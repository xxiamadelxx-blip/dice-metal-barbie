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
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView source, ValueCallback<Uri[]> callback,
                                                       FileChooserParams params) {
                if (pendingFiles != null) pendingFiles.onReceiveValue(null);
                pendingFiles = callback;
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("*/*");
                intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{
                    "model/gltf-binary", "application/octet-stream", "application/gltf-buffer"});
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