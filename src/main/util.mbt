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
