///|
type Highlight Map[Int, Map[Int, Color]]

///|
let moonbit_parser : @tree_sitter.Parser = @tree_sitter.Parser::new()..set_language(
  moonbit,
)

///|
let moonbit : @tree_sitter.Language = @tree_sitter_moonbit.language()

///|
fn add_color(self : Editor, node : @tree_sitter.Node, color : Color) -> Unit {
  let start_row = node.start_point().row()
  let start_col = node.start_point().column()
  let end_row = node.end_point().row()
  let end_col = node.end_point().column()
  if self.highlight._[start_row] is Some(t) {
    t.set(start_col, color)
  } else {
    self.highlight._[start_row] = Map::new()..set(start_col, color)
  }
  if self.highlight._[end_row] is Some(t) {
    t.set(end_col, Color::Default)
  } else {
    self.highlight._[end_row] = Map::new()..set(end_col, Color::Default)
  }
}

///|
fn highlight_mbt(self : Editor) -> Unit {
  // todo: we could do incremental highlighting
  self.highlight._.clear()
  let source_code = @cbytes.concat(self.rows, sep=b"\n")
  let tree = moonbit_parser.parse_bytes(None, source_code)
  let root_node = tree.root_node()
  // println(root_node.string())
  let cursor = @tree_sitter.QueryCursor::new()
  let query = @tree_sitter.Query::new?(moonbit, HIGHLIGHT_QUERY).unwrap()
  cursor.exec(query, root_node)
  while cursor.next_capture() is Some(c) {
    self.highlight_node(c.node, query.capture_name_for_id(c.index))
  }
}

///|
fn highlight_node(
  self : Editor,
  node : @tree_sitter.Node,
  group : String
) -> Unit {
  fn add_fg_color(name : String) {
    let color = match self.theme._[name] {
      Some(Fg(color)) => Some(color)
      Some(Style(fg~, ..)) => fg
      _ => None
    }
    if color is Some(color) {
      self.add_color(node, color)
    }
  }

  match group {
    _ => add_fg_color(group)
  }
}

///|
fn highlight(self : Editor) -> Unit {
  if self.filename is [.., .. b".mbt"] {
    self.highlight_mbt()
  }
}
