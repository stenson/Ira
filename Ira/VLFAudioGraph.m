//
//  VLFAudioGraph.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFAudioGraph.h"
#include <stdlib.h>

static NSString * const kRecordedFileName = @"%@/recorded-program-output.m4a";
static Float32 const kMicrophoneGain = -40;

static const Float32 tenBandEQFreqs[10] = { 32., 64., 128., 256., 512., 1024., 2048., 4096., 8192., 16384. };
static const Float32 tenBandEQDecibels[10] = { 13.2, 11.6, 9.4, -1.1, -2.8, -3.5, -5.4, -1.2, 4.3, -12.0 };

@interface VLFAudioGraph () {
    AUGraph graph;
    AudioUnit filePlayerUnit;
    AudioUnit _finalMixUnit;
    AUNode _finalMix;
    CFURLRef destinationURL;
    ExtAudioFileRef outputFile;
    AudioStreamBasicDescription _aacASBD;
    AudioStreamBasicDescription _notifierASBD;
    
    AudioUnit _filePlayers[4];
    int _filePlayerCount;
    
    int _loopingState;
    BOOL recording;
    BOOL graphEnabled;
    
    float _micAverage;
    int _micAverageCount;
    
    Float32 *_scratchBuffer;
}
@end

@implementation VLFAudioGraph

@synthesize mixerUnit = _mixerUnit;
@synthesize rioUnit = _rioUnit;

+ (UInt32)playbackURL:(CFURLRef)url withLoopCount:(UInt32)loopCount andUnit:(AudioUnit)unit
{
    AudioFileID recordedFile;
    CheckError(AudioFileOpenURL(url, kAudioFileReadPermission, 0, &recordedFile), "read");
    
    CheckError(AudioUnitSetProperty(unit, kAudioUnitProperty_ScheduledFileIDs,
                                    kAudioUnitScope_Global, 0, &recordedFile, sizeof(recordedFile)), "file to unit");
    
    
    UInt64 numPackets;
    UInt32 propSize = sizeof(numPackets);
    CheckError(AudioFileGetProperty(recordedFile, kAudioFilePropertyAudioDataPacketCount, &propSize, &numPackets), "packets");
    
    AudioStreamBasicDescription fileASBD;
    UInt32 asbdSize = sizeof(fileASBD);
    CheckError(AudioFileGetProperty(recordedFile, kAudioFilePropertyDataFormat, &asbdSize, &fileASBD), "file format");
    
    UInt32 framesToPlay = numPackets * fileASBD.mFramesPerPacket;
    
    ScheduledAudioFileRegion rgn;
    memset(&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    //rgn.mCompletionProc = FileCompleteCallback; 
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = recordedFile;
    rgn.mLoopCount = loopCount;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = framesToPlay;
    
    CheckError(AudioUnitSetProperty(unit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &rgn, sizeof(rgn)), "region");
    
    AudioTimeStamp startTime;
    memset(&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    
    CheckError(AudioUnitSetProperty(unit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
               "start time");
    
    return 0;
}

static void InterruptionListener (void *inUserData, UInt32 inInterruptionState) {
	NSLog(@"INTERRUPTION");
}

static OSStatus RecordingCallback (void *inRefCon,
                                   AudioUnitRenderActionFlags *ioActionFlags,
                                   const AudioTimeStamp *inTimeStamp,
                                   UInt32 inBusNumber,
                                   UInt32 inNumberFrames,
                                   AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFAudioGraph *ag = (__bridge VLFAudioGraph *)inRefCon;
        
        if (ag->recording) {
            CheckError(ExtAudioFileWriteAsync(ag->outputFile, inNumberFrames, ioData), "write to file");
        }
    }
    
    return noErr;
}

static OSStatus MicrophoneCallback (void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
        VLFAudioGraph *graph = (__bridge VLFAudioGraph *)inRefCon;
        
        vDSP_vflt16(ioData->mBuffers[0].mData, 1, graph->_scratchBuffer, 1, inNumberFrames);
        
        float avg = 0.0;
        vDSP_meamgv(ioData->mBuffers[0].mData, 1, &avg, inNumberFrames);
        //vDSP_meamgv(graph->_scratchBuffer, 1, &avg, inNumberFrames);
        
        graph->_micAverageCount++;
        graph->_micAverage += avg;
    }
    
    return noErr;
}

static void FileCompleteCallback(void *userData, ScheduledAudioFileRegion *bufferList, OSStatus status)
{
    NSLog(@"File COMPLETE");
}

- (void)notifyNoInputAvailable
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No audio input"
                                                    message:@"No audio input"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (float)getMicrophoneAverageDecibels
{
    float average = _micAverage / _micAverageCount;
    _micAverage = 0.0;
    _micAverageCount = 0;
    
    //NSLog(@"%f", average);
    return average;
}

- (Float64)currentHardwareSampleRate
{
    Float64 hardwareSampleRate;
	UInt32 propSize = sizeof (hardwareSampleRate);
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
									   &propSize,
									   &hardwareSampleRate),
			   "Couldn't get hardwareSampleRate");
    
	NSLog (@"hardwareSampleRate = %f", hardwareSampleRate);
    return hardwareSampleRate;
}

