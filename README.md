![Swordfish](https://raw.githubusercontent.com/voikya/swordfish/master/swordfish.png)

Swordfish is a simple document processing library for Ruby. It enables the conversion of Microsoft Word XML documents (.docx) into clean, semantic HTML5, without all the mess that normal export     tools or copy-and-paste would produce.

Features
-----

Swordfish currently supports identifying the following features:

- Paragraphs
- Formatting: bold, italic, underline, superscript, subscript, strikethrough
- Links
- Lists (including nested lists)
- Tables
- Footnotes and Endnotes
- Images (except for Word Drawings)

Installation
-----

Swordfish is available through RubyGems, so you can install it with `gem install swordfish`.

Converting a Document
-----

Converting a Word document into HTML just requires two calls: one to parse the document, and one to generate the markup:

```ruby
require 'swordfish'
Swordfish.open('~/Documents/my_word_doc.docx').to_html
```

Additional configuration options may be provided by calling `settings` with a hash of parameters prior to generating the final markup. For instance, if you want to enable footnotes (appearing as a block at the end of the HTML document), enable the `footnotes` option:

```ruby
Swordfish.open('~/Documents/my_word_doc.docx').settings(:footnotes => true).to_html
```

The following settings are currently available (all are boolean, and default to `false`)

- `guess_headers` — When true, attempt to identify headers within the text and assign them the appropriate `<h1>` through `<h6>` tags. When false, all text will be presented as normal paragraphs.
- `footnotes` — When true, preserve footnote and endnote content in a block at the end of the generated HTML, including links back to the original reference points in the text. When false, footnotes will be ignored.
- `smart_br` — When true, attempt to clean up unnecessary linebreaks often present in Word markup, such as at the very beginning or end of a paragraph. When false, linebreaks will be preserved exactly as in the original Word markup.
- `full_document` — When true, the generated HTML will represent a complete HTML document, including a doctype and header. When false, the output will be an HTML fragment suitable for insertion into the DOM, for example.

Images within the Word document are available after parsing by calling the `images` method, which returns a hash of file names and temporary files.

```ruby
# Print the file name and size of each image in a document
doc = Swordfish.open('~/Documents/my_word_doc.docx')
doc.images.each do |filename, tempfile|
  puts "#{filename}: #{tempfile.size}"
end
```
