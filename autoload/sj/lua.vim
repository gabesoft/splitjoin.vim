function! sj#lua#SplitFunction()
  let function_pattern = '\(\<function\>.\{-}(.\{-})\)\(.*\)\<end\>'
  let line             = getline('.')

  if line !~ function_pattern
    return 0
  else
    let head = sj#ExtractRx(line, function_pattern, '\1')
    let body = sj#Trim(sj#ExtractRx(line, function_pattern, '\2'))

    if sj#BlankString(body)
      let body = ''
    else
      let body = substitute(body, "; ", "\n", "").'\n'
    endif

    let replacement = head."\n".body."end"
    let new_line    = substitute(line, function_pattern, replacement, '')

    call sj#ReplaceMotion('V', new_line)

    return 1
  endif
endfunction

function! sj#lua#JoinFunction()
  normal! 0
  if search('\<function\>', 'cW', line('.')) < 0
    return 0
  endif

  let function_lineno = line('.')
  if searchpair('\<function\>', '', '^\s*\<end\>', 'W') <= 0
    return 0
  endif
  let end_lineno = line('.')

  let function_line = getline(function_lineno)
  let end_line      = sj#Trim(getline(end_lineno))

  if end_lineno - function_lineno > 1
    let body_lines = sj#GetLines(function_lineno + 1, end_lineno - 1)
    let body_lines = sj#TrimList(body_lines)
    let body       = join(body_lines, '; ')
    let body       = ' '.body.' '
  else
    let body = ' '
  endif

  let replacement = function_line.body.end_line
  call sj#ReplaceLines(function_lineno, end_lineno, replacement)

  return 1
endfunction

function! sj#lua#SplitTable()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let parser = sj#argparser#js#Construct(from + 1, to -1, getline('.'))
    call parser.Process()
    let pairs = filter(parser.args, 'v:val !~ "^\s*$"')
    let body  = "{\n".join(pairs, ",\n").",\n}"
    call sj#ReplaceMotion('Va{', body)

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'lua_table')
    endif

    return 1
  endif
endf

" This doesn't take anonymous functions into account that have more than one
" line to them. Perhaps the argparser can be extended to recognize these and
" allow proper split\join functionality on them.
function! sj#lua#JoinTable()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = sj#TrimList(split(body, "\n"))

    if g:splitjoin_normalize_whitespace
      let lines = map(lines, "substitute(v:val, '\\s\\+=\\s\\+', ' = ', 'g')")
    endif

    let body = substitute(join(lines, ' '), ',\s*$', '', '')

    call sj#ReplaceMotion('Va{', '{ '.body.' }')

    return 1
  else
    return 0
  end
endf
