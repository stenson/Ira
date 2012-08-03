//
//  VLFAudioGraph.m
//  Ira
//
//  Created by Rob Stenson on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VLFAudioGraph.h"

@interface VLFAudioGraph () {
    AUGraph graph;
    AudioUnit eqUnit;
    ExtAudioFileRef outputFile;
    AudioStreamBasicDescription outputASBD;
    BOOL recording;
}
@end

@implementation VLFAudioGraph

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
    
    CheckError(AUGraphOpen(graph), "open graph");
    
    AudioUnit rioUnit;
    AudioUnit mixerUnit;
    AudioUnit lowpassUnit;
    AudioUnit dpUnit;
    
    CheckError(AUGraphNodeInfo(graph, rio, NULL, &rioUnit), "rioUnit");
    CheckError(AUGraphNodeInfo(graph, mixer, NULL, &mixerUnit), "mixerUnit");
    CheckError(AUGraphNodeInfo(graph, lowpass, NULL, &lowpassUnit), "lowpassUnit");
    CheckError(AUGraphNodeInfo(graph, dp, NULL, &dpUnit), "dpUnit");
    
    eqUnit = [self configureEQNode:eq  WithHz:209  Db:-6.0  AndQ:0.30];
    [self configureEQNode:eq2 WithHz:541  Db:-12.0 AndQ:0.30];
    [self configureEQNode:eq3 WithHz:1495 Db:-12.0 AndQ:0.30];
    [self configureEQNode:eq4 WithHz:3256 Db:-6.0  AndQ:0.30];
    
    [self configureDynamicsUnit:dpUnit
                  WithThreshold:-100
                       headroom:30
                 expansionRatio:50.0
             expansionThreshold:-100
                     attackTime:0.03
                    releaseTime:0.0
                        andGain:30];
    
    CheckError(AudioUnitSetParameter(lowpassUnit, kLowPassParam_CutoffFrequency, kAudioUnitScope_Global, 0, 20000.0, 0), "cut freq");

    UInt32 oneFlag = 1;
	AudioUnitElement bus0 = 0;
	CheckError(AudioUnitSetProperty(rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, bus0, &oneFlag, sizeof(oneFlag)),
			   "Couldn't enable RIO output");
	
	AudioUnitElement bus1 = 1;
	CheckError(AudioUnitSetProperty(rioUnit,
									kAudioOutputUnitProperty_EnableIO,
									kAudioUnitScope_Input,
									bus1,
									&oneFlag,
									sizeof(oneFlag)),
			   "Couldn't enable RIO input");
    
    AudioStreamBasicDescription effectASBD;
    UInt32 asbdSize = sizeof(effectASBD);
    memset(&effectASBD, 0, asbdSize);
    
    CheckError(AudioUnitGetProperty(eqUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &effectASBD,
                                    &asbdSize),
               "get the effect asbd");
    
    Float64 hardwareSampleRate;
	UInt32 propSize = sizeof (hardwareSampleRate);
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
									   &propSize,
									   &hardwareSampleRate),
			   "Couldn't get hardwareSampleRate");
    
    NSLog(@"hardware sample rate %f", hardwareSampleRate);
    NSLog(@"current effect sample rate %f", effectASBD.mSampleRate);
    
    effectASBD.mSampleRate = hardwareSampleRate;
    
    // set kAudioUnitProperty_StreamFormat on input & output of eqUnit with updated sample rate (is it always 44100?)

    CheckError(AudioUnitSetProperty(mixerUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &effectASBD,
                                    asbdSize),
               "set asbd on mixer output");

    self->outputASBD = effectASBD;
    
    AudioUnitAddRenderNotify(dpUnit, &RecordingCallback, (__bridge void*)self);
    
    CheckError(AUGraphConnectNodeInput(graph, rio, 1,       mixer, 0),      "plug");
    CheckError(AUGraphConnectNodeInput(graph, mixer, 0,     eq, 0),         "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq, 0,        eq2, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq2, 0,       eq3, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq3, 0,       eq4, 0),        "plug");
    CheckError(AUGraphConnectNodeInput(graph, eq4, 0,       lowpass, 0),    "plug");
    CheckError(AUGraphConnectNodeInput(graph, lowpass, 0,   dp, 0),         "plug");
    CheckError(AUGraphConnectNodeInput(graph, dp, 0,        rio, 0),        "plug");
    
    [self enableGraph];
}

- (void)toggleRecording
{
    if (self->recording) {
        [self stopRecording];
    } else {
        [self startRecording];
    }
}

- (void)stopRecording
{
    self->recording = NO;
    CheckError(ExtAudioFileDispose(outputFile), "dispose");
}

- (void)startRecording
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/voice.m4a", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (__bridge CFStringRef)destinationFilePath, 
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    UInt32 asbdSize = sizeof(asbd);
    
    asbd.mChannelsPerFrame = 2;
    asbd.mFormatID = kAudioFormatMPEG4AAC_LD;
    //asbd.mFormatFlags = kMPEG4Object_HVXC;
    
    CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &asbdSize, &asbd),
               "complete asbd for aac");
    
    CheckError(ExtAudioFileCreateWithURL(destinationURL,
                                         kAudioFileM4AType,
                                         &asbd,
                                         NULL,
                                         kAudioFileFlags_EraseFile,
                                         &outputFile),
               "create ext audio output file");
    
    CheckError(ExtAudioFileSetProperty(outputFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       asbdSize,
                                       &self->outputASBD),
               "create file for format");
    
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    UInt32 codecSize = sizeof(codec);
    CheckError(ExtAudioFileSetProperty(outputFile, kExtAudioFileProperty_CodecManufacturer, codecSize, &codec),
               "set codec");
    
    CheckError(ExtAudioFileWriteAsync(outputFile, 0, NULL), "prime");
    ExtAudioFileSeek(outputFile, 0);
    
    self->recording = YES;
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
    CheckError(AUGraphInitialize(graph), "initialize graph");
    CheckError(AudioSessionSetActive(true), "active");
    CheckError(AUGraphStart(graph), "start");
    return YES;
}

- (BOOL)disableGraph
{
    NSLog(@"stopping");

    CheckError(AUGraphStop(graph), "stop");
    CheckError(AudioSessionSetActive(false), "inactive");
    CheckError(AUGraphUninitialize(graph), "uninitialize");
    return YES;
}

- (BOOL)setupAudioSession
{
    self->recording = NO;
    
    CheckError(AudioSessionInitialize(NULL,
                                      kCFRunLoopDefaultMode,
                                      InterruptionListener,
                                      (__bridge void *)self),
               "couldn't initialize audio session");
    
	UInt32 category = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                       sizeof(category),
                                       &category),
               "Couldn't set category on audio session");
    
	UInt32 ui32PropertySize = sizeof (UInt32);
	UInt32 inputAvailable;
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,
                                       &ui32PropertySize,
                                       &inputAvailable),
			   "Couldn't get current audio input available prop");
    
    float aBufferLength = 0.005; // In seconds
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
                            sizeof(aBufferLength), &aBufferLength);
    
	if (!inputAvailable) {
		[self notifyNoInputAvailable];
        return NO;
	} else {
        [self setupGraph];
        return YES;
    }
}

@end
