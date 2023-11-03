type csize = uint
proc `:=`*[T](x: var T, y: T): T =
  ## A assignment expression like convenience operator
  x = y
  x

proc findUO*(s: string, c: char): int {.noSideEffect.} =
  proc memchr(s: pointer, c: char, n: csize): pointer {.importc:"memchr",
                                                        header:"<string.h>".}
  let p = memchr(s.cstring.pointer, c, s.len.csize)
  if p == nil: -1 else: (cast[uint](p) - cast[uint](s.cstring.pointer)).int

proc delete*(x: var string, i: Natural) {.noSideEffect.} =
  ## Just like ``delete(var seq[T], i)`` but for ``string``.
  let xl = x.len
  for j in i.int .. xl-2:
    x[j] = move x[j+1]
  setLen(x, xl-1)

iterator maybePar*(parallel: bool, a, b: int): int =
  ## if flag is true yield ``||(a,b)`` else ``countup(a,b)``.
  if parallel:
    for i in `||`(a, b): yield i
  else:
    for i in a .. b: yield i

import core/macros

proc incd*[T: Ordinal | uint | uint64](x: var T, amt=1): T {.inline.} =
  ##Similar to prefix ``++`` in C languages: increment then yield value
  x.inc amt; x

proc decd*[T: Ordinal | uint | uint64](x: var T, amt=1): T {.inline.} =
  ##Similar to prefix ``--`` in C languages: decrement then yield value
  x.dec amt; x

proc postInc*[T: Ordinal | uint | uint64](x: var T, amt=1): T {.inline.} =
  ##Similar to post-fix ``++`` in C languages: yield initial val, then increment
  result = x; x.inc amt

proc postDec*[T: Ordinal | uint | uint64](x: var T, amt=1): T {.inline.} =
  ##Similar to post-fix ``--`` in C languages: yield initial val, then decrement
  result = x; x.dec amt

proc delItem*[T](x: var seq[T], item: T): int =
  result = find(x, item)
  if result >= 0:
    x.del(Natural(result))

proc seekable*(f: File): bool =
  ## True if Nim `File` is bound to an OS file pointing at a seekable device.
  proc ftell(f: File): int64 {.importc, header: "stdio.h".}
  f.ftell != -1

proc `&`*[T](x: openArray[T], y: openArray[T]): seq[T] =
  ## Allow `[1] & [2]` exprs; `system/` has only `add var seq openArray`.
  result.setLen x.len + y.len
  for i, e in x: result[i] = e
  for i, e in y: result[x.len + i] = e

proc echoQuit130*() {.noconv.} = echo ""; quit 130
  ## Intended for `setControlCHook(echoQuit130)` to achieve quieter exits.

proc newSeqNoInit*[T: Ordinal|SomeFloat](len: Natural): seq[T] =
  ## Make a new `seq[T]` of length `len`, skipping memory clear.
  ## (`newSeqUninitialized` overly constrains `T` to disallow `[bool]`, etc.)
  result = newSeqOfCap[T](len)
  when defined(nimSeqsV2): cast[ptr int](addr result)[] = len
  else: result.setLen len
