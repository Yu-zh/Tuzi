///|
const VERSION : Bytes = b"0.0.1"

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
fn cursor_pos(x : Int, y : Int) -> Bytes {
  fn bytes(a : Int) -> Bytes {
    @cbytes.int_to_bytes(a)
  }

  [..b"\x1b[", ..bytes(y), ';', ..bytes(x), 'H', 0]
}

///|
struct Editor {
  // max number of rows on the screen
  rmax : Int
  // max number of columns on the screen
  cmax : Int
  // column number (0 indexed) pointing to the contents instead of the screen
  mut cx : Int
  // row number (0 indexed) pointing to the contents instead of the screen
  mut cy : Int
  // contents to be displayed
  rows : Array[Bytes]
  mut filename : Bytes
  // row offset
  mut roff : Int
}

///|
enum Key {
  Up
  Down
  Right
  Left
  End
  Head
  Quit
  Insert(Byte)
  Backspace
  Newline
  Esc
}

///|
fn move_cursor(self : Editor, key : Key) -> Unit {
  fn adjust_cx() {
    if self.cy < self.rows.length() {
      if self.cx > self.rows[self.cy].length() {
        self.cx = self.rows[self.cy].length()
      }
    } else if self.cy == self.rows.length() {
      self.cx = 0
    } else {
      die("adjust_cx")
    }
  }

  fn move_up() -> Bool {
    guard self.cy > 0 else { return false }
    self.cy -= 1
    // update row offset
    // invariant self.cy >= self.roff
    if self.cy < self.roff {
      self.roff -= 1
    }
    true
  }

  fn move_down() -> Bool {
    guard self.cy < self.rows.length() else { return false }
    self.cy += 1
    // update row offset
    // invariant self.cy - self.roff < self.rmax - 2
    if self.cy + self.roff >= self.rmax - 2 {
      self.roff += 1
    }
    true
  }

  fn move_to_head() {
    self.cx = 0
  }

  fn move_to_end() {
    if self.cy < self.rows.length() {
      self.cx = self.rows[self.cy].length()
    }
  }

  fn move_right() {
    guard self.cy < self.rows.length() else { return }
    if self.cx < self.rows[self.cy].length() {
      // cx can be equal to the self.rows[self.cy].length()
      // it will point to the position after the last character
      self.cx += 1
    } else if self.cx == self.rows[self.cy].length() {
      if move_down() {
        move_to_head()
      }
    } else {
      die("move_right")
    }
  }

  fn move_left() {
    if self.cx > 0 {
      self.cx -= 1
    } else if self.cx == 0 {
      if move_up() {
        move_to_end()
      }
    } else {
      die("move_left")
    }
  }

  match key {
    Left => move_left()
    Right => move_right()
    Up => if move_up() { adjust_cx() }
    Down => if move_down() { adjust_cx() }
    Head => move_to_head()
    End => move_to_end()
    _ => die("move_cursor")
  }
}

///|
fn insert_char(self : Editor, c : Byte) -> Unit {
  if self.cy == self.rows.length() {
    self.rows.push([])
  }
  let row = self.rows[self.cy]
  self.rows[self.cy] = [..row[:self.cx], c, ..row[self.cx:]]
  self.cx += 1
}

///|
fn move_cursor_to(self : Editor, x : Int, y : Int) -> Unit {
  self.cy = y
  self.cx = x
}

///|
fn delete_char(self : Editor) -> Unit {
  if self.cx == 0 {
    if self.cy == 0 {
      return
    }
    let cy = self.cy - 1
    let cx = self.rows[cy].length()
    if self.cy == self.rows.length() {
      // last row does not need to be removed
    } else {
      let row = self.rows.remove(self.cy)
      self.rows[cy] = [..self.rows[cy], ..row]
    }
    self.move_cursor_to(cx, cy)
  } else {
    let row = self.rows[self.cy]
    self.rows[self.cy] = [..row[:self.cx - 1], ..row[self.cx:]]
    self.move_cursor(Left)
  }
}

///|
fn newline(self : Editor) -> Unit {
  if self.cy == self.rows.length() {
    self.rows.push([])
  } else {
    let row = self.rows[self.cy]
    let left = row[:self.cx]
    let right = row[self.cx:]
    self.rows[self.cy] = [..left]
    self.rows.insert(self.cy + 1, [..right])
  }
  self.move_cursor_to(0, self.cy + 1)
}

///|
fn process_key(self : Editor) -> Unit {
  let k = read_key()
  match k {
    Left | Right | Up | Down | End | Head => self.move_cursor(k)
    Quit => quit()
    Backspace => self.delete_char()
    Newline => self.newline()
    Insert(b) => self.insert_char(b)
    Esc => ()
  }
}

///|
fn draw_rows(self : Editor, buffer : @buffer.T) -> Unit {
  let rows_len = self.rows.length()
  for y in 0..<(self.rmax - 2) {
    if y < rows_len {
      buffer.write_bytes(self.rows[y + self.roff])
    } else if rows_len == 0 && y == self.rmax / 3 {
      let welcome = [
          // welcome message
          ..b"Kilo editor -- version ",
          ..VERSION,
        ]
      let padding = (self.cmax - welcome.length()) / 2
      let padding = Bytes::make(padding, b' ')
      buffer.write_bytes([b'~', ..padding, ..welcome])
    } else {
      buffer.write_byte('~')
    }
    buffer.write_bytes(CLEAR_LINE0)
    buffer.write_bytes(b"\r\n")
  }
}

///|
fn draw_status_bar(self : Editor, buffer : @buffer.T) -> Unit {
  buffer.write_bytes(INVERT_COLOR)
  let status_front = if self.filename.length() > 0 {
    self.filename
  } else {
    b"(No file)"
  }
  let status_end = [
      ..@cbytes.int_to_bytes(self.cy + 1),
      b':',
      ..@cbytes.int_to_bytes(self.cx + 1),
    ]
  let padding = Bytes::make(
    self.cmax - status_front.length() - status_end.length(),
    b' ',
  )
  let status : Bytes = [..status_front, ..padding, ..status_end, ..b"\r\n"]
  buffer.write_bytes(status)
  buffer.write_bytes(RESET_COLOR)
}

///|
fn draw_cursor(self : Editor, buffer : @buffer.T) -> Unit {
  buffer.write_bytes(cursor_pos(self.cx + 1, self.cy - self.roff + 1))
}

///|
fn refresh_screen(self : Editor) -> Unit {
  let buffer = @buffer.new(size_hint=256)
  buffer.write_bytes(HIDE_CURSOR)
  buffer.write_bytes(RESET_CURSOR)
  self.draw_rows(buffer)
  self.draw_status_bar(buffer)
  self.draw_cursor(buffer)
  buffer.write_bytes(SHOW_CURSOR)
  output_bytes(buffer.to_bytes())
}

///|
fn Editor::new() -> Editor {
  let rmax : FixedArray[Int] = [0]
  let cmax : FixedArray[Int] = [0]
  let r = get_window_size(rmax, cmax)
  guard r == 0 else { die("get_window_size") }
  Editor::{
    rmax: rmax[0],
    cmax: cmax[0],
    cx: 0,
    cy: 0,
    rows: [],
    filename: [],
    roff: 0,
  }
}

///|
fn main {
  enable_raw_mode()
  let editor = Editor::new()
  let args = @env.args()
  if args.length() > 1 {
    let filename = args[1]
    editor.read_file(filename)
  }
  while true {
    editor.refresh_screen()
    editor.process_key()
  }
}
