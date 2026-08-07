# hBlog

[![Haskell](https://img.shields.io/badge/Haskell-5D4E9F?logo=haskell&logoColor=white)](https://ronin-shadow.github.io/hBlog/api/)
[![Documentation](https://img.shields.io/badge/Documentation-API-blue?logo=readthedocs&logoColor=white)](https://ronin-shadow.github.io/hBlog/api/)

Static web page builder written in Haskell. A small custom blog generator and my personal blog.

## What this does

hBlog is a tiny static-site generator that parses a custom plaintext markup format (stored as .txt files in the `blogs/` directory) and converts them into HTML pages and an index page. It is provided as a library and a CLI executable named `blog`.

## Stack

- Language: Haskell (GHC 9.6 used in the flake)
- Styles: CSS (style.css included)
- Dev environment: Nix flake (flake.nix / flake.lock)

## Notable libraries and tools

From `blog.cabal`:
- base
- directory
- filepath
- mtl
- time
- optparse-applicative (CLI parsing)
- hspec, hspec-discover (tests)
- raw-strings-qq (tests)

From `flake.nix` (developer tooling):
- GHC 9.6
- cabal-install
- haskell-language-server (HLS)
- fourmolu (formatter)
- nixfmt-rfc-style
- wai-app-static (small static web server)

## Using the Nix dev shell (recommended)

This repository includes a `flake.nix` and `flake.lock`. The flake provides a developer shell with GHC, cabal, formatters and an included helper script `build-blog`.

1. Enter the nix shell:

```bash
nix develop
```

2. Inside the shell you can run the helper script to build the site:

```bash
build-blog
# which runs: cabal run blog -- convert-dir -i blogs/ -o docs/ -N "Mark's Blog"
```

## Building without Nix

Install a recent GHC (>= 9.6) and `cabal-install`, then:

```bash
cabal build
cabal run blog -- convert-dir -i blogs/ -o docs/ -N "Mark's Blog"
```

## CLI usage

The executable supports two main modes (see `app/Main.hs`):

- convert-dir (convert a directory with `.txt` posts into an output directory)
- convert-single (convert a single file from markup to html)

Examples:

```bash
# convert a directory of posts to docs/
cabal run blog -- convert-dir -i blogs/ -o docs/ -N "Mark's Blog"

# convert a single file to output.html
cabal run blog -- convert-single blogs/mypost.txt docs/mypost.html

# using stdin/stdout (single file)
cat blogs/mypost.txt | cabal run blog -- convert-single - -
```

Notes:
- If the output directory already exists the tool will ask whether to override it.
- Non-`.txt` files in the input directory are copied to the output (images, assets, etc.). The configured stylesheet (default `style.css`) is copied into the output.

## Markup language (brief)

This project uses a small custom plaintext markup. Blocks are separated by an empty line. The following conventions are supported (these are the parser rules used by the project):

```haskell
case first of
  ('*' : ' ' : text) -> Heading 1 (trim text)
  ('-' : ' ' : _) -> UnorderedList $ map (trim . drop 2) allLines
  ('#' : ' ' : _) -> OrderedList $ map (trim . drop 2) allLines
  ('>' : ' ' : _) -> CodeBlock $ map (trim . drop 2) allLines
  ('~' : ' ' : text) -> Date $ parseIsoDay text
  _ -> Paragraph (unlines allLines)
```

- Lines beginning with `* ` become a level-1 heading.
- Lines beginning with `- ` become an unordered list (every line in the block is an item).
- Lines beginning with `# ` become an ordered list (every line in the block is an item).
- Lines beginning with `> ` become a code block (each line after the `> ` is preserved as code lines).
- Lines beginning with `~ ` parse an ISO date (e.g. `~ 2026-08-03`).
- Any other block becomes a paragraph (text preserved with newlines).

Nesting is supported in the parser implementation, and blocks are split by an empty line (so add a blank line between blocks).

### Example post

```txt
* My thoughts on about this blog

~ 2026-08-03

Hey! I build this blog generator to learn Haskell. It was quit 'tuff and fun challange. I don't know what I'm gonna do with this blog yet. Probably talking why Haskell is good... yeah...
Cool thing about this blog generator(whatever u call it) is that it can do this, watch:

# This is an ordered list btw
# And it goes on
# and next...

You got the idea. I don't follow the gramma rules ;) I just type in Neovim. But heres another thing look:

- Unordered list!
- Wow, who would thought about this?
- and it goes on...

Great. What else can we do with that huh? Well coding! Here it goes:

> myBestFunction :: Int -> Int
myBestFunction n = n*2
```

This example shows headings, a date, paragraphs, ordered and unordered lists, and a code block.

## Tests

Run the test-suite with:

```bash
cabal test
```

## Serve the generated site

After building the site to `docs/` you can serve it locally:

```bash
# python simple server
python -m http.server 8000 --directory docs

# or use any static server you prefer
```

## About flake.nix

`flake.nix` in the repository defines a reproducible development shell for `x86_64-linux` and includes a helper `build-blog` script. Use `nix develop` to get a reproducible environment with GHC, cabal, formatters and language server.

## License

This project includes a LICENSE file (BSD-3-Clause).
