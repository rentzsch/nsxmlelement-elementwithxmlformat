/*******************************************************************************
	NSXMLElement+elementWithXMLFormat.h
		Copyright (c) 2006-2009 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>

	Note: this code uses C99 variable-length automatic arrays.

	***************************************************************************/

#import "NSXMLElement+elementWithXMLFormat.h"

NSString *elementWithXMLFormatErrorKey = @"elementWithXMLFormatError";

static size_t unicharlen(const unichar *it) {
	const unichar *begin = it;
	while(*it){++it;}
	return it - begin;
}

@implementation NSXMLElement (elementWithXMLFormat)

+ (id)elementWithXMLFormat:(NSString*)format_, ... {
	NSParameterAssert(format_);
	NSParameterAssert([format_ length]);
	
	NSError			*error = nil;
					[[[NSThread currentThread] threadDictionary] removeObjectForKey:elementWithXMLFormatErrorKey];
	NSXMLElement	*result = nil;
	
	//	Setup for efficiently walking format_.
	size_t          formatUnicharCount = [format_ length];
    size_t          formatByteCount = formatUnicharCount * sizeof(unichar);
    NSMutableData   *formatBufferData = [NSMutableData dataWithLength:formatByteCount];
	unichar         *formatBuffer = [formatBufferData mutableBytes];
                    [format_ getCharacters:formatBuffer];
	unichar         *formatIt, *formatEnd = formatBuffer + formatUnicharCount;
	
	//	Reduce the format string to just the formatters, with NUL characters in-between them.
	//	Example: @"foo %d bar %@ baz %f" => @"%d\0%@\0%f\0".
	//	We'll use these NUL characters later as formatted output element delimiters.
    size_t      delimitedFormatBufferUnicharCount = formatUnicharCount * 2; // Handles worst case where format string is nothing but formatters.
	unichar		delimitedFormatBuffer[delimitedFormatBufferUnicharCount];
	unichar		*delimitedFormatIt = delimitedFormatBuffer;
	unichar		*delimitedFormatEnd = delimitedFormatBuffer + (delimitedFormatBufferUnicharCount);
	for (formatIt = formatBuffer; formatIt != formatEnd; formatIt++) {
		assert(delimitedFormatIt != delimitedFormatEnd);
		if (('%' == *formatIt) && ((formatIt+1) != formatEnd)) {
			if ('%' != *(formatIt+1)) {
				*delimitedFormatIt++ = '%';
				*delimitedFormatIt++ = *(formatIt + 1);
				*delimitedFormatIt++ = 0;
			}
			formatIt++;
		}
	}
	size_t	delimitedFormatLength = delimitedFormatIt - delimitedFormatBuffer;
	
	if (!delimitedFormatLength) {
		//	No formatters found: it's just a literal. Short-circuit, parse and return.
		result = [[[NSXMLElement alloc] initWithXMLString:format_ error:&error] autorelease];
		if (error)
			[[[NSThread currentThread] threadDictionary] setObject:error forKey:elementWithXMLFormatErrorKey];
		return result;
	}
	
	NSString *delimitedFormat = (id)CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault,
																	   delimitedFormatBuffer,
																	   delimitedFormatLength,
																	   kCFAllocatorNull);
	
	//	Have the system do the heavy lifting of parsing the format string and converting it into a string.
	va_list args;
	va_start(args, format_);
	NSString *formattedString = [[NSString alloc] initWithFormat:delimitedFormat arguments:args];
	va_end(args);
	
	[delimitedFormat release];
	
	size_t          formattedStringUnicharCount = [formattedString length];
    size_t          formattedStringByteCount = formattedStringUnicharCount * sizeof(unichar);
    NSMutableData   *formattedBufferData = [NSMutableData dataWithLength:formattedStringByteCount];
	unichar         *formattedBuffer = [formattedBufferData mutableBytes];
                    [formattedString getCharacters:formattedBuffer]; [formattedString release];
	unichar         *formattedIt = formattedBuffer, *formattedEnd = formattedBuffer + formattedStringUnicharCount;
    
    NSMutableString *resultString = [[NSMutableString alloc] initWithCapacity:formatUnicharCount + formattedStringUnicharCount];
	
	for (formatIt = formatBuffer; formatIt != formatEnd; formatIt++) {
		if (('%' == *formatIt) && ((formatIt+1) != formatEnd)) {
			if ('%' == *(formatIt+1)) {
                [resultString appendString:@"%"];
			} else {
				assert(formattedIt != formattedEnd);
				size_t formattedStrLen = unicharlen(formattedIt);
				NSString *formattedStr = (id)CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault,
																				formattedIt,
																				formattedStrLen,
																				kCFAllocatorNull);
				NSAssert(formattedStr, @"CFStringCreateWithCharactersNoCopy failed");

				if ('%' == [resultString characterAtIndex:[resultString length]-1]) {
                    // Found a "%%%@": remove the "%" we've already written and write out the string without XML escaping.
                    [resultString deleteCharactersInRange:NSMakeRange([resultString length]-1, 1)];
                    [resultString appendString:formattedStr];
				} else {
					NSString *escapedStr = (id)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault,
																				   (CFStringRef)formattedStr,
																				   NULL);
					NSAssert(escapedStr, @"CFXMLCreateStringByEscapingEntities failed");
                    [resultString appendString:escapedStr];
					[escapedStr release];
				}
				formattedIt += formattedStrLen + 1;
				[formattedStr release];
			}
			formatIt++;
		} else {
            [resultString appendFormat:@"%C", *formatIt];
		}
	}
    
	//NSLog(@"resultString:%@", resultString);
	result = [[[NSXMLElement alloc] initWithXMLString:resultString error:&error] autorelease];
	[resultString release];
	
	if (error)
		[[[NSThread currentThread] threadDictionary] setObject:error forKey:elementWithXMLFormatErrorKey];

    // For GC. See:
    // http://lists.apple.com/archives/cocoa-dev/2008/Jun/msg00619.html
    [formatBufferData self];
    [formattedBufferData self];
    
	return result;
}

+ (NSError*)elementWithXMLFormatError {
	return [[[NSThread currentThread] threadDictionary] objectForKey:elementWithXMLFormatErrorKey];
}

@end
