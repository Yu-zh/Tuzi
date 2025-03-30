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
      guard read(STDIN_FILENO, p, 1) == 1 && p[0] == '[' else {
        return Other(ESC)
      }
      guard read(STDIN_FILENO, p, 1) == 1 else { return Other(ESC) }
      match p[0] {
        'A' => Up
        'B' => Down
        'C' => Right
        'D' => Left
        _ => Other(ESC)
      }
    }
    CTRL_Q => Quit
    CTRL_B => Left
    CTRL_F => Right
    CTRL_N => Down
    CTRL_E => End
    CTRL_A => Head
    CTRL_P => Up
    _ => Other(p[0])
  }
}
