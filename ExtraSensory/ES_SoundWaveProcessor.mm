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
#include "AudioFileReader.hpp"
#include "MFCCUtils.h"
#include "ES_DataBaseAccessor.h"

#define HF_SOUND_FILE_PRE   @"HF_SOUNDWAVE_PRE"
#define HF_SOUND_FILE_DUR   @"HF_SOUNDWAVE_DUR"

#define SAMPLING_RATE       22050.0
#define WINDOW_SIZE         2048
#define HOP_SIZE            1024
#define PREEMPH_COEF        0.97

#define MAX_ABS_VAL_KEY     @"max_abs_value"
#define NORMALIZER_KEY      @"normalization_multiplier"

typedef boost::shared_ptr<WM::AudioFileReader> AudioFileReaderRef;

@implementation ES_SoundWaveProcessor

@synthesize soundFileURLPre, soundFileURLDur;
@synthesize hfRecorderPre, hfRecorderDur;
@synthesize sampleDuration = _sampleDuration;

- (double) sampleDuration
{
    if (!_sampleDuration)
    {
        ES_AppDelegate *delegate = (ES_AppDelegate *)[[UIApplication sharedApplication] delegate];
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
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
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

- (BOOL) startDurRecording {
    NSLog(@"[SoundWaveProcessor] recordingForDuration %f",self.sampleDuration);
    if( ![hfRecorderDur isRecording] ) {
        BOOL success = [hfRecorderDur recordForDuration:self.sampleDuration];
        NSLog(@"[SoundWaveProcessor] Did we succeed to start recording audio: %@",success?@"success":@"fail");
        return success;
    }
    NSLog(@"[SoundWaveProcessor] it was in the middle of a recording");
    return YES;
}

- (void) pauseDurRecording {
    [hfRecorderDur stop];
}

- (void) processMFCC {
    NSLog(@"%@",[[NSBundle mainBundle] bundlePath]);
    NSLog(@"[ES_SoundWaveProcessor] processMFCC");
    NSString* soundFilePath = [[self.dataPath path] stringByAppendingPathComponent:HF_SOUND_FILE_DUR];
    int i = 0;
    while (![[NSFileManager defaultManager] fileExistsAtPath:soundFilePath]){
        NSLog(@"waiting 100 ms");
        [NSThread sleepForTimeInterval:.1];
        i++;
        if (i > 40){
            //don't wait more than 10 seconds
            NSLog(@"[SoundWaveProcessor] Waited too long (4 sec) and still no wav file. So giving up on MFCC this time :-( .");
            return;
        }
    }
    soundFileURLDur = [NSURL fileURLWithPath:soundFilePath];
    // Check audio file size:
    NSNumber *wavFileSize = nil;
    NSError *error = nil;
    [soundFileURLDur getResourceValue:&wavFileSize forKey:NSURLFileSizeKey error:&error];
    NSLog(@"[SoundWaveProcessor] Recorded sound file of size %@: %@",wavFileSize,soundFilePath);
    
    
    NSURL* MFCCFileURLDur = [NSURL fileURLWithPath:[[self.dataPath path] stringByAppendingPathComponent:[ES_DataBaseAccessor getMFCCFilename]]];
    NSLog( @"[SoundWaveProcessor] %@", MFCCFileURLDur );
    [self callAudio:(CFURLRef)soundFileURLDur toMFCC:MFCCFileURLDur];
}

- (void) callAudio: (const CFURLRef&)audioURL toMFCC:(NSURL*)MFCCURL {
    
    AudioFileReaderRef someReader = AudioFileReaderRef(new WM::AudioFileReader(audioURL));
    
    float max_abs_value = someReader->peak_abs_value();
    float normalization_multiplier = 1 / max_abs_value;
    [self writeAudioPropertiesFileWithMaxAbsVal:[NSNumber numberWithFloat:max_abs_value] andNormalizingMultiplier:[NSNumber numberWithFloat:normalization_multiplier]];

    FeatureTypeDTW::Features feats;
    WMAudioFilePreProcessInfo reader_info;
    reader_info.threshold_start_time = 0;
    reader_info.threshold_end_time = someReader->duration();
    reader_info.normalization_factor = normalization_multiplier;
    
    std::cout << "Computing MFCC features..." << std::endl;
    
    feats = get_mfcc_features(someReader,WINDOW_SIZE,SAMPLING_RATE,HOP_SIZE,PREEMPH_COEF,&reader_info);
    std::cout << "mfcc_features: " << feats.size() << "x" << feats[0].size() << std::endl;
    
    NSMutableString* arrayString = [[NSMutableString alloc] init];
    for (int i = 0; i<feats.size(); ++i) {
        for (int j = 0; j<feats[i].size(); ++j) {
            [arrayString appendString:[NSString stringWithFormat:@"%f,", feats[i].at(j)]];
        }
        [arrayString appendString:@"\n"];
    }
    //NSLog(@"array: %@",arrayString);
    NSError* err;
    BOOL success = [arrayString writeToURL:MFCCURL atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (success){
        NSLog(@"MFCC successfully written\n");
    }
}

- (void) writeAudioPropertiesFileWithMaxAbsVal:(NSNumber *)maxAbsVal andNormalizingMultiplier:(NSNumber *)normalizingMultiplier
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:maxAbsVal forKey:MAX_ABS_VAL_KEY];
    [dict setValue:normalizingMultiplier forKey:NORMALIZER_KEY];
    
    NSLog(@"[soundWaveProcessor] Audio properties: %@",dict);
    
    if (![NSJSONSerialization isValidJSONObject:dict]) {
        NSLog(@"[databaseAccessor] !!! Cannot write sound properties: not valid object for JSON. Data: %@",dict);
        return;
    }
    NSError *error;
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    NSString *outFilePath = [ES_DataBaseAccessor getDataFileFullPathForFilename:[ES_DataBaseAccessor getAudioPropertiesFilename]];
    
    if ([jsonObject writeToFile:outFilePath atomically:YES]) {
        NSLog(@"[soundWaveProcessor] Wrote audio properties file.");
    }
    else {
        NSLog(@"[soundWaveProcessor] Failed writing audio properties file.");
    }
}

@end