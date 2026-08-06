# SURG 2026 — FPGA Motor Controller Documentation Site

Interactive technical documentation for the SURG 2026 FPGA-based field-oriented
motor controller. Built so that someone with no background in the project can
read the site start to finish and be caught up on the PCB, the RTL, the MATLAB /
FOC math, the Vivado path, and everything that is still unresolved.

Static site. No build step, no dependencies, no network access at runtime.

---

## Running it locally

The site must be served over HTTP rather than opened as a `file://` URL, because
browsers block some behaviour on local files. Any static server works.

**Python** (installed on this machine):

```bash
cd site
python -m http.server 8080
```

**Node** (also installed):

```bash
cd site
npx serve -l 8080
```

Then open <http://localhost:8080>.

---

## Deploying to GitHub Pages

Pages' branch source can only serve from `/` or `/docs` — **not** from an
arbitrary folder like `/site`. So this repo publishes via GitHub Actions instead:
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml) uploads `site/`
as the Pages artifact on every push to `main`.

To switch it on:

1. The repo must be **public**, unless the account has GitHub Pro/Team — Pages
   does not publish from private repos on the free plan.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
3. Push to `main` (or run the workflow manually from the Actions tab).

It then goes live at `https://<user>.github.io/<repo>/`.

Nothing in the site needs to change for this. Every asset path is relative and
routing is hash-based (`#/overview`), so the site works unmodified whether it is
served from a domain root or from a project subpath, and Pages needs no rewrite
rules for deep links.

---

## What's in it

| Section | Covers |
|---|---|
| **1 · Project Overview** | What the project is, why an FPGA, my role, current state, what's unknown |
| **2 · System Architecture** | Battery → power board → driver board → Arty Z7 → motor, the PS/PL split, tool flow |
| **3 · PCB Interface** | Full signal map from the parsed netlist, chip roles, four signal paths, six netlist red flags |
| **4 · FPGA / RTL** | Every module and testbench, port tables, interactive PWM / Hall / DISABLE / current models |
| **5 · MATLAB / FOC Math** | Fixed point and Q-format, Clarke / Park / inverse Park, PI loop, duty generation |
| **6 · FOC Strategy** | Six-step vs Hall-assisted vs encoder vs sensorless, and why Hall-assisted is the near-term path |
| **7 · Vivado Starter Guide** | Project setup, first simulation, XDC explanation, what's missing before a bitstream |
| **8 · Software & Tools** | MATLAB, Simulink, HDL Coder, Vivado, Verilog, Zynq, Arty Z7, Altium, Git, SimpleFOC, TI parts |
| **9 · Open Questions** | 16 tracked items with owner, severity, what each blocks, and a ready-to-send question |
| **10 · Timeline** | What happened in order, including the three assumptions that turned out wrong |
| **11 · Resource Library** | 129 categorised links, official docs preferred, videos marked |
| **12 · Glossary** | 25 terms, also available as hover popovers throughout the site |

Plus a **project assistant** (bottom-right button) — a retrieval bot over the
project knowledge base that cites its sources and says when it doesn't know.

---

## File structure

```
site/
├── index.html                  page shell, nav, search, chat panel
├── README.md                   this file
└── assets/
    ├── css/
    │   └── main.css            dark/light themes and all components
    └── js/
        ├── data.js             structured project data — EDIT THIS FIRST
        ├── content.js          page prose, SVG diagrams, code samples
        ├── interactive.js      the ten canvas/DOM widgets
        ├── chatbot.js          assistant knowledge base and retrieval
        └── app.js              router, search, TOC, glossary, rendering
```

### Where to make changes

**Adding a fact, a signal, a question, a link, or a glossary term** → `data.js`.
It holds `SIGNALS`, `RTL_MODULES`, `TESTBENCHES`, `QUESTIONS`, `TIMELINE`,
`GLOSSARY`, `LINKS` and `LEARNING_ORDER` as plain arrays. The tables, cards,
timeline, glossary and search index all build themselves from these, so adding an
entry is a one-line change that shows up everywhere.

