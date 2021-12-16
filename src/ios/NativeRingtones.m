/********* NativeRingtones.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NativeRingtones : CDVPlugin

@property AVAudioPlayer * currentRingtone;

@property NSMutableDictionary* completeCallbacks;

- (void)get:(CDVInvokedUrlCommand*)command;
- (void)play:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)addCompleteListener:(CDVInvokedUrlCommand*)command;
@end

@implementation NativeRingtones

- (void)get:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    //NSString* echo = [command.arguments objectAtIndex:0];

    NSMutableArray *audioFileList;
    NSMutableArray *_systemSounds = nil;

    audioFileList = [[NSMutableArray alloc] init];
    _systemSounds = [NSMutableArray array];

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *directoryURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds"];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];

    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        }
        else if (! [isDirectory boolValue]) {
            //Get sound url
            NSString *soundUrl = [url.absoluteString stringByReplacingOccurrencesOfString:@"file://"
                                                                               withString:@""];

            //Get sound name
            NSString *last = [soundUrl pathComponents].lastObject;
            NSArray *Array = [last componentsSeparatedByString:@"."];
            NSString *soundName = [Array objectAtIndex:0];

            //Get sound store file category
            NSString *category = [[soundUrl stringByDeletingLastPathComponent] lastPathComponent];

            NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:soundName,@"Name",soundUrl,@"Url",category, @"Category", nil];

            [_systemSounds addObject:dic2];
        }
    }

/***   Test for store file to local folder
     NSData *fileData;
　　 fileData = [[NSFileManager defaultManager] contentsAtPath:@"/System/Library/Audio/UISounds/photoShutter.caf"];
     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
     NSString* pathCreate = [[paths objectAtIndex:0] stringByAppendingString:@"/Sounds"];
     NSString* pathCopy = [[paths objectAtIndex:0] stringByAppendingString:@"/Sounds/photoShutter.caf"];
     NSError *errorw1;
     NSError *errorw2;
     bool createDirectory = [[NSFileManager defaultManager] createDirectoryAtPath:pathCreate withIntermediateDirectories:YES attributes:nil error:&errorw1];
     bool existFile = [[NSFileManager defaultManager] fileExistsAtPath:pathCopy];
     if (existFile) {
       [[NSFileManager defaultManager] removeItemAtPath:pathCopy error:&errorw1];
     }
     bool success = [[NSFileManager defaultManager] copyItemAtPath:@"/System/Library/Audio/UISounds/photoShutter.caf" toPath:pathCopy error:&errorw2];
****/

    if (_systemSounds != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:_systemSounds];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSURL*) getFileURL:(NSString*)ringtoneUri
{
    NSString* basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
    NSString* pathFromWWW = [NSString stringWithFormat:@"%@/%@", basePath, ringtoneUri];

    NSURL *fileURL = [NSURL fileURLWithPath : pathFromWWW];
    if( ![[NSFileManager defaultManager] fileExistsAtPath:pathFromWWW]){
        fileURL = [NSURL fileURLWithPath : ringtoneUri];
    }
    return fileURL;
}

- (void)play:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    NSString* ringtoneUri = [command argumentAtIndex:0];
    BOOL playOnce = [[command argumentAtIndex:1 withDefault:[NSNumber numberWithBool:YES]] boolValue];
    NSInteger volume = [[command argumentAtIndex:2] integerValue];

    NSURL *fileURL = [self getFileURL: ringtoneUri];
    CFURLRef soundFileURLRef = (CFURLRef) CFBridgingRetain(fileURL);

    if (self.currentRingtone != nil && playOnce == false) {
        [self.currentRingtone stop];
        self.currentRingtone = nil;
    }

    AVAudioPlayer *_audioPlayer;

    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    _audioPlayer.delegate = self;

    if(volume < 0){
        _audioPlayer.volume = 1.0;
    }else{
        _audioPlayer.volume = volume / 100.00; // from 0.0 to 1.0
    }
    if (playOnce == false) {
        // Set any negative integer value to loop the sound indefinitely until you call the stop() method.
        _audioPlayer.numberOfLoops = -1;
    }

    self.currentRingtone = _audioPlayer;
    [_audioPlayer play];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    if (self.currentRingtone != nil) {
        [self.currentRingtone stop];
        self.currentRingtone = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    self.currentRingtone = nil;
    if (self.completeCallbacks != nil) {
        NSString* currentAudioID = player.url;
        NSString* callbackId = self.completeCallbacks[currentAudioID];
        if (callbackId) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            [self.completeCallbacks removeObjectForKey:currentAudioID];
        }
    }
}

- (void) addCompleteListener:(CDVInvokedUrlCommand *)command
{
    NSArray* arguments = command.arguments;
    NSString *ringtoneUri = [arguments objectAtIndex:0];

    if(self.completeCallbacks == nil) {
        self.completeCallbacks = [NSMutableDictionary dictionary];
    }
    self.completeCallbacks[[self getFileURL: ringtoneUri]] = command.callbackId;
}

@end
