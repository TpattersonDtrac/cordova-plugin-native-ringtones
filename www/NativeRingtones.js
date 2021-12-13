var exec = require('cordova/exec');

function RingtoneManager() {
    this.propTest = 'superTest';
}


/**
 * Get the ringtone list of the device
 *
 * @param {Object}
 *            Set the ringtone list to the attribute ringtoneList of the object
 */
RingtoneManager.prototype.getRingtone = function (successCallback, errorCallback, ringtoneType) {
    exec(successCallback, errorCallback, "NativeRingtones", "get", [ringtoneType]);
};

RingtoneManager.prototype.playRingtone = function (ringtoneUri, playOnce, volume, streamType, successCallback, errorCallback, completeCallback) {
    if (!successCallback) {
        successCallback = function (success) { };
    }

    if (!errorCallback) {
        errorCallback = function (error) { };
    }

    if (typeof playOnce == "undefined") {
        playOnce = true;
    }

    if (typeof volume == "undefined") {
        volume = 100;
    } else {
        if (volume < 0) {
            volume = -1;
        } else if (volume > 100) {
            volume = 100;
        }
    }

    if (typeof streamType == "undefined") {
        streamType = -1;
    }

    if(typeof completeCallback === "function") {
        exec(completeCallback, errorCallback, "NativeRingtones", "addCompleteListener", [ringtoneUri]);
    }
    exec(successCallback, errorCallback, "NativeRingtones", "play", [ringtoneUri, playOnce, volume, streamType]);
};

RingtoneManager.prototype.stopRingtone = function (successCallback, errorCallback) {
    if (!successCallback) {
        successCallback = function (success) { };
    }
    if (!errorCallback) {
        errorCallback = function (error) { };
    }

    exec(successCallback, errorCallback, "NativeRingtones", "stop", []);
};

// https://developer.android.com/reference/android/media/AudioManager.html
RingtoneManager.STREAM_VOICE_CALL = 0;
RingtoneManager.STREAM_SYSTEM = 1;
RingtoneManager.STREAM_RING = 2;
RingtoneManager.STREAM_MUSIC = 3;
RingtoneManager.STREAM_ALARM = 4;
RingtoneManager.STREAM_NOTIFICATION = 5;
RingtoneManager.STREAM_DTMF = 8;
RingtoneManager.STREAM_ACCESSIBILITY = 10;

module.exports = new RingtoneManager();