**Adding or rewriting a page** → `content.js`. Pages live in the `PAGES` object,
keyed by their URL id. Add the id to `NAV` in `data.js` and it appears in the
sidebar, breadcrumbs, pager and search automatically.

**Adding an interactive model** → `interactive.js`. Register it as
`WIDGETS.myname = function (host) { ... }`, then place it in a page with
`widget('myname', 'Title', 'note')`.

**Teaching the assistant something** → `chatbot.js`. Add an entry to `KB` with
`k` (trigger keywords), `a` (answer HTML), `c` (citations) and `p` (page link).

---

## Content conventions

These are deliberate and worth preserving if you edit the site.

### Status badges

Every technical claim carries one:

- **Confirmed** — read directly from a project file or a vendor datasheet
- **Assumption** — a reasoned inference, not yet verified against the source
- **Open** — an unanswered question
- **Blocker** — an open item that stops downstream work

### Citations

Facts cite their source. Local project files appear as `code` spans; vendor
documentation links out. The `cite()` helper in `content.js` handles both from
the `SRC` registry in `data.js`.

### Accuracy rules the site follows

These were requirements, not preferences:

1. **No invented testing.** Nothing on the site claims the RTL compiled, that a
   simulator ran, or that hardware was tested — because none of that has
   happened. `vivado`, `xvlog`, `xelab`, `iverilog` and `verilator` were all
   absent from PATH when this was checked.
2. **Interactive models are labelled as models.** Every widget re-implements
   documented behaviour in JavaScript. Each is marked "Interactive model" and
   none is presented as simulator output.
3. **Netlist extraction is not visual DRC.** The PCB findings are stated as
   things to check in Altium, not as proven defects.
4. **Generated diagrams are labelled.** Every SVG carries "Generated explanatory
   diagram" in its caption.
5. **Three duty commands stays the control model** while the six physical HI/LO
   outputs are explained as the pin-level mapping. 3PWM is not framed as a new
   decision.
6. **Hall-assisted FOC is the near-term direction**; sensorless FOC is presented
   as future research with its prerequisites listed.

---

## Source material

Built from these local project files:

| File | Used for |
|---|---|
| `PCB_CROSSCHECK_2026-08-05.md` | The primary source. Netlist extraction, signal map, red flags. |
| `FPGA_KNOWN_INFO_2026-08-05.md` | RTL status, PS/PL split, open questions, Vivado status |
| `FPGA_TODO.md` | Work plan and PCB-team questions |
| `README.md` | Board interface summary |
| `SURG_FPGA_FOC.md` | Datasheet research log, platform comparison |
| `UPDATED_DRIVER_BOARD_REVIEW_2026-08-03.md` | History — marked superseded |
| `FPGA_BOARD_INTERFACE_2026-07-29.md` | History — describes the old board, superseded |
| `fpga/rtl/*.v` · `fpga/tb/*.v` | Port tables, behaviour descriptions, code samples |
| `matlab/*.m` · `board_interface_check_LAST_RUN.txt` | FOC math, Q-format, recorded run output |
| `DriverBoard.SchDoc` · `ActualDriverBoard.PcbDoc` · `HV Motor Driver.BomDoc` | Source of the parsed netlist |

Vendor documentation cited throughout: TI (UCC21222, AMC1300, AMC1311,
OPA4388), Digilent (Arty Z7), AMD/Xilinx (Zynq TRM, XADC UG480, Vivado guides),
MathWorks (FOC, Clarke/Park, HDL Coder, fixed point), SimpleFOC, Tektronix,
Keysight and Altium.

---

## Browser support

Modern evergreen browsers. Uses `color-mix()`, `:has()`, CSS custom properties,
`IntersectionObserver` and Canvas 2D. Respects
`prefers-color-scheme` on first load and `prefers-reduced-motion` for scrolling.
Theme choice and checklist progress persist in `localStorage`.

## Accessibility

Skip link, keyboard-navigable search (`/` to focus, arrows to move, Enter to
open), ARIA labelling on controls, visible focus rings, and `role="img"` with
descriptive labels on every diagram. Glossary popovers open on focus as well as
hover.
