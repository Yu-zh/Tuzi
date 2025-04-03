///|
fn output_bytes(bs : Bytes) -> Unit {
  let len = bs.length()
  guard len == write(STDOUT_FILENO, bs, len) else { die("write") }

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
      guard read(STDIN_FILENO, p, 1) == 1 && p[0] == '[' else { return Esc }
      guard read(STDIN_FILENO, p, 1) == 1 else { return Esc }
      match p[0] {
        'A' => Up
        'B' => Down
        'C' => Right
        'D' => Left
        _ => Esc
      }
    }
    CTRL_Q => Quit
    CTRL_B => Left
    CTRL_F => Right
    CTRL_N => Down
    CTRL_E => End
    CTRL_A => Head
    CTRL_P => Up
    CTRL_S => Save
    BACKSPACE => Backspace
    NEWLINE => Newline
    _ => Insert(p[0])
  }
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
fn save_file(self : Editor) -> Unit {
  guard not(self.filename is []) else { return }
  let contents = @cbytes.concat(self.rows, sep=b"\n")
  let decoder = @encoding.decoder(UTF8)
  let filename = decoder.decode_lossy(self.filename)
  try {
    @fs.write_bytes_to_file!(filename, contents)
  } catch {
    e => die(@encoding.encode(UTF8, e.to_string()))
  }
  self.dirty = false
}
