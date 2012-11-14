//
//  main.m
//  Brainfuckery
//
//  Created by Sidney Just
//  Copyright (c) 2012 by Sidney Just
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
//  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "BFInterpreter.h"
#import "BFExtendedInterpreter.h"

static NSString *helloWorldScript = @"++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.+++.";

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        
        BFExtendedInterpreterType type = kBFExtendedInterpreterDialectClassic;
        NSString *script = helloWorldScript;
        
        if(argc >= 2)
        {
            for(int i=1; i<argc; i++)
            {
                if(strcmp(argv[i], "-x") == 0)
                {
                    type = kBFExtendedInterpreterDialectTypeI;
                }
                else if(strcmp(argv[i], "-x2") == 0)
                {
                    type = kBFExtendedInterpreterDialectTypeII;
                }
                else
                {
                    NSError *error;
                    NSString *path = [[NSString stringWithUTF8String:argv[i]] stringByExpandingTildeInPath];
                    
                    script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                    
                    if(!script)
                    {
                        NSLog(@"Could not load file %@, error: %@", path, error);
                        return -1;
                    }
                }
            }
        }
        
        BFInterpreter *interpreter = [[BFExtendedInterpreter alloc] initWithScript:script andDialect:type];
        [interpreter setNeedsInput:^() {
            return (char)getchar();
        }];
        
        [interpreter execute];
        [interpreter release];
        
    }
    
    return 0;
}

