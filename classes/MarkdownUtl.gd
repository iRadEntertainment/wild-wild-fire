extends RefCounted
class_name MarkdownUtl


static func convert_to_bbcode(markdown: String) -> String:
	markdown = markdown.replace("\r\n", "\n").replace("\r", "\n")
	
	var out := PackedStringArray()
	var lines := markdown.split("\n", false)
	var in_list := false
	
	for i in lines.size():
		var line: String = lines[i]
		
		# Close list on blank line
		if line.strip_edges() == "":
			if in_list:
				out.append("[/ul]")
				in_list = false
			out.append("") # keep a blank line
			continue
		
		# Headings
		var heading = _match_heading(line)
		if heading.found:
			if in_list:
				out.append("[/ul]")
				in_list = false
			out.append(_heading_to_bbcode(heading.level, _inline_to_bbcode(heading.text)))
			continue
		
		# Bullet lists
		var bullet = _match_bullet(line)
		if bullet.found:
			if not in_list:
				out.append("[ul]")
				in_list = true
			out.append("[li]" + _inline_to_bbcode(bullet.text) + "[/li]")
			continue
		
		# Paragraph
		if in_list:
			out.append("[/ul]")
			in_list = false
		out.append(_inline_to_bbcode(line))
	
	# Close list if file ends while in a list
	if in_list:
		out.append("[/ul]")
	
	var bb := "\n".join(out)
	return _condense_blank_lines(bb)


# Headings: ^\s{0,3}(#{1,6})\s+(.*)
static func _match_heading(line: String) -> Dictionary:
	var r := RegEx.new()
	r.compile("^\\s{0,3}(#{1,6})\\s+(.*)$")
	var m := r.search(line)
	if m:
		return {
			"found": true,
			"level": m.get_string(1).length(),
			"text": m.get_string(2)
		}
	return {"found": false}


static func _heading_to_bbcode(level: int, text: String) -> String:
	# Tweak sizes to your UI. RichTextLabel supports [font_size=...]
	var sizes = {1: 28, 2: 24, 3: 20, 4: 18, 5: 16, 6: 14}
	var s = sizes.get(level, 16)
	return "[font_size=%d][b]%s[/b][/font_size]" % [s, text]


# Bullets: ^\s*[-*]\s+(.*)
static func _match_bullet(line: String) -> Dictionary:
	var r := RegEx.new()
	r.compile("^\\s*[-*]\\s+(.*)$")
	var m := r.search(line)
	if m:
		return {"found": true, "text": m.get_string(1)}
	return {"found": false}


# Inline conversions: links, images, code, bold, italics
static func _inline_to_bbcode(s: String) -> String:
	var out := s
	
	# Images: ![alt](url)  -> [img]url[/img]  (alt ignored by BBCode)
	out = _regex_replace(out, "!\\[([^\\]]*)\\]\\(([^)\\s]+)(?:\\s+\"[^\"]*\")?\\)", func(m):
		return "[img]%s[/img]" % m.get_string(2)
	)
	
	# Links: [text](url) -> [url=url]text[/url]
	out = _regex_replace(out, "\\[([^\\]]+)\\]\\(([^)\\s]+)(?:\\s+\"[^\"]*\")?\\)", func(m):
		var text: String = m.get_string(1)
		var url: String = m.get_string(2)
		return "[url=%s]%s[/url]" % [url, text]
	)
	
	# Inline code: `code` -> [code]code[/code]
	out = _regex_replace(out, "`([^`]+)`", func(m):
		return "[code]%s[/code]" % m.get_string(1)
	)
	
	# Bold: **text** or __text__ -> [b]text[/b]
	out = _regex_replace(out, "(\\*\\*|__)(.+?)\\1", func(m):
		return "[b]%s[/b]" % m.get_string(2)
	)
	
	# Italic: *text* or _text_ (but not ** or __)
	out = _regex_replace(out, "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", func(m):
		return "[i]%s[/i]" % m.get_string(1)
	)
	out = _regex_replace(out, "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", func(m):
		return "[i]%s[/i]" % m.get_string(1)
	)
	
	return out


static func _regex_replace(text: String, pattern: String, repl_func: Callable) -> String:
	var r := RegEx.new()
	r.compile(pattern)
	var i := 0
	var result := ""
	while true:
		var m := r.search(text, i)
		if not m:
			result += text.substr(i)
			break
		result += text.substr(i, m.get_start() - i)
		result += repl_func.call(m)
		i = m.get_end()
	return result


static func _condense_blank_lines(s: String) -> String:
	var r := RegEx.new()
	r.compile("(\\n\\s*){3,}")
	return r.sub(s, "\n\n", true)
