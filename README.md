# ME Homepage — สาขาวิชาวิศวกรรมเครื่องกล มรภ.นครสวรรค์

**เว็บจริง: <https://krissanar.github.io/me-nsru/>**

Static site split out of the single-file export `export/index.html`
(1.53 MB, everything inlined as base64).

No build step, no dependencies. Serve the folder and it runs.

```bash
npx serve site
```

Any static host works — GitHub Pages, Netlify, or a plain Apache/nginx
directory. Upload the whole `site/` folder as-is.

## Layout

```
ME_Page/                         ← repository root
  README.md                      this file
  .github/workflows/pages.yml    publishes site/ to GitHub Pages on push
  site/                          ← the only folder that gets published
    index.html            27 KB   หน้าแรก — markup only
    ME-Study-Plan.html    22 KB   แผนการศึกษา ปี 1–4
    css/
      fonts.css            3 KB   @font-face — IBM Plex Sans Thai + Plex Mono
      style.css           19 KB   tokens, reset, components, breakpoints
    js/
      main.js            2.7 KB   burger menu, header height sync, hero video
    assets/
      img/                        logo, og-cover, 3 outcome photos,
                                  5 staff portraits, lab background
      fonts/                      10 × woff2 (thai + latin subsets)
      video/hero.mp4      521 KB  hero loop, lazy — desktop only
  tools/                         ← source, not published
    og-card.html                  source for the share card
    build-og.sh                   renders it to assets/img/og-cover.jpg
```

`export/` and the old `ME-Homepage-share_*.html` files stay on disk but are
git-ignored: site/ supersedes them, and they are 1.6 MB of base64 apiece that
git cannot meaningfully diff.

## Which source this came from

`ME_Page/` holds several versions. This build comes from **`export/index.html`**,
the newest and the only one carrying the real URLs. The earlier
`ME-Homepage-share_2 - Copy.html` had all 17 links still on `href="#"`, plus
older wording — "หลักสูตรใหม่" instead of "หลักสูตรปรับปรุง", "โรงประลอง"
instead of "อาคารปฏิบัติการ" — and no ค่าเทอม/กยศ. panel. From here on edit
`site/`, not the old single-file versions.

## The split itself changed nothing visual

Verified by rendering `site/index.html` and `export/index.html` side by side at
1280×900 and comparing the computed geometry of all 310 `<body>` elements:
identical layout hash, identical `document.scrollHeight` (5876 px), identical
resolved fonts and colours, same 33 links. (The typography pass below came
after, and *does* change appearance — deliberately.)

What the split changed is how the page loads. The original parsed 1.53 MB of
base64 before it could paint — fonts, photos and a 521 KB video all sat inside
the HTML whether used or not. Now:

- `index.html` is **27 KB** instead of 1.53 MB.
- Images and fonts are separate files, so the browser caches them across page
  loads and `loading="lazy"` on the photos finally does something. In the
  single-file version "lazy" was meaningless — those bytes had already arrived.
- The hero video is only fetched when `main.js` decides to play it. On phones,
  reduced-motion, and data-saver connections it is never requested at all.
- The two Thai font subsets used above the fold are `<link rel="preload">`ed.

One byte-level fix: a stray `}` closed `@media (max-width:860px)` one rule
early, pushing the two touch-target rules to the top level and leaving a second
`}` that the CSS parser discarded as an error. Those rules had therefore been
applying at every viewport all along, so `style.css` keeps them top-level —
layout unchanged, brace balanced. That is also the correct reading: WCAG 2.5.8
applies at all widths, and at desktop `.ftr ul a` measures ~23 px on its own.

## Typography

The page mixes two scripts, and the original styled them the same way. A label
style calibrated for Latin all-caps — small, letter-tracked, mono, low-contrast
grey — had been applied to Thai text too, where it fails three ways at once:

- **Too small.** Thai stacks vowels and tone marks (ผู้ = ผ + ู below + ้ above).
  Below about 13 px those collapse into each other. 21 elements were rendering
  Thai between 11.5 px and 13.5 px.
- **Tracking breaks it.** Thai is written without spaces between words, so
  letter-spacing removes the only word-boundary cue a reader has. Footer
  headings like "ลิงก์ที่เกี่ยวข้อง" were the worst of it.
- **Contrast.** `--mute-2` was *lighter* than `--mute` and used only on the
  smallest labels — the least contrast exactly where the most was needed. It
  measured 3.10:1 against a 4.5:1 requirement.

So there are now two label styles, and `style.css` says which is which:

- **Latin labels** keep mono + tracking: `.accred-main .kicker`, `.fee .kicker`,
  `.band .kicker`, `.brand small`, and the numerals.
- **Thai labels** get the body face, no tracking, a 13.5 px floor, and weight
  rather than size for emphasis: `.card-glass .kicker`, `.accred-side .kicker`,
  `.facts dt`, `.fee-grid dt`, `.ftr h2`.

`--mute-2` is gone; `--label:#5F6875` replaces it (5.70:1 on white, 5.03:1 on
`--bg-soft-2`). Nothing below 13.5 px is Thai any more.

Measured before → after, at 1440×900 across 153 text elements:

