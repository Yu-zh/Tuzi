///|
// extern "c" fn hello() = "moonbit_hello"

///|
extern "c" fn enable_raw_mode() = "enable_raw_mode"

///|
extern "c" fn read_key(p : @c.Pointer[Byte]) -> Int = "read_key"

///|
fn load_char(p : @c.Pointer[Byte]) -> Char {
  Char::from_int(p.load().to_int())
}

///|
fn identity[A, B](x : A) -> B = "%identity"

///|
fn main {
  enable_raw_mode()
  // cannot use `Bytes` but it is const
  let arr : FixedArray[Byte] = [0]
  let p = @c.Pointer::of_bytes(identity(arr))
  while true {
    let r = read_key(p)
    guard r == 1 else { break }
    let c = load_char(p)
    println("\{c.to_int()} (\{c})\r")
    if c == 'q' {
      break
    }
  }
}
