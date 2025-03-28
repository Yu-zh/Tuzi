///|
// extern "c" fn hello() = "moonbit_hello"

///|
extern "c" fn enable_raw_mode() = "enable_raw_mode"

///|
extern "c" fn read(fd : Int, p : FixedArray[Byte], len : Int) -> Int = "read"

///|
extern "c" fn write(fd : Int, p : Bytes, len : Int) -> Int = "write"

///|
extern "c" fn perror(s : Bytes) = "perror"

///|
extern "c" fn exit(n : Int) = "exit"

///|
const STDIN_FILENO = 0

///|
const STDOUT_FILENO = 1

///|
fn die(s : Bytes) -> Unit {
  // clear the screen
  write_bytes("\x1b[2J")
  // reset cursor to the top left
  write_bytes("\x1b[H")
  perror([..s, 0])
  exit(1)
}

///|
fn read_key(p : FixedArray[Byte]) -> Int {
  read(STDIN_FILENO, p, 1)
}

///|
fn write_bytes(bs : Bytes) -> Unit {
  let len = bs.length()
  guard len == write(STDOUT_FILENO, bs, len) else { die("write") }

}

///|
fn main {
  enable_raw_mode()
  // clear the screen
  write_bytes("\x1b[2J")
  // cannot use `Bytes` but it is const
  let arr : FixedArray[Byte] = [0]
  while true {
    let r = read_key(arr)
    guard r == 1 else { die("read_key") }
    let c = Char::from_int(arr[0].to_int())
    println("\{c.to_int()} (\{c})\r")
    if c == 'q' {
      break
    }
  }
}

///|
fn _identity[A, B](x : A) -> B = "%identity"
