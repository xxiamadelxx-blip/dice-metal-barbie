package io.adeldice.rngfirst;

import android.app.Activity;
import android.os.Bundle;
import android.os.Build;
import android.view.WindowInsets;
import android.widget.FrameLayout;
import android.view.ViewGroup;
import android.content.Intent;
import android.net.Uri;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.ConsoleMessage;
import android.util.Log;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.widget.Toast;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.util.Locale;

/** Offline Android shell for genuine original BlenderKit D20, using native WebGL2.
 *  Private licensed GLB never committed to GitHub nor included in open-source APK.
 *  User selects it once; SHA-checked bytes live in getFilesDir() for next launches.
 */
public final class MainActivity extends Activity {
  private static final String HOST = "appassets.androidplatform.net";
  private static final String START = "https://"+HOST+"/alpha4-webgl.html";
  private static final String MODEL = "d20_selected_original_500k.glb";
  private static final String SHA = "60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39";
  private static final long MAX_BYTES = 30L*1024*1024;
  private static final int PICK_MODEL = 401;
  private ValueCallback<Uri[]> upload;
  private WebView browser;

  @Override public void onCreate(Bundle state) {
    super.onCreate(state);
    browser = new WebView(this);
    // Android 15 forces edge-to-edge for SDK 35. Preserve readable UI
    // by applying real system-bar insets to a native root container.
    FrameLayout root = new FrameLayout(this);
    root.setOnApplyWindowInsetsListener((view,insets)->{
      int left,top,right,bottom;
      if(Build.VERSION.SDK_INT>=30){
        android.graphics.Insets bars=insets.getInsets(WindowInsets.Type.systemBars());
        left=bars.left;top=bars.top;right=bars.right;bottom=bars.bottom;
      }else{
        left=insets.getSystemWindowInsetLeft();top=insets.getSystemWindowInsetTop();
        right=insets.getSystemWindowInsetRight();bottom=insets.getSystemWindowInsetBottom();
      }
      view.setPadding(left,top,right,bottom);
      return insets;
    });
    root.addView(browser,new FrameLayout.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,ViewGroup.LayoutParams.MATCH_PARENT));
    setContentView(root);
    WebSettings settings=browser.getSettings();
    settings.setJavaScriptEnabled(true);
    settings.setDomStorageEnabled(true);
    settings.setAllowContentAccess(true);
    settings.setAllowFileAccess(false);
    settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
    browser.setWebViewClient(new WebViewClient() {
      @Override public boolean shouldOverrideUrlLoading(WebView view,WebResourceRequest request) {
        return !HOST.equals(request.getUrl().getHost());
      }
      @Override public WebResourceResponse shouldInterceptRequest(WebView view,WebResourceRequest request) {
        Uri uri=request.getUrl();
        if (!"https".equals(uri.getScheme())||!HOST.equals(uri.getHost()))return denied();
        String path=uri.getPath();
        if(path==null||path.contains(".."))return denied();
        if(path.equals("/"))path="/alpha4-webgl.html";
        String fileName=path.substring(1);
        try{
          InputStream stream;
          String mime;
          if(fileName.equals(MODEL)){
            File privateModel=new File(getFilesDir(),MODEL);
            if(!privateModel.exists())return denied();
            stream=new FileInputStream(privateModel);
            mime="model/gltf-binary";
          }else if(fileName.equals("alpha4-webgl.html")||fileName.equals("glb-core.js")||fileName.equals("webgl-renderer.js")||fileName.equals("rng-core.js")){
            stream=getAssets().open(fileName);
            mime=fileName.endsWith(".html")?"text/html":"text/javascript";
          }else{return denied();}
          return new WebResourceResponse(mime,"UTF-8",stream);
        }catch(IOException e){return denied();}
      }
    });
    browser.setWebChromeClient(new WebChromeClient(){
      @Override public boolean onConsoleMessage(ConsoleMessage message){
        Log.i("AlphaPlainWebGL",message.message());
        return true;
      }
      @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params){
        if(upload!=null)upload.onReceiveValue(null);
        upload=callback;
        Intent open=new Intent(Intent.ACTION_OPEN_DOCUMENT);
        open.setType("*/*");
        open.addCategory(Intent.CATEGORY_OPENABLE);
        try{startActivityForResult(open,PICK_MODEL);return true;}
        catch(Exception e){upload.onReceiveValue(null);upload=null;return false;}
      }
    });
    browser.loadUrl(START);
  }
  private WebResourceResponse denied(){
    return new WebResourceResponse("text/plain","UTF-8",403,"Forbidden",
        java.util.Collections.emptyMap(),new ByteArrayInputStream(new byte[0]));
  }
  @Override protected void onActivityResult(int request,int result,Intent data){
    super.onActivityResult(request,result,data);
    if(request!=PICK_MODEL)return;
    Uri uri=(result==RESULT_OK&&data!=null)?data.getData():null;
    if(uri!=null){
      try{copyAndCheck(uri);}catch(Exception e){
        uri=null;
        Toast.makeText(this,"Неверный GLB: требуется оригинальный D20 500k",Toast.LENGTH_LONG).show();
      }
    }
    if(upload!=null){upload.onReceiveValue(uri==null?null:new Uri[]{uri});upload=null;}
  }
  private void copyAndCheck(Uri uri) throws Exception {
    MessageDigest md=MessageDigest.getInstance("SHA-256");
    File temp=new File(getFilesDir(),MODEL+".partial");
    long total=0;
    try(InputStream in=getContentResolver().openInputStream(uri);
        OutputStream out=new FileOutputStream(temp)){
      if(in==null)throw new IOException("Missing file");
      byte[] chunk=new byte[65536];int n;
      while((n=in.read(chunk))!=-1){total+=n;if(total>MAX_BYTES)throw new IOException("Too large");out.write(chunk,0,n);md.update(chunk,0,n);}
    }catch(Exception e){temp.delete();throw e;}
    StringBuilder hash=new StringBuilder();
    for(byte b:md.digest())hash.append(String.format(Locale.ROOT,"%02x",b&255));
    if(!SHA.equals(hash.toString())){temp.delete();throw new IOException("SHA mismatch");}
    File target=new File(getFilesDir(),MODEL);
    if(target.exists()&&!target.delete()){temp.delete();throw new IOException("Old file locked");}
    if(!temp.renameTo(target))throw new IOException("Rename failed");
    Toast.makeText(this,"Оригинальный D20 проверен и сохранён",Toast.LENGTH_SHORT).show();
  }
  @Override public void onBackPressed(){if(browser.canGoBack())browser.goBack();else super.onBackPressed();}
  @Override protected void onDestroy(){if(browser!=null)browser.destroy();super.onDestroy();}
}