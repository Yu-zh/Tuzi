///|
const STDIN_FILENO = 0

///|
const STDOUT_FILENO = 1

///|
// 0: clear from cursor to end of screen/line (default)
// 1: clear from cursor to beginning of screen/line
// 2: clear entire screen/line
const CLEAR_SCREEN2 : Bytes = "\x1b[2J"

///|
const CLEAR_LINE0 : Bytes = "\x1b[K"

///|
const RESET_CURSOR : Bytes = "\x1b[H"

///|
const HIDE_CURSOR : Bytes = "\x1b[?25l"

///|
const SHOW_CURSOR : Bytes = "\x1b[?25h"

///|
// 1: bold
// 4: underline
// 5: blink
// 7: reverse
// 0: reset
const INVERT_COLOR : Bytes = "\x1b[7m"

///|
const RESET_COLOR : Bytes = "\x1b[m"

///|
enum Color {
  Black = 30
  Red = 31
  Green = 32
  Yellow = 33
  Blue = 34
  Magenta = 35
  Cyan = 36
  LightGray = 37
  DarkGray = 90
  LightRed = 91
  LightGreen = 92
  LightYellow = 93
  LightBlue = 94
  LightMagenta = 95
  LightCyan = 96
  White = 97
  Default = 39
}

///|
fn color_to_bytes(color : Color) -> Bytes {
  [..b"\x1b[", ..color.to_int().to_string().to_bytes(), b'm']
}

///|
fn to_int(self : Color) -> Int = "%identity"
