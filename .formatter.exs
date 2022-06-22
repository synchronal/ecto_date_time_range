# Used by "mix format"
[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "guides/**/*.md",
    "*.md"
  ],
  markdown: [line_length: 100],
  plugins: [MarkdownFormatter]
]
