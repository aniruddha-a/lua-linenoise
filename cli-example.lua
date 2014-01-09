-- An full command line example 
--local S = require 'serpent'
local L = require 'linenoise'

gt  = {} -- The global table to hold all CLIs
gfn = {} -- The global table to map CLI to a function

function trim(s) 
  local n = s:find("%S")
  return n and s:match(".*%S", n) or ""
end

function dumpall(t, s)
    if next(t) == nil then print('',s) end
    for k,v in pairs(t) do 
        dumpall(v, s .. ' ' .. k)
    end
end

-- on '?' at the end of command 
function dumpcompletions (s)
    print("Possible completions:")
    local t   = gt
    local ret = ''
    for w in s:gmatch("%S+") do 
        local n, m = nmatches(t, w)
        if n == 1 then 
            t = t[m]
            ret = ret .. m .. ' '
        else 
            break
        end
    end
    dumpall(t, ret)
end

-- Check how many matches were there for the given word/prefix
-- at this level
function nmatches(t, w)
    local n = 0
    local lastmatch
    for k,v in pairs(t) do 
        if k:match('^' .. w) then
            n = n + 1
            lastmatch = k
        end
    end
    return n, lastmatch
end

function dumpmatches(t, w)
    local allopts = ' '
    for k,v in pairs(t) do 
        if k:match(w) then
            allopts = allopts .. k .. ' | '
        end
    end
    print('\n', allopts)
end

L.setcompletion(function(c,s)
    local t   = gt
    local ret = ''
    for w in s:gmatch("%S+") do -- foreach CLI word
        local n, m = nmatches(t, w)
        if n == 1 then 
            t = t[m]
            ret = ret .. m .. ' '
        elseif n == 0 then
            print ("\n^ Unknown\n")
        else 
            dumpmatches(t,w)
            ret = ret .. w
        end
    end
    L.addcompletion(c, ret)
end)

--------------- TEST------------
-- Split and add the string as a CLI to the global table gt
function addtocli (str, fn) 
    local t = gt
    for w in str:gmatch("%S+") do -- foreach word
        --    print(w) 
        if t[w] == nil then 
            t[w] = {}
        end
        t = t[w]
    end
    gfn[str] = fn
end

function fn1(s) print ('\n\tIn handler for [ ' .. s .. ' ]\n') end
function exit(s) os.exit() end
function help(s) 
    print [[

    '?'              at any point in the CLI for help
    'exit'|'quit'    to exit
    ]]
end

-- Test commands 
addtocli("hello line noise", fn1)
addtocli("this is a test", fn1)
addtocli("this too is test", fn1)
addtocli("exit", exit)
addtocli("quit", exit)
addtocli("help", help)

-- Dump our CLI table using serpent
-- print(S.block(gt))

local prompt = "lncli> "
local line = L.linenoise(prompt)
while line do 
    line = trim(line)
    local n = #line
    if n > 0 then 
        if line:sub(n,n) == '?' then 
            dumpcompletions(line:sub(1, n-1))
        else 
            local f = gfn[line] 
            if f then f(line) else print 'Invalid/Incomplete command' end
            L.historyadd(line)
        end
    end
    line = L.linenoise(prompt)
end
