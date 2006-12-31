/*******************************************************************************
	NSXMLElement+elementWithXMLFormat.h
		Copyright (c) 2006 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>

	***************************************************************************/

#import <Foundation/Foundation.h>

@interface NSXMLElement (elementWithXMLFormat)

+ (id)elementWithXMLFormat:(NSString*)format_, ...;
+ (NSError*)elementWithXMLFormatError;

@end
