///|
test "int_to_bytes" {
  assert_eq!(int_to_bytes(123), b"123")
  assert_eq!(int_to_bytes(0), b"0")
}

///|
test "lines" {
  assert_eq!(lines(b"hello\nworld\n").collect(), [b"hello"[:], b"world"[:]])
  assert_eq!(lines(b"hello\nworld\n!").collect(), [
    b"hello"[:],
    b"world"[:],
    b"!"[:],
  ])
  assert_eq!(lines(b"").collect(), [])
  assert_eq!(lines(b"\n").collect(), [b""[:]])
}
