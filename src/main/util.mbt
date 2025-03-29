///|
fn die[T](s : Bytes) -> T {
  write_bytes(CLEAR_SCREEN)
  write_bytes(RESET_CURSOR)
  perror([..s, 0])
  exit(1)
  // should be unreachable
  panic()
}
