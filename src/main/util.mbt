///|
fn die[T](s : Bytes) -> T {
  output_bytes(CLEAR_SCREEN2)
  output_bytes(RESET_CURSOR)
  perror([..s, 0])
  exit(1)
  // should be unreachable
  panic()
}

///|
fn output_bytes(bs : Bytes) -> Unit {
  let len = bs.length()
  guard len == write(STDOUT_FILENO, bs, len) else { die("write") }

}

///|
fn int_to_bytes(a : Int) -> Bytes {
  if a == 0 {
    return "0"
  }
  let buf = @buffer.new()
  fn go(i : Int) {
    let r = i / 10
    if r != 0 {
      go(r)
    }
    buf.write_byte((i % 10).to_byte() + b'0')
  }

  go(a)
  buf.to_bytes()
}
