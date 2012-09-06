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
static Float32 const kMicrophoneGain = 20;

@interface VLFAudioGraph () {
    AUGraph graph;
    AudioUnit eqUnit;
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
    
    UInt32 playableFrames;
    playableFrames = audioFileDuration(recordedFile, fileASBD);
    
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
    
    return playableFrames;
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
        
//        AudioSampleType *buffer = (AudioSampleType *)ioData->mBuffers[0].mData;
//        printf("%d\n", MAX(abs(buffer[0])-10000, 0));
        
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
        
        AudioSampleType *buffer = (AudioSampleType *)ioData->mBuffers[0].mData;
        
        int shifted = (int)fabsf((float)(buffer[0] << 9));
        printf("%d\n", MAX(shifted, 0));
        
        //vDSP_vflt16(ioData->mBuffers[0].mData, 1, button->_scratchBuffer, 1, inNumberFrames);
    }
    
    return noErr;
}

//static void FileCompleteCallback(void *userData, ScheduledAudioFileRegion *bufferList, OSStatus status)
//{
//    NSLog(@"File COMPLETE");
//}

- (void)notifyNoInputAvailable
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No audio input"
                                                    message:@"No audio input"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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

- (void)configureDynamicsUnit:(AudioUnit)dpUnit
                WithThreshold:(UInt32)t
                     headroom:(UInt32)h
               expansionRatio:(Float32)er
           expansionThreshold:(UInt32)et
                   attackTime:(Float32)at
                  releaseTime:(Float32)rt 
                      andGain:(UInt32)g
{
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_Threshold, kAudioUnitScope_Global, 0, t, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_HeadRoom, kAudioUnitScope_Global, 0, h, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_ExpansionRatio, kAudioUnitScope_Global, 0, er, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_ExpansionThreshold, kAudioUnitScope_Global, 0, et, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_AttackTime, kAudioUnitScope_Global, 0, at, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_ReleaseTime, kAudioUnitScope_Global, 0, rt, 0), "param");
    CheckError(AudioUnitSetParameter(dpUnit, kDynamicsProcessorParam_MasterGain, kAudioUnitScope_Global, 0, g, 0), "param");
}


- (void)setupGraph
{
    CheckError(NewAUGraph(&graph), "instantiate graph");
    
    AUNode rio = [self addNodeWithType:kAudioUnitType_Output AndSubtype:kAudioUnitSubType_RemoteIO];
    AUNode mixer = [self addNodeWithType:kAudioUnitType_Mixer AndSubtype:kAudioUnitSubType_MultiChannelMixer];
    
    AUNode eq = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_ParametricEQ];
    AUNode eq2 = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_ParametricEQ];
    AUNode eq3 = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_ParametricEQ];
    AUNode eq4 = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_ParametricEQ];
    
    AUNode lowpass = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_LowPassFilter];
    AUNode dp = [self addNodeWithType:kAudioUnitType_Effect AndSubtype:kAudioUnitSubType_DynamicsProcessor];
    
    AUNode filePlayer = [self addNodeWithType:kAudioUnitType_Generator AndSubtype:kAudioUnitSubType_AudioFilePlayer];
    _finalMix = [self addNodeWithType:kAudioUnitType_Mixer AndSubtype:kAudioUnitSubType_MultiChannelMixer];
    
    AUNode converter = [self addNodeWithType:kAudioUnitType_FormatConverter AndSubtype:kAudioUnitSubType_AUConverter];
    
    CheckError(AUGraphOpen(graph), "open graph");
    
    AudioUnit dpUnit;
    AudioUnit lowpassUnit;
    AudioUnit converterUnit;
    
    CheckError(AUGraphNodeInfo(graph, dp, NULL, &dpUnit), "dpUnit");
    CheckError(AUGraphNodeInfo(graph, rio, NULL, &_rioUnit), "rioUnit");
    CheckError(AUGraphNodeInfo(graph, mixer, NULL, &_mixerUnit), "mixerUnit");
    CheckError(AUGraphNodeInfo(graph, lowpass, NULL, &lowpassUnit), "lowpassUnit");
    CheckError(AUGraphNodeInfo(graph, _finalMix, NULL, &_finalMixUnit), "finalMixUnit");
    CheckError(AUGraphNodeInfo(graph, converter, NULL, &converterUnit), "converterUnit");
    CheckError(AUGraphNodeInfo(graph, filePlayer, NULL, &filePlayerUnit), "filePlayerUnit");
    
//    UInt32 on = 1;
//    CheckError(AudioUnitSetProperty(_mixerUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Output, 0, &on, sizeof(UInt32)), "set metering on");
    
    eqUnit = [self configureEQNode:eq  WithHz:209  Db:-6.0  AndQ:0.30];
    [self configureEQNode:eq2 WithHz:541  Db:-12.0 AndQ:0.30];
    [self configureEQNode:eq3 WithHz:1495 Db:-12.0 AndQ:0.30];
    [self configureEQNode:eq4 WithHz:3256 Db:-6.0  AndQ:0.30];
    
    [self configureDynamicsUnit: dpUnit
                  WithThreshold: -100
                       headroom: 30
                 expansionRatio: 50.0
             expansionThreshold: -100
                     attackTime: 0.03
                    releaseTime: 0.0
                        andGain: kMicrophoneGain];
    
    CheckError(AudioUnitSetParameter(lowpassUnit, kLowPassParam_CutoffFrequency, kAudioUnitScope_Global, 0, 20000.0, 0), "cut freq");

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
    
    CheckError(AudioUnitGetProperty(eqUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &effectASBD, &asbdSize),
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
    
    CheckError(AudioUnitSetProperty(converterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &effectASBD, asbdSize), "asbd on converter");
    
    AudioUnit notifierUnit = _finalMixUnit;
    CheckError(AudioUnitAddRenderNotify(notifierUnit, &RecordingCallback, (__bridge void*)self), "render notify");
    CheckError(AudioUnitGetProperty(notifierUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &_notifierASBD, &asbdSize), "notifier ABSD");
    
    CheckError(AudioUnitAddRenderNotify(_mixerUnit, &MicrophoneCallback, (__bridge void*)self), "mic notify");
    
    // microphone chain
    CheckError(AUGraphConnectNodeInput(graph, rio, 1,       mixer, 0),      "plug");
    CheckError(AUGraphConnectNodeInput(graph, mixer, 0,     eq, 0),         "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq, 0,        eq2, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq2, 0,       eq3, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq3, 0,       eq4, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq4, 0,       lowpass, 0),    "plug");
    CheckError(AUGraphConnectNodeInput(graph, lowpass, 0,   dp, 0),         "plug");
    
    // to final mixer
    CheckError(AUGraphConnectNodeInput(graph, dp, 0, _finalMix, 0), "plug");
    CheckError(AUGraphConnectNodeInput(graph, filePlayer, 0, converter, 0), "plug");
    CheckError(AUGraphConnectNodeInput(graph, converter, 0, _finalMix, 1), "plug");
    
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
    
    CheckError(ExtAudioFileWriteAsync(outputFile, 0, NULL), "prime");
    ExtAudioFileSeek(outputFile, 0);
    
    self->recording = YES;
}

- (AudioStreamBasicDescription)getAACFormat
{
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    UInt32 asbdSize = sizeof(asbd);
    
    asbd.mChannelsPerFrame = 2;
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
    _filePlayerCount = 0;
    self->recording = NO;
    
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
