// ==UserScript==
// @name         YouTube ad skip (local)
// @description  Pula o vídeo do anúncio, silencia durante ele e esconde banners de anúncio.
// @match        https://www.youtube.com/*
// @run-at       document-end
// ==/UserScript==
//
// Baseado no gist ShivangamSoni/91a4fcd938a4f3d4491559d019a60b7c (sem modo teatro,
// sem remoção de DOM, escopo só em www.youtube.com). Sem rede, sem cookies, sem GM_*.
// O YouTube muda o player com frequência: se parar de funcionar, ajustar os seletores.

(function () {
  'use strict';

  const style = document.createElement('style');
  style.textContent = `
    #masthead-ad,
    #player-ads,
    ytd-ad-slot-renderer,
    ytd-in-feed-ad-layout-renderer,
    ytd-statement-banner-renderer,
    ytd-display-ad-renderer,
    ytd-promoted-sparkles-web-renderer,
    ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-ads"],
    .ytp-ad-overlay-container,
    .ytp-ad-player-overlay-layout__player-card-container {
      display: none !important;
    }
  `;
  document.documentElement.appendChild(style);

  let mutedByUs = false;

  setInterval(() => {
    const player = document.querySelector('#movie_player');
    const video = document.querySelector('#movie_player video.html5-main-video');
    if (!player || !video) return;

    if (player.classList.contains('ad-showing')) {
      if (!video.muted) {
        video.muted = true;
        mutedByUs = true;
      }
      if (Number.isFinite(video.duration) && video.duration > 0) {
        video.currentTime = video.duration;
      }
      const skip = player.querySelector(
        '.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button'
      );
      if (skip) skip.click();
    } else if (mutedByUs) {
      video.muted = false;
      mutedByUs = false;
    }
  }, 250);
})();
