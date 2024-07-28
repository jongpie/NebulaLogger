//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/*
The code below is originally from the project stacktrace.js - also released under the MIT License.
It provides with cross-browser stack trace parsing, which is utilizied internally by Nebula Logger
to automatically track the source compontent that is logging. The original JavaScript code has been modified
to be used for Nebula Logger, but credit goes to the contributors of stacktrace.js for the original implementation.

    - The stacktrace.js project's LICENSE file has been copied below. For full license details, visit:
      https://github.com/stacktracejs/stacktrace.js
    - To see the original code that was copied, visit:
      https://github.com/stacktracejs/stacktrace.js/blob/710bba1118d396466ee342a30b3dfd19ecbda8b5/dist/stacktrace.js#L14C9-L202C7

Some of the changes made below for Nebula Logger's usage includes:
- converting the function ErrorStackParser(StackFrame) into a class
- converting var variables to const & let
- removal of the StackFrame class originally returned, and replaced with an Object
- updated some parsing logic to reflect the current structure of some JavaScript stack traces for Aura & LWC
- updated some parsing logic to align with what data will be stored in Nebula Logger

*/

/*
Copyright (c) 2017 Eric Wendelin and other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
const FIREFOX_SAFARI_STACK_REGEXP = /(^|@)\S+:\d+/;
const CHROME_IE_STACK_REGEXP = /^\s*at .*(\S+:\d+|\(native\))/m;
const SAFARI_NATIVE_CODE_REGEXP = /^(eval@)?(\[native code])?$/;

export class ErrorStackParser {
    parse(error) {
        let stackTraceParticles;
        if (typeof error.stacktrace !== 'undefined' || typeof error['opera#sourceloc'] !== 'undefined') {
            stackTraceParticles = this.parseOpera(error);
        } else if (error.stack && error.stack.match(CHROME_IE_STACK_REGEXP)) {
            stackTraceParticles = this.parseV8OrIE(error);
        } else if (error.stack) {
            stackTraceParticles = this.parseFFOrSafari(error);
        } else {
            throw new Error('Cannot parse given Error object');
        }

        return stackTraceParticles;
    }

    // Separate line and column numbers from a string of the form: (URI:Line:Column)
    extractLocation(urlLike) {
        // Fail-fast but return locations like "(native)"
        if (urlLike.indexOf(':') === -1) {
            return [urlLike];
        }

        const regExp = /(.+?)(?::(\d+))?(?::(\d+))?$/;
        const parts = regExp.exec(urlLike.replace(/[()]/g, ''));
        return [parts[1], parts[2] || undefined, parts[3] || undefined];
    }

    parseV8OrIE(error) {
        const filtered = error.stack.split('\n').filter(function (line) {
            return !!line.match(CHROME_IE_STACK_REGEXP);
        }, this);

        return filtered.map(function (line) {
            if (line.indexOf('(eval ') > -1) {
                // Throw away eval information until we implement stacktrace.js/stackframe#8
                line = line.replace(/eval code/g, 'eval').replace(/(\(eval at [^()]*)|(\),.*$)/g, '');
            }
            let sanitizedLine = line.replace(/^\s+/, '').replace(/\(eval code/g, '(');

            // capture and preseve the parenthesized location "(/foo/my bar.js:12:87)" in
            // case it has spaces in it, as the string is split on \s+ later on
            const location = sanitizedLine.match(/ (\((.+):(\d+):(\d+)\)$)/);

            // remove the parenthesized location from the line, if it was matched
            sanitizedLine = location ? sanitizedLine.replace(location[0], '') : sanitizedLine;

            const tokens = sanitizedLine.split(/\s+/).slice(1);
            // if a location was matched, pass it to extractLocation() otherwise pop the last token
            const locationParts = this.extractLocation(location ? location[1] : tokens.pop());
            const proxyPrefix = 'Proxy.';
            let functionName = tokens.join(' ') || undefined;
            if (functionName?.startsWith('Proxy.')) {
                functionName = functionName.substring(functionName.indexOf(proxyPrefix) + proxyPrefix.length);
            }
            const fileName = ['eval', '<anonymous>'].indexOf(locationParts[0]) > -1 ? undefined : locationParts[0];

            return {
                functionName: functionName,
                fileName: fileName,
                lineNumber: locationParts[1],
                columnNumber: locationParts[2],
                source: line
            };
        }, this);
    }

    parseFFOrSafari(error) {
        const filtered = error.stack.split('\n').filter(function (line) {
            return !line.match(SAFARI_NATIVE_CODE_REGEXP);
        }, this);

        return filtered.map(function (line) {
            // Throw away eval information until we implement stacktrace.js/stackframe#8
            if (line.indexOf(' > eval') > -1) {
                line = line.replace(/ line (\d+)(?: > eval line \d+)* > eval:\d+:\d+/g, ':$1');
            }

            if (line.indexOf('@') === -1 && line.indexOf(':') === -1) {
                // Safari eval frames only have function names and nothing else
                return {
                    functionName: line
                };
            } 
                const functionNameRegex = /((.*".+"[^@]*)?[^@]*)(?:@)/;
                const matches = line.match(functionNameRegex);
                const functionName = matches && matches[1] ? matches[1] : undefined;
                const locationParts = this.extractLocation(line.replace(functionNameRegex, ''));

                return {
                    functionName: functionName,
                    fileName: locationParts[0],
                    lineNumber: locationParts[1],
                    columnNumber: locationParts[2],
                    source: line
                };
            
        }, this);
    }

    parseOpera(e) {
        if (!e.stacktrace || (e.message.indexOf('\n') > -1 && e.message.split('\n').length > e.stacktrace.split('\n').length)) {
            return this.parseOpera9(e);
        } else if (!e.stack) {
            return this.parseOpera10(e);
        } 
            return this.parseOpera11(e);
        
    }

    parseOpera9(e) {
        const lineRE = /Line (\d+).*script (?:in )?(\S+)/i;
        const lines = e.message.split('\n');
        const result = [];

        for (let i = 2, len = lines.length; i < len; i += 2) {
            const match = lineRE.exec(lines[i]);
            if (match) {
                result.push({
                    fileName: match[2],
                    lineNumber: match[1],
                    source: lines[i]
                });
            }
        }

        return result;
    }

    parseOpera10(e) {
        const lineRE = /Line (\d+).*script (?:in )?(\S+)(?:: In function (\S+))?$/i;
        const lines = e.stacktrace.split('\n');
        const result = [];

        for (let i = 0, len = lines.length; i < len; i += 2) {
            const match = lineRE.exec(lines[i]);
            if (match) {
                result.push({
                    functionName: match[3] || undefined,
                    fileName: match[2],
                    lineNumber: match[1],
                    source: lines[i]
                });
            }
        }

        return result;
    }

    // Opera 10.65+ Error.stack very similar to FF/Safari
    parseOpera11(error) {
        const filtered = error.stack.split('\n').filter(function (line) {
            return !!line.match(FIREFOX_SAFARI_STACK_REGEXP) && !line.match(/^Error created at/);
        }, this);

        return filtered.map(function (line) {
            const tokens = line.split('@');
            const locationParts = this.extractLocation(tokens.pop());
            const functionCall = tokens.shift() || '';
            const functionName = functionCall.replace(/<anonymous function(: (\w+))?>/, '$2').replace(/\([^)]*\)/g, '') || undefined;
            let argsRaw;
            if (functionCall.match(/\(([^)]*)\)/)) {
                argsRaw = functionCall.replace(/^[^(]+\(([^)]*)\)$/, '$1');
            }
            const args = argsRaw === undefined || argsRaw === '[arguments not available]' ? undefined : argsRaw.split(',');

            return {
                functionName: functionName,
                args: args,
                fileName: locationParts[0],
                lineNumber: locationParts[1],
                columnNumber: locationParts[2],
                source: line
            };
        }, this);
    }
}
/* End of code originally copied from stacktrace.js */
