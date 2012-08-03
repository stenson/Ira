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

static void CheckError(OSStatus error, const char *operation) {
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

#endif
