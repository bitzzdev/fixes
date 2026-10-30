Claude Code CLI on Android (Termux) Workaround

«Tested with: Claude Code v2.1.47

Newer versions of "@anthropic-ai/claude-code" no longer include the JavaScript CLI ("cli.js") and currently do not work natively in Termux. This guide explains how to install a compatible version that works on Android.»

Prerequisites

- Termux
- Node.js 22 or newer
- npm
- Internet connection
- A Claude account (Pro, Max, Team, Enterprise) or an Anthropic Console API account

---

1. Update Termux

pkg update && pkg upgrade -y

---

2. Install Node.js and Git

pkg install nodejs git -y

Verify the installation:

node -v
npm -v

---

3. Install the Compatible Claude Code Version

Do not install the latest version.

Install v2.1.47 instead:

npm install -g @anthropic-ai/claude-code@2.1.47

---

4. Verify the Installation

Check that "cli.js" exists:

ls $(npm root -g)/@anthropic-ai/claude-code

You should see something similar to:

LICENSE.md
README.md
cli.js
package.json
vendor
...

---

5. Test the CLI

Run:

node $(npm root -g)/@anthropic-ai/claude-code/cli.js --version

Expected output:

2.1.47 (Claude Code)

You can also use the globally installed command:

claude --version

or

claude -v

---

6. Start Claude Code

Launch Claude Code:

claude

The first launch will display a login screen.

Choose one of:

1. Claude subscription (Pro, Max, Team, Enterprise)
2. Anthropic Console API
3. Third-party provider (Bedrock, Vertex AI, Microsoft Foundry)

Complete authentication in your browser.

---

Updating

Avoid running:

npm install -g @anthropic-ai/claude-code

This installs the newest release, which currently does not work in Termux.

Instead, always pin the version:

npm install -g @anthropic-ai/claude-code@2.1.47

---

Why This Works

Older releases of Claude Code shipped a JavaScript entry point ("cli.js"), allowing the CLI to run directly with Node.js.

Starting with newer releases, Anthropic switched to platform-specific native binaries. Those binaries target desktop Linux, macOS, and Windows, but not Android/Termux.

Version 2.1.47 still includes the JavaScript CLI, making it compatible with Termux.

---

Troubleshooting

"Cannot find module .../cli.js"

You installed a newer version.

Reinstall the compatible version:

npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code@2.1.47

---

"claude: command not found"

Check whether npm installed the global executable:

which claude

If nothing is returned, reinstall the package:

npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code@2.1.47

---

Check the installed version

claude --version

Expected output:

2.1.47 (Claude Code)

---

Known Limitations

- Only older JavaScript-based releases work natively in Termux.
- Do not upgrade unless Android support is officially added.
- Future authentication changes from Anthropic may affect older clients.

---

Tested Environment

- Android (Termux)
- Node.js v24.x
- npm
- Claude Code v2.1.47

---

License

Claude Code is developed and licensed by Anthropic. This document describes a community workaround for running a compatible version on Android via Termux.
