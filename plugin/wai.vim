" wai.vim - wai
" Author:   Tobias Pflug
" Version:  0.1
" License:  see :help license

"
" load script
"
if exists('g:loaded_wai') || &cp
    finish
endif
let g:loaded_wai = 1

"
" set up mappings
"
if !exists('g:wai_map_keys')
    let g:wai_map_keys = 1
endif
if g:wai_map_keys
    execute "autocmd FileType html,xml,mustache" "nnoremap <buffer>" "<Leader>w"  ":call WaiXmlPath()<CR>"
    execute "autocmd FileType json" "nnoremap <buffer>" "<Leader>w"  ":call WaiJsonPath()<CR>"
endif


function! WaiJsonPath()
    python <<EOF
def getJsonPath(jsonString):
    if not jsonString or len(jsonString) == 0:
        return '[empty]'
    pos = 0
    depth = 0
    last = '__start__'
    lastIdentifier = ''
    path = []
    jsonLength = len(jsonString)
    while pos < jsonLength:
        current = jsonString[pos]
        if current == '"':
            pos += 1
            startPos = pos
            while pos < jsonLength and jsonString[pos] != '"':
                pos += 1
            identifier = jsonString[startPos:pos]
            if jsonString[pos+1] == ':':
                lastIdentifier = identifier
                pos += 1
            pos += 1
        if current == "{":
            if lastIdentifier:
                path.append(lastIdentifier)
            depth += 1
            pos += 1
            last = '{'
        elif current == '}':
            if depth == 0:
                return '[empty]'
            if len(path) > 1:
                path.pop()
            depth -= 1
            pos += 1
            last = '}'
        else:
            pos += 1
            last = current
    return ".".join(path)
data = '\n'.join(vim.current.buffer[0:int(vim.eval("line('.')"))])
path = getJsonPath(data)
vim.command('echo "' + path + '"')
EOF
endfunction

"
" Parse current buffer from [0:line('.')] and echo
" the path to the element in the current line.
"
" If the element in the current line is opened and
" closed again it is included as last element on
" the path expression.
"
function! WaiXmlPath()
    python << EOF
import xml.sax

# handler to track opening/closing tags
class HtmlContentHandler(xml.sax.ContentHandler):
    def __init__(self):
        xml.sax.ContentHandler.__init__(self)
        self.path = []
        self.lastDiv = ''
        self.lastEvent = ''
        self.skip = False
    def startElement(self, name, attrs):
        if not (name in ('div', 'path') and attrs.has_key('class')):
            self.skip = True
            return
        divClass = attrs.getValue('class');
        self.path.append('.' + divClass)
        self.lastDiv = '.' + divClass;
        self.lastEvent = 'open'
    def endElement(self, name):
        if self.skip:
            self.skip = False
            return
        self.lastEvent = 'close'
        self.path.pop()
    def getPath(self):
        if (len(self.path) == 0):
            return '[empty]'
        p = '>'.join(self.path)
        if self.lastEvent == 'close':
            return p + '>' + self.lastDiv;
        return p;

# error handler to ignore early file end
class HtmlErrorHandler(xml.sax.ErrorHandler):
    def __init__(self):
        pass
    def error(self, exception):
        print "error: %s\n" % exception
    def fatalError(self, exception):
        if exception.getMessage() == 'no element found':
            pass
        else:
            print "fatal: %s\n" % exception.getMessage()


# parse everything up to current line
data = '\n'.join(vim.current.buffer[0:int(vim.eval("line('.')"))])
htmlHandler = HtmlContentHandler()
xml.sax.parseString(data, htmlHandler, HtmlErrorHandler())
divPath = htmlHandler.getPath()
vim.command('echo "' + divPath + '"')
EOF
endfunction
