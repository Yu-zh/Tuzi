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
  rmax : Int
  cmax : Int
  mut cx : Int
  mut cy : Int
  rows : Array[Bytes]
  mut filename : Bytes
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
  let rows_len = self.rows.length()
  for y in 0..<(self.rmax - 2) {
    if y < rows_len {
      buffer.write_bytes(self.rows[y])
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
  buffer.write_bytes(cursor_pos(self.cx + 1, self.cy + 1))
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
  Editor::{ rmax: rmax[0], cmax: cmax[0], cx: 0, cy: 0, rows: [], filename: [] }
}

///|
fn read_file(self : Editor, filename : String) -> Unit {
  let contents = try {
    @fs.read_file_to_bytes!(filename)
  } catch {
    e => die(@encoding.encode(UTF8, e.to_string()))
    //e => die(e.to_string().to_bytes())
  }
  for line in @cbytes.lines(contents) {
    self.rows.push([..line])
  }
  self.filename = @encoding.encode(UTF8, filename)
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
