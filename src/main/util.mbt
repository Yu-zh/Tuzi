///|
fn die[T](s : Bytes) -> T {
  @termbit.execute(@termbit.Terminal::Clear(All))
  @termbit.execute(@termbit.Cursor::MoveTo(0, 0))
  perror([..s, 0])
  exit(1)
  // should be unreachable
  panic()
}

///|
fn quit() -> Unit {
  @termbit.execute(@termbit.Terminal::Clear(All))
  @termbit.execute(@termbit.Cursor::MoveTo(0, 0))
  exit(0)
}