- (AUNode)addNodeWithType:(OSType)type AndSubtype:(OSType)subtype
{
    AudioComponentDescription acd;
    AUNode node;
    
    acd.componentType = type;
    acd.componentSubType = subtype;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    
    CheckError(AUGraphAddNode(graph, &acd, &node), "adding node");
    return node;
}

- (AudioStreamBasicDescription)canonicalASBD
{    
	AudioStreamBasicDescription myASBD;
	memset (&myASBD, 0, sizeof (myASBD));
	myASBD.mSampleRate = [self currentHardwareSampleRate];
	myASBD.mFormatID = kAudioFormatLinearPCM;
	myASBD.mFormatFlags = kAudioFormatFlagsCanonical;
	myASBD.mBytesPerPacket = 4;
	myASBD.mFramesPerPacket = 1;
	myASBD.mBytesPerFrame = 4;
	myASBD.mChannelsPerFrame = 2;
	myASBD.mBitsPerChannel = 16;
    
    return myASBD;
}

- (AudioUnit)configureEQNode:(AUNode)eqNode WithHz:(UInt32)hz Db:(UInt32)db AndQ:(Float32)q
{
    AudioUnit eq;
    CheckError(AUGraphNodeInfo(graph, eqNode, NULL, &eq), "eqUnit");
    CheckError(AudioUnitSetParameter(eq, kParametricEQParam_CenterFreq, kAudioUnitScope_Global, 0, hz, 0),  "set center freq");
    CheckError(AudioUnitSetParameter(eq, kParametricEQParam_Gain, kAudioUnitScope_Global, 0, db, 0), "set gain");
    return eq;
}


