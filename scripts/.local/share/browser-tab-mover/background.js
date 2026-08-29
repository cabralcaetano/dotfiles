const MOVE_TO_PREFIX = 'move-to-';

chrome.commands.onCommand.addListener(async (command, tab) => {
  if (!tab?.id || tab.windowId === undefined || tab.index === undefined) return;

  try {
    if (command === 'move-left') {
      await chrome.tabs.move(tab.id, { index: Math.max(0, tab.index - 1) });
      return;
    }

    if (command === 'move-right') {
      await chrome.tabs.move(tab.id, { index: tab.index + 1 });
      return;
    }

    if (command.startsWith(MOVE_TO_PREFIX)) {
      const position = Number(command.slice(MOVE_TO_PREFIX.length));
      if (!Number.isInteger(position) || position < 1) return;
      await chrome.tabs.move(tab.id, { index: position - 1 });
    }
  } catch (error) {
    console.warn('OMP Tab Mover failed:', error);
  }
});
