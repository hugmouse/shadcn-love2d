# shadcn-love2d

A [shadcn/ui](https://ui.shadcn.com)-inspired task management app screen copied with [LOVE 12.0](https://love2d.org).

Dark-themed data table with filtering, sorting, pagination, pseudo-CRUD operations, and persistent storage.

## Features

What do you even expect to be here?

- Full data table with resizable columns, row selection, and hover states
- Text filtering, multi-select status/priority dropdowns
- Column header sorting (asc/desc) with sort indicators
- Pagination with configurable rows per page
- Pseudo-CRUD: add, edit, copy, and delete tasks via modals
- Persistent storage in .lua file with json inside
- [Lucide](https://lucide.dev) SVG icons rendered via svglover (with mods)
- shadcn/ui zinc palette, 8px radius, 1px border design tokens
- Profiler overlay (F3)

## Building the app on macOS

You can package it in a very inconvinient way:

```bash
zip -9 -r -q build/shadcn-love2d.love \
    main.lua conf.lua theme.lua \
    components/ screens/ data/ lib/ assets/ \
    -x "lib/batteries/.git/*" "lib/batteries/.github/*" \
       "lib/batteries/.test/*" "lib/batteries/.luacheckrc"

cp -R /path/to/love.app build/shadcn-love2d.app
cp build/shadcn-love2d.love build/shadcn-love2d.app/Contents/Resources/game.love
```

## Project Structure

```
main.lua              Screen router, profiler overlay
conf.lua              Window config
theme.lua             Design stuff (colors, spacing, radii, fonts)

screens/
  task_list.lua       Main screen: toolbar, table, pagination, popups

components/
  icon.lua            SVG icon loader/renderer (Lucide icons via svglover)
  badge.lua           Pill-shaped outline labels
  checkbox.lua        Toggleable checkbox
  button.lua          Multi-variant button (default/outline/ghost)
  input.lua           Text input (single/multiline)
  select.lua          Single-select dropdown
  table.lua           Data table with columns, hover, scroll, sort
  dialog.lua          Read-only task detail modal
  task_form.lua       Add/edit task form modal
  confirm_dialog.lua  Destructive action confirmation modal
  dropdown.lua        Multi-select filter dropdown
  context_menu.lua    Action menu (row/column headers)
  toolbar.lua         Horizontal left/right item layout
  pagination.lua      Page nav bar with rows-per-page select
  layout.lua          Header/footer draw helpers

assets/
  icons/              Lucide SVG icons (20 icons)

data/
  tasks.lua           Placeholder data (love2d repo issues)
  store.lua           Mutable task store with persistence

lib/
  batteries/          Lua utility library (sort, tablex, stringx, etc.)
  InputField.lua      ReFreezed logic-only text input library
  svglover.lua        SVG rendering for LOVE (patched for LOVE 12, other stuff)
  profile.lua         Profiler! Can you believe that?
```

## Third-Party Libraries

| Library                                                | License | Source                       |
| ------------------------------------------------------ | ------- | ---------------------------- |
| [batteries](https://github.com/1bardesign/batteries)   | zlib    | Max Cahill                   |
| [InputField](https://github.com/ReFreezed/InputField)  | MIT     | Marcus 'ReFreezed' Thunstrom |
| [profile.lua](https://github.com/2dengine/profile.lua) | MIT     | 2dengine LLC                 |
| [svglover](https://github.com/globalcitizen/svglover)  | GPL-3.0 | globalcitizen                |
| [Lucide Icons](https://github.com/lucide-icons/lucide) | ISC     | Lucide Contributors          |

### Modifications to svglover

The bundled `lib/svglover.lua` is modified from the original for LOVE 12.0 and more icon compatibility:

1. `currentColor` support: `_colorparse` now handles `stroke="currentColor"` (returns white for caller tinting)
2. SVG root attribute inheritance: `fill`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin` from the `<svg>` root element now propagate to child elements
3. `<line>` element support: new element handler for `<line x1 y1 x2 y2>`
4. `<rect>` rounded corners: `rx`/`ry` attributes are now passed through to `love.graphics.rectangle`
5. LOVE 12 stencil fix: replaced removed `love.graphics.stencil()`/`setStencilTest()` calls with polygon fill fallback

Since these features had not been tested with a wider variety of SVG icons, I decided not to create a pull request for the original library (I didn't want to be responsible for broken icons).

Licensed under [GPL-3.0-or-later](COPYING). See [THIRD-PARTY-NOTICES](THIRD-PARTY-NOTICES) for bundled library licenses.
