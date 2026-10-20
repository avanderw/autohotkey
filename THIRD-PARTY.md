# Third-Party Components and Release Gates

## AutoHotkey

The executable embeds the AutoHotkey v2 runtime. The exact version and SHA-256
hash are recorded in build-info.json with each build. Its accompanying license
is included as AutoHotkey-license.txt in the ZIP and installation directory.

- Project: https://www.autohotkey.com/
- Source and version tags: https://github.com/AutoHotkey/AutoHotkey
- License information: https://www.autohotkey.com/docs/v2/license.htm

Before public distribution, review the runtime's redistribution terms, including
any corresponding-source obligations, and provide the required source materials
for the exact runtime version. Bundling the application's AHK source does not
by itself establish compliance for the runtime.

## Icon

The release icon is Lucide's bell-ring, selected for its reminder imagery.

- Project and preview: https://lucide.dev/icons/bell-ring
- Pinned source: https://raw.githubusercontent.com/lucide-icons/lucide/0.468.0/icons/bell-ring.svg
- Pinned license: https://raw.githubusercontent.com/lucide-icons/lucide/0.468.0/LICENSE
- License: ISC, with the upstream Feather/MIT attribution retained in ICON-LICENSE.txt.

check-in.svg is the upstream source; check-in.ico is its multi-resolution Windows
conversion, rendered in teal. ICON-LICENSE.txt must accompany redistributed
copies. The old file-text.ico is no longer a release input; other local scripts
may still use it.

## Application and Build Tools

The original application code and repository documentation are MIT licensed,
Copyright (c) 2026 Andrew van der Westhuizen. See LICENSE. Modification,
redistribution, and commercial use are permitted while retaining the copyright
and permission notice. No in-app credit screen is required by MIT.

This license does not replace the separate terms for the AutoHotkey runtime or
Lucide icon. Those components retain their upstream notices and licenses.

Ahk2Exe and Inno Setup are build tools, not bundled application dependencies.
Review their applicable terms; current Inno Setup versions request a commercial
license for commercial use. Do not include build-tool installers in releases.