//
//  ES_SoundWaveProcessor.h
//  Sensor_Accessor
//
//  Created by Peter Zhao on 4/5/12.
//  Copyright (c) 2012 CALab. All rights reserved.
//
//
#import "ES_SoundWaveProcessor.h"
#import "ES_AppDelegate.h"
#import "ES_User.h"
#import "ES_Settings.h"

#define HF_SOUND_FILE_PRE   @"HF_SOUNDWAVE_PRE"
#define HF_SOUND_FILE_DUR   @"HF_SOUNDWAVE_DUR"

@implementation ES_SoundWaveProcessor

@synthesize soundFileURLPre, soundFileURLDur;
@synthesize hfRecorderPre, hfRecorderDur;
@synthesize sampleDuration = _sampleDuration;

- (double) sampleDuration
{
    if (!_sampleDuration)
    {
        ES_AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        _sampleDuration = [delegate.user.settings.sampleDuration doubleValue];
    }
    return _sampleDuration;
}

+ (NSString*) hfSoundFileNamePre {
    return HF_SOUND_FILE_PRE;
}

+ (NSString*) hfSoundFileNameDur {
    return HF_SOUND_FILE_DUR;
}

-(NSURL*) dataPath
{
    //--// Grab the user document's directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *dataPath = [fileManager URLForDirectory: NSDocumentDirectory
                                          inDomain: NSUserDomainMask
                                 appropriateForURL: nil
                                            create: YES
                                             error: nil];
    return [NSURL fileURLWithPath:[[dataPath path] stringByAppendingPathComponent:@"data"]];
}

-(id) init {
    self = [super init];
    
    if (self) {
        //--// Initializing an audio session & start our session
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        //soundFileURLPre = [NSURL fileURLWithPath:[[self.dataPath path] stringByAppendingPathComponent:HF_SOUND_FILE_PRE]];
        
        soundFileURLDur = [NSURL fileURLWithPath:[[self.dataPath path] stringByAppendingPathComponent:HF_SOUND_FILE_DUR]];
        
        //--// Initialize high freq recorder
        // See here: http://developer.apple.com/library/ios/#DOCUMENTATION/AudioVideo/Conceptual/MultimediaPG/UsingAudio/UsingAudio.html
        // for why we need to use AppleIMA4 versus MPEG4AAC when recording.
        //
        // Important Excerpt:
        //      For AAC, MP3, and ALAC (Apple Lossless) audio, decoding can take place using hardware-assisted codecs.
        //      While efficient, this is limited to one audio stream at a time. If you need to play multiple sounds
        //      simultaneously, store those sounds using the IMA4 (compressed) or linear PCM (uncompressed) format.
        //
        NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithFloat: 44100.0],            AVSampleRateKey,
                                        [NSNumber numberWithInt: kAudioFormatAppleIMA4], AVFormatIDKey,
                                        [NSNumber numberWithInt: 1],                    AVNumberOfChannelsKey,
                                        [NSNumber numberWithInt: AVAudioQualityMedium], AVEncoderAudioQualityKey, nil];
        
        //NSError *hferrorPre = nil;
        //hfRecorderPre = [[AVAudioRecorder alloc] initWithURL: soundFileURLPre
        //                                            settings: recordSettings
        //                                               error: &hferrorPre];
        //if( hferrorPre != nil ) {
        //    NSLog( @"[SoundWaveProcessor] ERROR: %@", [hferrorPre localizedDescription] );
        //}
        
        NSError *hferrorDur = nil;
        // records to the url of soundFileURLDur
        hfRecorderDur = [[AVAudioRecorder alloc] initWithURL: soundFileURLDur
                                                    settings: recordSettings
                                                       error: &hferrorDur];
        
        if( hferrorDur != nil ) {
            NSLog( @"[SoundWaveProcessor] ERROR: %@", [hferrorDur localizedDescription] );
        }
        
        
        //[hfRecorderPre setDelegate:self];
        [hfRecorderDur setDelegate:self];
        
        //[hfRecorderPre prepareToRecord];
        [hfRecorderDur prepareToRecord];
        
        //hfRecorderPre.meteringEnabled = YES;
        hfRecorderDur.meteringEnabled = YES;
        
    }
    
    return self;
}

- (void) startPreRecording {
    if( ![hfRecorderPre isRecording] ) {
        [hfRecorderPre record];
    }
}

- (void) pausePreRecording {
    [hfRecorderPre stop];
}

- (void) startDurRecording {
    if( ![hfRecorderDur isRecording] ) {
        [hfRecorderDur recordForDuration:self.sampleDuration];
    }
}

- (void) pauseDurRecording {
    [hfRecorderDur stop];
}

@end