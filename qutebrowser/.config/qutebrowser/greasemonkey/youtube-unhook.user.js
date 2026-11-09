// ==UserScript==
// @name         YouTube unhook (local)
// @description  Equivalente local da extensão Unhook, com as mesmas opções ligadas no Chromium do usuário.
// @match        https://www.youtube.com/*
// @run-at       document-start
// ==/UserScript==
//
// Espelha o painel do Unhook (capturas de 2026-11-08). LIGADAS lá e aqui: End Screen Feed, End Screen
// Cards, Shorts, Merch/Tickets/Offers, Hide Notifications, Explore/Trending, More from YouTube,
// Subscriptions (item do menu), Disable Autoplay, Disable Annotations. DESLIGADAS lá e aqui: Home Feed,
// Video Sidebar (recomendados, chat, playlist), Comments, Mixes, Video Info, Top Header.
// NÃO replicado: "Hide Inapt Search Results" (o critério da extensão não é conhecido).
// Só CSS, cliques locais e redirecionamento /shorts/ID -> /watch?v=ID. Sem rede, sem cookies, sem GM_*.
// O YouTube troca nomes de elementos com frequência: se algo voltar a aparecer, ajustar os seletores.

(function () {
  'use strict';

  const hidden = [
    // End Screen Feed + Cards
    '.html5-endscreen',
    '.ytp-endscreen-content',
    '.ytp-ce-element',
    '.ytp-suggestion-set',
    '.ytp-videowall-still',
    // Annotations
    '.annotation',
    '.ytp-iv-video-content',
    // Shorts: prateleiras, entradas de menu, itens em resultados/canais
    'ytd-rich-section-renderer:has(ytd-rich-shelf-renderer[is-shorts])',
    'ytd-rich-shelf-renderer[is-shorts]',
    'ytd-reel-shelf-renderer',
    'ytd-guide-entry-renderer:has(a[title="Shorts"])',
    'ytd-mini-guide-entry-renderer[aria-label="Shorts"]',
    'ytd-mini-guide-entry-renderer:has([title="Shorts"])',
    'ytd-mini-guide-entry-renderer:has(a[href^="/shorts"])',
    'ytd-video-renderer:has(a[href^="/shorts/"])',
    'ytd-grid-video-renderer:has(a[href^="/shorts/"])',
    'ytd-rich-item-renderer:has(a[href^="/shorts/"])',
    'yt-tab-shape[tab-title="Shorts"]',
    // Merch, Tickets, Offers
    'ytd-merch-shelf-renderer',
    '#ticket-shelf',
    'ytd-ticket-shelf-renderer',
    // Notifications (sino do topo)
    'ytd-notification-topbar-button-renderer',
    // Menu: Subscriptions, Explore/Trending, More from YouTube
    'ytd-guide-entry-renderer:has(a[href="/feed/subscriptions"])',
    'ytd-mini-guide-entry-renderer:has(a[href="/feed/subscriptions"])',
    'ytd-guide-entry-renderer:has(a[href^="/feed/trending"])',
    'ytd-guide-entry-renderer:has(a[href^="/feed/explore"])',
    'ytd-guide-section-renderer:has(a[href^="/feed/storefront"])',
    'ytd-guide-section-renderer:has(a[href="/premium"])',
  ];

  const style = document.createElement('style');
  style.textContent = hidden.join(',\n') + ' { display: none !important; }';
  // No document-start o documentElement pode ainda não existir.
  const inject = () => document.documentElement.appendChild(style);
  if (document.documentElement) inject();
  else document.addEventListener('DOMContentLoaded', inject, { once: true });

  // Itens de menu cujo seletor muda por layout: esconde pelo texto.
  const labels = new Set(['Shorts', 'Subscriptions', 'Inscrições']);

  setInterval(() => {
    for (const e of document.querySelectorAll('ytd-mini-guide-entry-renderer, ytd-guide-entry-renderer')) {
      if (e.style.display !== 'none' && labels.has(e.innerText.trim())) e.style.display = 'none';
    }
    // Disable Autoplay: desliga o botão de autoplay do player
    const autoplay = document.querySelector('.ytp-autonav-toggle-button[aria-checked="true"]');
    if (autoplay) autoplay.click();
  }, 1000);

  function leaveShorts() {
    const m = location.pathname.match(/^\/shorts\/([\w-]+)/);
    if (m) location.replace('/watch?v=' + m[1]);
  }
  leaveShorts();
  window.addEventListener('yt-navigate-finish', leaveShorts);
})();
