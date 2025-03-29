///|
const STDIN_FILENO = 0

///|
const STDOUT_FILENO = 1

///|
// 0: clear from cursor to end of screen/line (default)
// 1: clear from cursor to beginning of screen/line
// 2: clear entire screen/line
const CLEAR_SCREEN : Bytes = "\x1b[2J"

///|
const RESET_CURSOR : Bytes = "\x1b[H"

///|
const HIDE_CURSOR : Bytes = "\x1b[?25l"

///|
const SHOW_CURSOR : Bytes = "\x1b[?25h"

///|
struct Editor {
  screen_rows : Int
  screen_cols : Int
} derive(Default)

///|
fn read_key(p : FixedArray[Byte]) -> Unit {
  let r = read(STDIN_FILENO, p, 1)
  guard r == 1 else { die("read_key") }

}

///|
fn write_bytes(bs : Bytes) -> Unit {
  let len = bs.length()
  guard len == write(STDOUT_FILENO, bs, len) else { die("write") }

}

///|
fn process_key() -> Unit {
  // cannot use `Bytes` but it is const
  let arr : FixedArray[Byte] = [0]
  read_key(arr)
  let c = Char::from_int(arr[0].to_int())
  println("\{c.to_int()} (\{c})\r")
  if c == 'q' {
    exit(0)
  }
}

///|
fn refresh_screen() -> Unit {
  let buffer = @buffer.new(size_hint=256)
  buffer.write_bytes(HIDE_CURSOR)
  buffer.write_bytes(RESET_CURSOR)
  write_bytes(buffer.to_bytes())
}

///|
fn Editor::new() -> Editor {
  let rows : FixedArray[Int] = [0]
  let cols : FixedArray[Int] = [0]
  let r = get_window_size(rows, cols)
  guard r == 0 else { die("get_window_size") }
  println(rows[0])
  println(cols[0])
  Editor::{ screen_rows: rows[0], screen_cols: cols[0] }
}

///|
fn main {
  enable_raw_mode()
  let editor = Editor::new()
  ignore(editor)
  while true {
    refresh_screen()
    process_key()
  }
}

///|
fn _identity[A, B](x : A) -> B = "%identity"
