package cordova.plugin.nativeRingtones;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.*;

import android.content.ContentValues;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.media.RingtoneManager;
import android.media.Ringtone;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.database.Cursor;
import android.content.Context;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;

/**
 * This class echoes a string called from JavaScript.
 */
public class NativeRingtones extends CordovaPlugin {

    private static MediaPlayer currentRingtone = null;
    private static HashMap<String, CallbackContext> completeCallbacks;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("get")){
            return this.get(args.getString(0), callbackContext);
        }
        else if (action.equals("play")){
            // ringtoneUri, playOnce, volume, streamType
            return this.play(args.getString(0), args.getBoolean(1), args.getInt(2), args.getInt(3), callbackContext);
        }
        else if (action.equals("stop")){
            return this.stop(callbackContext);
        }
        else if (action.equals("addCompleteListener")) {
            if (completeCallbacks == null) {
                completeCallbacks = new HashMap<String, CallbackContext>();
            }
            try {
                String audioID = args.getString(0);
                completeCallbacks.put(audioID, callbackContext);
            } catch (JSONException e) {
                callbackContext.sendPluginResult(new PluginResult(Status.ERROR, e.toString()));
            }
            return true;
        }
        return false;
    }

  private boolean get(String ringtoneType, final CallbackContext callbackContext) throws JSONException{
        RingtoneManager manager = new RingtoneManager(this.cordova.getActivity().getBaseContext());

        //The default value if ringtone type is "notification"
        if (ringtoneType == "alarm") {
            manager.setType(RingtoneManager.TYPE_ALARM);
        } else if (ringtoneType == "ringtone"){
            manager.setType(RingtoneManager.TYPE_RINGTONE);
        } else {
            manager.setType(RingtoneManager.TYPE_NOTIFICATION);
        }

        Cursor cursor = manager.getCursor();
        JSONArray ringtoneList = new JSONArray();

        while (cursor.moveToNext()) {
            String notificationTitle = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX);
            String notificationUri = cursor.getString(RingtoneManager.URI_COLUMN_INDEX) + "/" + cursor.getString(RingtoneManager.ID_COLUMN_INDEX);

            /****   Transfer Content URI to file URI   ******* /
            /* String filePath;

            if (notificationUri != null && "content".equals(notificationUri.getScheme())) {
                Cursor cursor1 = this.cordova.getActivity().getBaseContext().getContentResolver().query(notificationUri, new String[] {
                    android.provider.MediaStore.Images.ImageColumns.DATA
                }, null, null, null);
                cursor1.moveToFirst();
                filePath = cursor1.getString(0);
                cursor1.close();
            } else {
                filePath = notificationUri.getPath();
            }*/

            JSONObject json = new JSONObject();
            json.put("Name", notificationTitle);
            json.put("Url", notificationUri);

            ringtoneList.put(json);
        }

        if (ringtoneList.length() > 0) {
            callbackContext.success(ringtoneList);
        } else {
            callbackContext.error("Can't get system Ringtone list");
        }

        return true;
    }

    private boolean play(String ringtoneUri, boolean playOnce, int volume, int streamType, final CallbackContext callbackContext) throws JSONException{
        try {
            if (streamType == -1) {
                streamType = AudioManager.STREAM_NOTIFICATION;
            }

            if (currentRingtone != null && !playOnce) {
                currentRingtone.stop();
                currentRingtone.release();
                currentRingtone = null;
            }

            Context ctx = this.cordova.getActivity().getApplicationContext();

            MediaPlayer ringtoneSound = new MediaPlayer();
            ringtoneSound.setDataSource(ctx, Uri.parse(ringtoneUri));
            ringtoneSound.setLooping(!playOnce);
            ringtoneSound.setAudioStreamType(streamType);
            if(volume >= 0) ringtoneSound.setVolume(volume * 0.01f, volume * 0.01f);
            ringtoneSound.prepare();
            currentRingtone = ringtoneSound;
            if (playOnce) {
                ringtoneSound.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                    public void onCompletion(MediaPlayer mp) {
                        mp.stop();
                        mp.release();
                        if (completeCallbacks != null) {
                            CallbackContext callbackContext = completeCallbacks.get(ringtoneUri);
                            if (callbackContext != null) {
                                try {
                                    JSONObject done = new JSONObject();
                                    done.put("id", ringtoneUri);
                                    callbackContext.sendPluginResult(new PluginResult(Status.OK, done));
                                } catch (JSONException e) {
                                    callbackContext.sendPluginResult(new PluginResult(Status.ERROR, e.toString()));
                                }
                            }
                        }
                    }
                });
            }

            ringtoneSound.start();
            callbackContext.success("Play the ringtone succennfully!");
        } catch (Exception e) {
            callbackContext.error("Can't play the ringtone!");
        }

        return true;
    }

    private boolean stop(final CallbackContext callbackContext){
        if (currentRingtone != null) {
            currentRingtone.stop();
            currentRingtone.release();
            currentRingtone = null;

            if(callbackContext != null) callbackContext.success("Stop the ringtone successfully!");
            return true;
        } else {
            if(callbackContext != null) callbackContext.error("Can't stop the ringtone!");
            return false;
        }
    }

    @Override
    public void onDestroy(){
        this.stop(null);
        super.onDestroy();
    }

}
