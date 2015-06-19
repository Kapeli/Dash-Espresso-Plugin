#import "Dash.h"

@interface NSString (DHUtils)

- (NSString *)getWordAtIndex:(NSInteger)index;

@end

@implementation NSString (DHUtils)

// based on http://stackoverflow.com/questions/15391171/extract-word-substring-from-nsstring-at-given-index
- (NSString *)getWordAtIndex:(NSInteger)index
{
    if(index < 0 || index >= self.length)
    {
        return nil;
    }
    
    NSMutableCharacterSet *wordSet = [[[NSMutableCharacterSet alloc] init] autorelease];
    [wordSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    [wordSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];
    NSMutableCharacterSet *wordBreakSet = [[[NSMutableCharacterSet alloc] init] autorelease];
    [wordBreakSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [wordBreakSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@";="]];
    
    NSInteger adjustedIndex = index;
    if(![wordSet characterIsMember:[self characterAtIndex:adjustedIndex]])
    {
        BOOL found = NO;
        NSInteger previous = index;
        while(previous > 0)
        {
            --previous;
            unichar character = [self characterAtIndex:previous];
            if([wordSet characterIsMember:character])
            {
                found = YES;
                adjustedIndex = previous;
                break;
            }
            else if([wordBreakSet characterIsMember:character])
            {
                break;
            }
        }
        NSInteger next = index;
        if(!found && ![wordBreakSet characterIsMember:[self characterAtIndex:index]])
        {
            while(next+1 < self.length)
            {
                ++next;
                unichar character = [self characterAtIndex:next];
                if([wordSet characterIsMember:character])
                {
                    found = YES;
                    adjustedIndex = next;
                    break;
                }
                else if([wordBreakSet characterIsMember:character])
                {
                    break;
                }
            }
        }
        
        if(!found)
        {
            return nil;
        }
    }

    NSInteger beforeBeginning = adjustedIndex;
    while (beforeBeginning >= 0 &&
           [wordSet characterIsMember:
            [self characterAtIndex:beforeBeginning]])
        --beforeBeginning;
    
    NSInteger afterEnd = adjustedIndex;
    while (afterEnd < self.length &&
           [wordSet characterIsMember:
            [self characterAtIndex:afterEnd]])
        ++afterEnd;
    
    NSRange range = NSMakeRange(beforeBeginning + 1,
                                afterEnd - beforeBeginning - 1);
    return [self substringWithRange:range];
}

@end

@implementation Dash

- (BOOL)canPerformActionWithContext:(id)context
{
    return YES;
}

- (BOOL)dashIsInstalled
{
    if(![[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.kapeli.dash"] && ![[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.kapeli.dashdoc"] && ![[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.kapeli.dashbeta"])
    {
        if([[NSAlert alertWithMessageText:@"Dash" defaultButton:@"Download Dash" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Dash is not installed. Please download Dash."] runModal] == NSAlertDefaultReturn)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://kapeli.com/dash"]];
        }
        return NO;
    }
    return YES;
}

- (BOOL)performActionWithContext:(id)context error:(NSError **)outError
{
    @try {
        if([self dashIsInstalled])
        {
            NSArray *ranges = [context selectedRanges];
            if(ranges.count)
            {
                NSRange range = [[ranges objectAtIndex:0] rangeValue];
                NSString *string = [context string];
                if(!string.length)
                {
                    return NO;
                }
                NSString *searchString = nil;
                if(range.length)
                {
                    searchString = [string substringWithRange:range];
                }
                else
                {
                    NSString *word = [string getWordAtIndex:range.location];
                    searchString = word;
                }
                if(!searchString)
                {
                    return NO;
                }
                NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
                [pboard setString:searchString forType:NSStringPboardType];
                NSPerformService(@"Look Up in Dash", pboard);
                return YES;
            }
        }
    }
    @catch(NSException *exception) { }
    return NO;
}

@end
