// ==UserScript==
// @name         YouTube SponsorBlock (local)
// @description  Pula automaticamente segmentos do banco do SponsorBlock (sponsor.ajay.app). Sem UI de envio/votos.
// @match        https://www.youtube.com/*
// @run-at       document-end
// ==/UserScript==
//
// Consulta a API pelo prefixo do SHA-256 do ID (4 hex), como a extensão oficial: o servidor não
// recebe o ID do vídeo. Só pula; não envia segmentos nem votos. Usa fetch da própria página
// (a API responde com Access-Control-Allow-Origin: *). Sem cookies, sem GM_*.

(function () {
  'use strict';

  const API = 'https://sponsor.ajay.app/api/skipSegments/';
  // Categorias puladas automaticamente (ver https://wiki.sponsor.ajay.app/w/Segment_Categories).
  const CATEGORIES = ['sponsor', 'selfpromo', 'interaction'];

  let currentId = null;
  let segments = [];

  async function hashPrefix(id) {
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(id));
    return Array.from(new Uint8Array(digest).slice(0, 2), (b) => b.toString(16).padStart(2, '0')).join('');
  }

  async function load(id) {
    segments = [];
    try {
      const url =
        API + (await hashPrefix(id)) +
        '?categories=' + encodeURIComponent(JSON.stringify(CATEGORIES)) +
        '&actionTypes=' + encodeURIComponent('["skip"]');
      const res = await fetch(url);
      if (!res.ok) return; // 404 = sem segmentos
      const entry = (await res.json()).find((v) => v.videoID === id);
      if (id !== currentId || !entry) return;
      segments = entry.segments.map((s) => s.segment).sort((a, b) => a[0] - b[0]);
    } catch (e) {
      console.warn('[sponsorblock-local]', e);
    }
  }

  setInterval(() => {
    const id = location.pathname === '/watch' ? new URLSearchParams(location.search).get('v') : null;
    if (id !== currentId) {
      currentId = id;
      segments = [];
      if (id) load(id);
    }
    if (!segments.length) return;

    const player = document.querySelector('#movie_player');
    const video = document.querySelector('#movie_player video.html5-main-video');
    if (!video || (player && player.classList.contains('ad-showing'))) return;

    const t = video.currentTime;
    const seg = segments.find((s) => t >= s[0] && t < s[1] - 0.15);
    if (seg) video.currentTime = seg[1];
  }, 200);
})();