- (void)setupGraph
{
    CheckError(NewAUGraph(&graph), "instantiate graph");
    
    AUNode rio = [self addNodeWithType:kAudioUnitType_Output AndSubtype:kAudioUnitSubType_RemoteIO];
    AUNode mixer = [self addNodeWithType:kAudioUnitType_Mixer AndSubtype:kAudioUnitSubType_MultiChannelMixer];
    
    AUNode nBandEq = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_NBandEQ];
    AUNode lowpass = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_LowPassFilter];
    AUNode filePlayer = [self addNodeWithType:kAudioUnitType_Generator AndSubtype:kAudioUnitSubType_AudioFilePlayer];
    _finalMix = [self addNodeWithType:kAudioUnitType_Mixer AndSubtype:kAudioUnitSubType_MultiChannelMixer];
    
    CheckError(AUGraphOpen(graph), "open graph");
    
    AudioUnit nBandEqUnit;
    AudioUnit lowpassUnit;
    
    CheckError(AUGraphNodeInfo(graph, rio, NULL, &_rioUnit), "rioUnit");
    CheckError(AUGraphNodeInfo(graph, mixer, NULL, &_mixerUnit), "mixerUnit");
    CheckError(AUGraphNodeInfo(graph, nBandEq, NULL, &nBandEqUnit), "nbandeqUnit");
    CheckError(AUGraphNodeInfo(graph, lowpass, NULL, &lowpassUnit), "lowpassUnit");
    CheckError(AUGraphNodeInfo(graph, _finalMix, NULL, &_finalMixUnit), "finalMixUnit");
    CheckError(AUGraphNodeInfo(graph, filePlayer, NULL, &filePlayerUnit), "filePlayerUnit");
    
    UInt32 maxBands;
    UInt32 maxBandsSize = sizeof(maxBands);
    CheckError(AudioUnitGetProperty(nBandEqUnit, kAUNBandEQProperty_MaxNumberOfBands, kAudioUnitScope_Global, 0, &maxBands, &maxBandsSize), "max bands");
    NSLog(@"MAX BANDS %lu", maxBands);
    
    UInt32 numBands = 10;
    CheckError(AudioUnitSetProperty(nBandEqUnit, kAUNBandEQProperty_NumberOfBands, kAudioUnitScope_Global, 0, &numBands, sizeof(numBands)), "set bands");
    
    for (int i = 0; i < 10; i++) {
        CheckError(AudioUnitSetParameter(nBandEqUnit, kAUNBandEQParam_Frequency + i, kAudioUnitScope_Global, 0, tenBandEQFreqs[i], 0), "nband freq");
        CheckError(AudioUnitSetParameter(nBandEqUnit, kAUNBandEQParam_Gain + i, kAudioUnitScope_Global, 0, tenBandEQDecibels[i], 0), "nband gain");
        CheckError(AudioUnitSetParameter(nBandEqUnit, kAUNBandEQParam_Bandwidth + i, kAudioUnitScope_Global, 0, 10.0, 0), "n band q");
    }
    
    CheckError(AudioUnitSetParameter(lowpassUnit, kLowPassParam_CutoffFrequency, kAudioUnitScope_Global, 0, 2000.0, 0), "cut freq");

    UInt32 oneFlag = 1;
	AudioUnitElement bus0 = 0;
	CheckError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, bus0, &oneFlag, sizeof(oneFlag)),
			   "Couldn't enable RIO output");
	
	AudioUnitElement bus1 = 1;
	CheckError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, bus1, &oneFlag, sizeof(oneFlag)),
			   "Couldn't enable RIO input");
    
    AudioStreamBasicDescription effectASBD;
    UInt32 asbdSize = sizeof(effectASBD);
    memset(&effectASBD, 0, asbdSize);
    
    CheckError(AudioUnitGetProperty(nBandEqUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &effectASBD, &asbdSize),
               "get the effect asbd");
    
    Float64 hardwareSampleRate;
	UInt32 propSize = sizeof (hardwareSampleRate);
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &propSize, &hardwareSampleRate),
			   "Couldn't get hardwareSampleRate");
    
    NSLog(@"hardware sample rate %f", hardwareSampleRate);
    NSLog(@"current effect sample rate %f", effectASBD.mSampleRate);
    
    effectASBD.mSampleRate = hardwareSampleRate;
    
    // set kAudioUnitProperty_StreamFormat on input & output of eqUnit with updated sample rate (is it always 44100?)

    CheckError(AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &effectASBD, asbdSize), "set asbd on mixer output");
    
    AudioUnit notifierUnit = _finalMixUnit;
    CheckError(AudioUnitAddRenderNotify(notifierUnit, &RecordingCallback, (__bridge void*)self), "render notify");
    CheckError(AudioUnitGetProperty(notifierUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_notifierASBD, &asbdSize), "notifier ABSD");
    
    CheckError(AudioUnitAddRenderNotify(lowpassUnit, &MicrophoneCallback, (__bridge void*)self), "mic notify");
    //CheckError(AudioUnitAddRenderNotify(_finalMixUnit, &MicrophoneCallback, (__bridge void*)self), "mic notify");
    
    CheckError(AUGraphConnectNodeInput(graph, rio, 1, mixer, 0), "plug");
    
    if (YES) {
        if (NO) {
//            CheckError(AUGraphConnectNodeInput(graph, mixer, 0, eqNodes[0], 0), "plug");
//            int limit = TARGET_IPHONE_SIMULATOR ? 2 : 9;
//            for (int p = 1; p <= limit; p++) {
//                CheckError(AUGraphConnectNodeInput(graph, eqNodes[p-1], 0, eqNodes[p], 0), "eq plug");
//            }
//            CheckError(AUGraphConnectNodeInput(graph, eqNodes[limit], 0, lowpass, 0), "plug");
        } else {
            CheckError(AUGraphConnectNodeInput(graph, mixer, 0, nBandEq, 0), "plug");
            CheckError(AUGraphConnectNodeInput(graph, nBandEq, 0, lowpass, 0), "plug");
            CheckError(AUGraphConnectNodeInput(graph, lowpass, 0, _finalMix, 0), "plug");
        }
    } else {
        CheckError(AUGraphConnectNodeInput(graph, mixer, 0, _finalMix, 0), "plug");
    }

    CheckError(AUGraphConnectNodeInput(graph, filePlayer, 0, _finalMix, 1), "plug");
    
    // to headphones
    CheckError(AUGraphConnectNodeInput(graph, _finalMix, 0, rio, 0), "plug");
    
    _aacASBD = [self getAACFormat];
    
    [self enableGraph];
}