| | before | after |
|---|---|---|
| WCAG AA contrast failures | 25 | **0** |
| Thai text below 14 px | 21 elements | 12, none below 13.5 px |
| smallest Thai | 11.5 px | 13.5 px |

Two elements still report as failures in an automated sweep — `.band .ttl` and
`.band .kicker`. Both are false positives: they sit on a `linear-gradient`
overlay, which a `backgroundColor` probe cannot see. Sampling the actual
painted pixels behind the title gives rgb(36,44,55) and **14.09:1**.

Two other fixes came out of the same pass:

- **320 px horizontal overflow.** `repeat(auto-fit,minmax(300px,1fr))` sets a
  track floor that cannot shrink, and at a 320 px viewport the wrap only leaves
  ~284 px, so the page ran 4 px wide. All ten auto-fit tracks are now
  `minmax(min(<floor>,100%),1fr)`, which is inert above the threshold. This bug
  was in `export/index.html` too — it is not something the split introduced.
- **Staff emails.** They cannot fit a phone-width card at any usable size
  (the longest needs 158 px in a 120 px column even at 11 px), so the line has
  to break. A `<wbr>` after each `@` puts the break there instead of mid-token
  — "krissana@ / nsru.ac.th" rather than "krissana@nsru.ac.t / h". `<wbr>` is
  zero-width: href, copied text and accessible name are all unchanged.

Verified clean at 320, 360, 375, 390, 414, 480, 540, 600, 700, 768, 834, 900,
1024, 1180, 1280, 1366, 1440, 1600 and 1920 px — no horizontal overflow, no
clipped content, no tap target under 24 px.

What was **not** changed: the scale still has 26 distinct sizes with half-pixel
steps (15.5, 16.5, 17.5). That is unusually fine-grained, but the steps are
deliberate optical tuning and collapsing them would churn the whole page for no
visible gain.

## The share card

`assets/img/og-cover.jpg` (1200×630) is what Facebook and Line show when
someone shares the page. It is generated — edit `tools/og-card.html` and re-run:

```bash
bash tools/build-og.sh
```

The card is rendered in headless Chrome rather than composed with an image
library because it contains Thai text, and ffmpeg's `drawtext` has no
complex-script shaping — it would break สระ and วรรณยุกต์. The script asserts
the output is exactly 1200×630, since `og:image:width` / `:height` in
`index.html` hard-code those numbers.

`lab.webp` is the card background, blurred and heavily scrimmed. That is
deliberate: it is not a plain photo but a composite carrying its own baked-in
captions, which otherwise read as a second layer of text at thumbnail size.

## Deploying

Pushing to `main` publishes automatically. `.github/workflows/pages.yml`
uploads the **`site/` folder only** and deploys it to GitHub Pages, so `tools/`
and this README never reach the public site. There is no build step — the site
is plain HTML, CSS and JS with its assets beside it.

To publish a content change:

```bash
git add site && git commit -m "อัปเดตเนื้อหา" && git push
```

The Actions tab shows the run; it finishes in well under a minute. You can also
redeploy by hand from Actions → "Deploy site to GitHub Pages" → Run workflow.

One-time setup on GitHub, after the first push: **Settings → Pages → Source**
must be set to **GitHub Actions** (not "Deploy from a branch"). Without that the
workflow runs but nothing is served.

## Site URL

The site is served from a subpath, `https://krissanar.github.io/me-nsru/`.
Every internal link and asset reference is relative, so the subpath needs no
`<base>` tag and nothing breaks — but three tags do carry the absolute URL and
have to move together if the site ever changes address:

| tag | why it cannot be relative |
|---|---|
| `og:image` | Line will not resolve a relative path; Facebook only sometimes does |
| `og:url` | names the canonical target of a share |
| `link rel="canonical"` | tells search engines which URL is authoritative |

All three sit together at the top of `index.html`.

If IT ever points a university domain (say `me.nsru.ac.th`) at GitHub Pages,
change those three, set the domain under **Settings → Pages → Custom domain**,
and commit a `site/CNAME` file containing just the hostname.

## Notes

- The five staff photos have **name banners burned into the images** (green bar,
  name and degree), which repeat the name printed below each photo. Cropping
  them out would cut into the faces. Replacing them with clean portraits would
  tidy the section up.
- On phones the topbar wraps to two rows and the header stack takes ~165 px
  before any content. It scrolls away (only `.hdr` is sticky), so it costs the
  fold once rather than permanently — but shortening those two link labels
  would buy back a lot of first screen.
- `ME-Study-Plan.html` pulls IBM Plex from the Google Fonts CDN while
  `index.html` uses local `assets/fonts/`. Worth switching it to `css/fonts.css`.
- Staff portraits are 272×374 and 404×444, framed `3/4` with
  `object-position: center top`. Match that ratio when swapping a photo in.
- `--lab` (`assets/img/lab.webp`) is used three times: hero background,
  full-bleed band, and the share card. Replacing it changes all three.
- The nav degrades without JS — a `<noscript>` block shows the menu inline.
- All outbound links carry `target="_blank" rel="noopener"`.
- The phone link is `tel:+6656219100;ext=2301` — RFC 3966 extension syntax.
