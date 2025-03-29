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
fn cursor_pos(x : Int, y : Int) -> Bytes {
  fn bytes(a : Int) -> Bytes {
    int_to_bytes(a)
  }

  [..b"\x1b[", ..bytes(y), ';', ..bytes(x), 'H', 0]
}

///|
struct Editor {
  rmax : Int
  cmax : Int
  mut cx : Int
  mut cy : Int
} derive(Default)

///|
enum Key {
  Up
  Down
  Right
  Left
  Quit
  Normal(Byte)
}

///|
fn read_key() -> Key {
  // cannot use `Bytes` because it is const
  let p : FixedArray[Byte] = [0]
  let mut r = 0
  while r != 1 {
    r = read(STDIN_FILENO, p, 1)
    if r == -1 {
      die("read")
    }
  }
  match p[0] {
    ESC => {
      guard read(STDIN_FILENO, p, 1) == 1 && p[0] == '[' else {
        return Normal(ESC)
      }
      guard read(STDIN_FILENO, p, 1) == 1 else { return Normal(ESC) }
      match p[0] {
        'A' => Up
        'B' => Down
        'C' => Right
        'D' => Left
        _ => Normal(ESC)
      }
    }
    CTRL_Q => Quit
    CTRL_B => Left
    CTRL_F => Right
    CTRL_N => Down
    CTRL_P => Up
    _ => Normal(p[0])
  }
}

///|
fn move_cursor(self : Editor, key : Key) -> Unit {
  match key {
    Left => if self.cx != 0 { self.cx -= 1 }
    Right => if self.cx != self.cmax { self.cx += 1 }
    Up => if self.cy != 0 { self.cy -= 1 }
    Down => if self.cy != self.rmax { self.cy += 1 }
    _ => abort("impossible")
  }
}

///|
fn quit() -> Unit {
  output_bytes(CLEAR_SCREEN2)
  output_bytes(RESET_CURSOR)
  exit(0)
}

///|
fn process_key(self : Editor) -> Unit {
  let k = read_key()
  match k {
    Left | Right | Up | Down => self.move_cursor(k)
    Quit => quit()
    Normal(_) => ()
  }
}

///|
fn draw_rows(self : Editor, buffer : @buffer.T) -> Unit {
  for y in 0..<(self.rmax - 1) {
    if y == self.rmax / 3 {
      // welcome message
      let welcome = [..b"Kilo editor -- version ", ..VERSION]
      let padding = (self.cmax - welcome.length()) / 2
      let padding = Bytes::make(padding, b' ')
      buffer.write_bytes([b'~', ..padding, ..welcome])
    } else {
      buffer.write_byte('~')
    }
    buffer.write_bytes(CLEAR_LINE0)
    buffer.write_bytes(b"\r\n")
  }
  // todo status line
  buffer.write_byte('~')
  buffer.write_bytes(CLEAR_LINE0)
}

///|
fn draw_cursor(self : Editor, buffer : @buffer.T) -> Unit {
  buffer.write_bytes(cursor_pos(self.cx + 1, self.cy + 1))
}

///|
fn refresh_screen(self : Editor) -> Unit {
  let buffer = @buffer.new(size_hint=256)
  buffer.write_bytes(HIDE_CURSOR)
  buffer.write_bytes(RESET_CURSOR)
  self.draw_rows(buffer)
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
  Editor::{ rmax: rmax[0], cmax: cmax[0], cx: 0, cy: 0 }
}

///|
fn main {
  enable_raw_mode()
  let editor = Editor::new()
  while true {
    editor.refresh_screen()
    editor.process_key()
  }
}

///|
fn _identity[A, B](x : A) -> B = "%identity"
