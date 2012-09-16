//
//  VLFAudioUtilities.h
//  Ira
//
//  Created by Robert Stenson on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef Ira_VLFAudioUtilities_h
#define Ira_VLFAudioUtilities_h

#import <AudioToolbox/AudioToolbox.h>

static void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr) return;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
    
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
}

static UInt32 audioFileDuration(AudioFileID afid, AudioStreamBasicDescription asbd)
{
    UInt64 dataPacketCount;
    UInt64 totalFrames;
    UInt32 propertySize;
    OSStatus err;
    
    totalFrames = 0;
    propertySize = sizeof(dataPacketCount);
    
    err = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataPacketCount, &propertySize, &dataPacketCount);
    if (err) {
        fprintf(stderr, "AudioFileGetProperty kAudioFilePropertyAudioDataPacketCount failed\n");
    } else {
        if (asbd.mFramesPerPacket)
            totalFrames = asbd.mFramesPerPacket * dataPacketCount;
    }
    
    AudioFilePacketTableInfo pti;
    propertySize = sizeof(pti);
    err = AudioFileGetProperty(afid, kAudioFilePropertyPacketTableInfo, &propertySize, &pti);
    if (err == noErr) {
        totalFrames = pti.mNumberValidFrames;
    }
    
    return (UInt32)totalFrames;
}

static UInt32 playableFramesInURL(CFURLRef url)
{
    AudioFileID recordedFile;
    CheckError(AudioFileOpenURL(url, kAudioFileReadPermission, 0, &recordedFile), "read");
    
    AudioStreamBasicDescription fileASBD;
    UInt32 asbdSize = sizeof(fileASBD);
    CheckError(AudioFileGetProperty(recordedFile, kAudioFilePropertyDataFormat, &asbdSize, &fileASBD), "file format");
    
    return audioFileDuration(recordedFile, fileASBD);
}

#endif
