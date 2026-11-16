# infoblocks

Infographic building blocks for Beamer: icon circles, cards, stat tiles and percentage meters. They are made for the JECS and NIES themes in `~/dev/tex/` and match the look of the Quarto JECS decks.

The accent colours are the package's own, with the JECS palette values, so a slide looks the same under either theme.

## Install

Clone it into `~/dev/tex/`, beside the themes, then symlink `tex/` into the user texmf tree, the same way as the themes:

```bash
git clone git@github.com:fabregithub/infoblocks.git ~/dev/tex/infoblocks
ln -sfn ~/dev/tex/infoblocks/tex ~/Library/texmf/tex/latex/infoblocks
```

Compile with **XeLaTeX** (or LuaLaTeX), because `fontawesome7` needs `fontspec`. Load it after the theme:

```latex
\usetheme{JECS}      % or NIES
\usepackage{infoblocks}
```

## Commands

| Command | Draws |
|---|---|
| `\iconcircle[accent]{icon}` | White icon on a filled circle (2.1em across, so it follows the font size) |
| `\softicon[accent]{icon}` | Accent-coloured icon on a pale circle |
| `\stat[accent]{約10万人}` | Big bold number, as its own paragraph |
| `\stattile[accent][tcb opts]{icon}{96.1\%}{label}` | Tile with the icon on the left and the number and label on the right |
| `\begin{infocard}[accent][tcb opts]{icon}{title}` … `\end{infocard}` | Pale card with an accent rule on top and an icon and title header |
| `\meter[accent]{51.8}[2.4cm]` | Percentage above a bar; the width defaults to `\linewidth` |

### Accents

- **Built in:** `navy` (default), `red`, `teal`, `plain`.
- **Your own:** `\ibdefineaccent{name}{accent}{tint}{ink}` defines another. For example, `\ibdefineaccent{violet}{violet}{violet!8}{violet}` under NIES.
- **Colour names you can use directly:** `ibnavy`, `ibred`, `ibteal` and `ibtext`. They compile under any theme, whereas `karakurenai` exists only in JECS.

### Icons

Icons are Font Awesome 7 Free names, for example `users`, `thumbs-up`, `laptop`, `magnifying-glass` and `vault`. Look them up with `texdoc fontawesome7`.

The `bootstrapicons` package has the same set as Quarto, but it draws each icon as a black PDF image that cannot be recoloured, so it cannot give a white icon on a filled circle.

## Example

`example/example-jecs.tex` and `example/example-nies.tex` are the same two slides under each theme. They were taken from the Koriyama エコチル調査連絡協議会 deck.

```latex
\begin{columns}[T,totalwidth=\textwidth]
  \begin{column}{0.325\textwidth}
    \begin{infocard}[navy][equal height group=row1]{users}{全体調査}
      \stat{約10万人}
      \begin{itemize}
        \item 質問票調査（保護者）…
      \end{itemize}
    \end{infocard}
  \end{column}
  ...
\end{columns}

\stattile[red]{thumbs-up}{51.2\%}{親権者・積極的意思表示}
\meter[teal]{41.2}[2.4cm]
```

Run XeLaTeX **twice**. Both themes place the frame title with a `remember picture` overlay, and it appears only after the second pass.

## Quarto: one source for reveal.js and Beamer

`quarto/` holds the pieces that let a Quarto reveal.js deck written with the JECS layout classes also render through Beamer with these blocks:

| File | Role |
|---|---|
| `infoblocks.lua` | Quarto filter: `.cards`/`.card`, `.tiles`/`.tile`, icons (`[]{.ic .bi .bi-x}`), `.chip`, `.stat`, `.takeaway`, `.cite`, `.iconrow`, `.timeline`, `.chain`, `.org`, `.units`, `.compare`, `.steps`, `.photos`, `.booklet` → infoblocks / Beamer. It also maps Bootstrap Icons names to Font Awesome names, and converts image sizes from px on the 1600 px slide to mm on the 160 mm slide. It does nothing for other formats, so reveal.js output is unchanged |
| `before-body.tex` | Template partial: the title page as a plain, unnumbered frame |
| `title-background.tex` | Preamble: the JECS or NIES title image on page 1, in place of the theme's canvas |

In the deck's YAML, with the paths relative to the `.qmd`:

```yaml
filters: [../../../../tex/infoblocks/quarto/infoblocks.lua]
format:
  beamer:
    theme: JECS
    pdf-engine: xelatex
    latex-tinytex: false        # TeX Live 2026, not ~/Library/TinyTeX
    include-in-header:
      - beamer-preamble.tex     # fonts, zxjatype/xeCJK, \usepackage{infoblocks}
      - ../../../../tex/infoblocks/quarto/title-background.tex
    template-partials: [../../../../tex/infoblocks/quarto/before-body.tex]
```

`FY2026/20261116-JECS-Koriyama/quarto/` in the presentations repository is the working example.

Why it is built this way:

- **Title page.** Pandoc's Beamer class uses `ignorenonframetext`, which skips everything between frames and only finds frames written as `\begin{frame}` in the source. The themes' `\titleframe` macro therefore produces nothing, and its background setting is skipped. The partial writes the frame itself, and the preamble file swaps the background for page 1.
- **Three passes in the filter.** The first runs top-down over containers, so they see their children's original spans. Pandoc does not revisit what a top-down handler returns, so the second, bottom-up pass handles what is inside them, and the span mapping runs last.
- **Whitespace trimming.** It strips ASCII whitespace only. Lua's `%s` also matches the byte `0xA0`, which ends many UTF-8 Japanese characters.
- **Raw `{=html}` blocks** (the meter grid, for example) do not reach Beamer. A Beamer version of such a slide goes in `::: {.content-visible when-format="beamer"}`.

## Notes

- **Card heights:** cards set side by side only line up if they share an `equal height group`.
- **Overflow:** nothing warns when text overflows a card or the slide, so check the PDF.
- **`\stat`:** it ends its own paragraph, so don't follow it with `\par`.

## Licence

MIT (see `LICENSE`). The JECS and NIES title images that `quarto/title-background.tex` points to belong to the theme repositories and are not part of this package.