- (int)fetchFilePlayer
{
    AudioUnit unit;
    AUNode player = [self addNodeWithType:kAudioUnitType_Generator AndSubtype:kAudioUnitSubType_AudioFilePlayer];
    
    CheckError(AUGraphNodeInfo(graph, player, NULL, &unit), "new file player unit");
    CheckError(AUGraphConnectNodeInput(graph, player, 0, _finalMix, _filePlayerCount + 2), "plug in new file player");
    
    _filePlayers[_filePlayerCount] = unit;
    _filePlayerCount++;
    
    CheckError(AUGraphUpdate(graph, NULL), "update");
    
    return _filePlayerCount - 1;
}

- (AudioUnit)getFilePlayerForIndex:(int)index
{
    return _filePlayers[index];
}

- (void)setGain:(Float32)gain forMixerInput:(int)index
{
    CheckError(AudioUnitSetParameter(_finalMixUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, index + 2, gain, 0), "mixer gain");
}

- (UInt32)playbackURL:(CFURLRef)url withLoopCount:(UInt32)loopCount andUnitIndex:(int)index
{
    return [VLFAudioGraph playbackURL:url withLoopCount:loopCount andUnit:_filePlayers[index]];
}

- (void)playbackURL:(CFURLRef)url withLoopCount:(UInt32)loopCount
{
    [VLFAudioGraph playbackURL:url withLoopCount:loopCount andUnit:filePlayerUnit];
}

- (void)playbackRecording
{
    [self playbackURL:destinationURL withLoopCount:0];
}

- (NSString *)generateRecordedOutputFileName
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dc = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
 
    NSString *path = @"%@/";
    NSString *withDate = [NSString stringWithFormat:@"%i-%i-%i-at-%i-%i-%i.m4a", [dc day], [dc month], [dc year], [dc hour], [dc minute], [dc second]];
    
    return [path stringByAppendingString: withDate];
}

- (BOOL)toggleRecording
{
    if (self->recording) {
        [self stopRecording];
        return NO;
    } else {
        [self startRecording];
        return YES;
    }
}

- (void)stopRecording
{
    self->recording = NO;
    CheckError(ExtAudioFileDispose(outputFile), "dispose");
    
    [self playbackRecording];
}

