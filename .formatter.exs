# Used by "mix format"
[
  inputs: [
    "{mix,.credo,.formatter}.exs",
    "{.medic,config,lib,test}/**/*.{ex,exs}",
    "guides/**/*.md",
    "*.md"
  ],
  line_length: 135,
  markdown: [line_length: 100],
  plugins: [MarkdownFormatter]
]
