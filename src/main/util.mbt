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
fn quit() -> Unit {
  output_bytes(CLEAR_SCREEN2)
  output_bytes(RESET_CURSOR)
  exit(0)
}
