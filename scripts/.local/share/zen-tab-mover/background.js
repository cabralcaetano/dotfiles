const SHORTCUTS = {
  "move-up": "Alt+Shift+K",
  "move-down": "Alt+Shift+J",
};

const BACKWARD_COMMANDS = new Set(["move-up"]);
const FORWARD_COMMANDS = new Set(["move-down"]);

async function configureShortcuts() {
  if (!browser.commands?.update) return;

  for (const [name, shortcut] of Object.entries(SHORTCUTS)) {
    try {
      await browser.commands.update({ name, shortcut });
    } catch (error) {
      console.warn(`Tab Shifter could not set ${name} to ${shortcut}:`, error);
    }
  }
}

async function moveActiveTab(command, tab) {
  if (!tab?.id || typeof tab.index !== "number") return;

  if (BACKWARD_COMMANDS.has(command)) {
    await browser.tabs.move(tab.id, { index: Math.max(0, tab.index - 1) });
    return;
  }

  if (FORWARD_COMMANDS.has(command)) {
    await browser.tabs.move(tab.id, { index: tab.index + 1 });
  }
}

browser.runtime.onInstalled.addListener(configureShortcuts);
browser.runtime.onStartup.addListener(configureShortcuts);
configureShortcuts();

browser.commands.onCommand.addListener((command, tab) => {
  moveActiveTab(command, tab).catch((error) => {
    console.warn("Tab Shifter failed:", error);
  });
});
