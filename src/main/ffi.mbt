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
extern "c" fn get_window_size(r : FixedArray[Int], c : FixedArray[Int]) -> Int = "get_window_size"
