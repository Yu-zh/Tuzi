///|
pub fn int_to_bytes(a : Int) -> Bytes {
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

///|
pub fn lines(s : Bytes) -> Iter[@bytes.View] {
  let mut i = 0
  let mut j = 0
  let len = s.length()
  Iter::new(fn(yield_) {
    while j < len {
      while j < len && s[j] != b'\n' {
        j += 1
      } else {
        guard yield_(s[i:j]) is IterContinue else { return IterEnd }
        i = j + 1
        j = j + 1
      }
    } else {
      IterContinue
    }
  })
}
