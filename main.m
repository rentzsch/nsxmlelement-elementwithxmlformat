#import "NSXMLElement+elementWithXMLFormat.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	//[NSXMLElement elementWithXMLFormat:nil];
	NSLog(@"element: %@", [NSXMLElement elementWithXMLFormat:@"<t a=\"%%\">%s%d|%d</t>", "<", 9876, 8765]);
	if ([NSXMLElement elementWithXMLFormatError])
		NSLog(@"error: %@", [NSXMLElement elementWithXMLFormatError]);
	
    [pool release];
    return 0;
}
