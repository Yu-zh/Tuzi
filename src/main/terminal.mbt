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