- (void)startRecording
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: [self generateRecordedOutputFileName], documentsDirectory];
    destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    
    CheckError(ExtAudioFileCreateWithURL(destinationURL, kAudioFileM4AType, &_aacASBD, NULL, kAudioFileFlags_EraseFile, &outputFile),
               "create ext audio output file");
    
    CheckError(ExtAudioFileSetProperty(outputFile, kExtAudioFileProperty_ClientDataFormat, sizeof(_notifierASBD), &_notifierASBD),
               "create file for format");
    
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    UInt32 codecSize = sizeof(codec);
    CheckError(ExtAudioFileSetProperty(outputFile, kExtAudioFileProperty_CodecManufacturer, codecSize, &codec), "set codec");
    
    UInt32 convSize = sizeof(AudioConverterRef);
    AudioConverterRef convRef = NULL;
    CheckError(ExtAudioFileGetProperty(outputFile, kExtAudioFileProperty_AudioConverter, &convSize, &convRef), "converter");
    
    UInt32 bitRateSize = sizeof(UInt32);
    UInt32 bitRate = 64000;
    CheckError(AudioConverterSetProperty(convRef, kAudioConverterEncodeBitRate, bitRateSize, &bitRate), "bit rate");
    
    CFArrayRef config = NULL;
    CheckError(ExtAudioFileSetProperty(outputFile, kExtAudioFileProperty_ConverterConfig, sizeof(config), &config), "config");
    
    CheckError(ExtAudioFileWriteAsync(outputFile, 0, NULL), "prime");
    ExtAudioFileSeek(outputFile, 0);
    
    self->recording = YES;
}

- (AudioStreamBasicDescription)getAACFormat
{
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    UInt32 asbdSize = sizeof(asbd);
    
    asbd.mChannelsPerFrame = 1;
    asbd.mFormatID = kAudioFormatMPEG4AAC;
    
    CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &asbdSize, &asbd), "complete asbd for aac");
    
    return asbd;
}

- (void)printASBD: (AudioStreamBasicDescription) asbd
{    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    if (asbd.mFormatFlags & kAudioFormatFlagIsSignedInteger) {
        NSLog(@"YES IT's INTEGER");
    }
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lu",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
}

- (BOOL)enableGraph
{
    if (self->graphEnabled == YES) {
        return YES;
    } else {
        self->graphEnabled = YES;
        NSLog(@"ENABLING GRAPH");
        CheckError(AUGraphInitialize(graph), "initialize graph");
        CheckError(AudioSessionSetActive(true), "active");
        CheckError(AUGraphStart(graph), "start");
        return YES;
    }
}

- (BOOL)disableGraph
{
    self->graphEnabled = NO;
    NSLog(@"stopping");

    CheckError(AUGraphStop(graph), "stop");
    CheckError(AudioSessionSetActive(false), "inactive");
    CheckError(AUGraphUninitialize(graph), "uninitialize");
    return YES;
}

- (BOOL)setupAudioSession
{
    _scratchBuffer = (void *) malloc(2048 * sizeof(Float32));
    
    _filePlayerCount = 0;
    self->recording = NO;
    
    _micAverage = 0.0;
    _micAverageCount = 0;
    
    CheckError(AudioSessionInitialize(NULL, kCFRunLoopDefaultMode, InterruptionListener, (__bridge void *)self),
               "couldn't initialize audio session");
    
	UInt32 category = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category),
               "Couldn't set category on audio session");
    
	UInt32 ui32PropertySize = sizeof (UInt32);
	UInt32 inputAvailable;
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &ui32PropertySize, &inputAvailable),
			   "Couldn't get current audio input available prop");
    
    float aBufferLength = 0.005; // In seconds
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,  sizeof(aBufferLength), &aBufferLength);
    
//    UInt32 override = kAudioSessionOverrideAudioRoute_Speaker;
//    CheckError(AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(override), &override), "override to speaker");
    
	if (!inputAvailable) {
		[self notifyNoInputAvailable];
        return NO;
	} else {
        [self setupGraph];
        return YES;
    }
}

@end
