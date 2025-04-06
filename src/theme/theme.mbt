///|
typealias Color = @termbit.Color

///|
pub type Theme Map[String, Style] derive(Show)

///|
pub enum Style {
  Fg(Color)
  Style(
    fg~ : Color?,
    bg~ : Color?,
    underline~ : (Color, UnderlineStyle)?,
    modifiers~ : Array[Modifier]
  )
} derive(Show)

///|
pub enum UnderlineStyle {
  Line
  Curl
  Dashed
  Dotted
  Double_line
} derive(Show)

///|
pub enum Modifier {
  Bold
  Dim
  Italic
  Underlined
  Slow_blink
  Rapid_blink
  Reversed
  Hidden
  Crossed_out
} derive(Show)

///|
let palette : Map[String, Color] = {
  "default": Default,
  "black": Black,
  "red": Red,
  "green": Green,
  "yellow": Yellow,
  "blue": Blue,
  "magenta": Magenta,
  "cyan": Cyan,
  "gray": DarkGray,
  "light-red": LightRed,
  "light-green": LightGreen,
  "light-yellow": LightYellow,
  "light-blue": LightBlue,
  "light-magenta": LightMagenta,
  "light-cyan": LightCyan,
  "light-gray": LightGray,
  "white": White,
}

///|
fn parse_rgb(rgb_str : String) -> Color! {
  // do not use base=16 because the input could be 0b, which will leads to error
  fn p!(i, j) {
    @strconv.parse_uint!([.."0x", ..rgb_str.view(start_offset=i, end_offset=j)])
  }

  let r = p!(1, 3).to_byte()
  let g = p!(3, 5).to_byte()
  let b = p!(5, 7).to_byte()
  Color::RGB(r, g, b)
}

///|
test "parse_rgb" {
  fn p(x) {
    parse_rgb?(x)
  }

  inspect!(p("#eff1f5"), content="Ok(RGB(b'\\xEF', b'\\xF1', b'\\xF5'))")
  inspect!(p("#fe640b"), content="Ok(RGB(b'\\xFE', b'\\x64', b'\\x0B'))")
}

///|
fn parse_underline_style(style : String) -> UnderlineStyle! {
  match style {
    "line" => UnderlineStyle::Line
    "curl" => UnderlineStyle::Curl
    "dashed" => UnderlineStyle::Dashed
    "dotted" => UnderlineStyle::Dotted
    "double_line" => UnderlineStyle::Double_line
    _ => fail!("parse_underline_style")
  }
}

///|
fn parse_modifier(modifier : String) -> Modifier! {
  match modifier {
    "bold" => Modifier::Bold
    "dim" => Modifier::Dim
    "italic" => Modifier::Italic
    "underlined" => Modifier::Underlined
    "slow_blink" => Modifier::Slow_blink
    "rapid_blink" => Modifier::Rapid_blink
    "reversed" => Modifier::Reversed
    "hidden" => Modifier::Hidden
    "crossed_out" => Modifier::Crossed_out
    _ => fail!("parse_modifier")
  }
}

///|
fn parse_item(item : Json) -> Style! {
  match item {
    String(color) => Fg(palette[color].unwrap())
    Object(
      {
        "fg"? : fg,
        "bg"? : bg,
        "underline"? : underline,
        "modifiers"? : modifiers,
        ..
      }
    ) => {
      let fg = if fg is Some(String(fg)) { palette[fg] } else { None }
      let bg = if bg is Some(String(bg)) { palette[bg] } else { None }
      let underline = if underline is Some(Object(underline)) {
        guard underline["color"].unwrap() is String(color)
        guard underline["style"].unwrap() is String(style)
        Some((palette[color].unwrap(), parse_underline_style!(style)))
      } else {
        None
      }
      let modifiers = if modifiers is Some(Array(modifiers)) {
        let ms = []
        for m in modifiers {
          guard m is String(modifier)
          ms.push(parse_modifier!(modifier))
        }
        ms
      } else {
        []
      }
      Style(fg~, bg~, underline~, modifiers~)
    }
    _ => fail!("parse_item")
  }
}

///|
pub fn load_theme(path : String) -> Theme! {
  let contents = @fs.read_file_to_string!(path)
  let json = @json.parse!(contents)
  guard json is Object(json_obj)
  let theme = {}
  match json_obj {
    { "palette": Object(local_palette), .. } =>
      for k, v in local_palette {
        guard v is String(rgb_str)
        palette[k] = parse_rgb!(rgb_str)
      }
    _ => ()
  }
  for k, v in json_obj {
    if k == "palette" {
      continue
    }
    theme[k] = parse_item!(v)
  }
  theme
}

///|
pub let catppuccin_latte : Theme = {
  guard @env.current_dir() is Some(path)
  load_theme?([..path, .."/theme/catppuccin-latte.json"]).unwrap()
}
