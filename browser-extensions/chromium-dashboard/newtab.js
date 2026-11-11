const DEFAULT_SETTINGS = {
  city: "",
  githubUser: "cabralcaetano",
  nextdnsProfile: "932497",
  nextdnsApiKey: ""
};

const WEATHER_CODES = new Map([
  [0, "Céu limpo"], [1, "Predominantemente limpo"], [2, "Parcialmente nublado"], [3, "Nublado"],
  [45, "Neblina"], [48, "Neblina com geada"], [51, "Garoa leve"], [53, "Garoa"], [55, "Garoa forte"],
  [61, "Chuva leve"], [63, "Chuva"], [65, "Chuva forte"], [71, "Neve leve"], [73, "Neve"], [75, "Neve forte"],
  [80, "Pancadas leves"], [81, "Pancadas de chuva"], [82, "Pancadas fortes"], [95, "Trovoadas"],
  [96, "Trovoadas com granizo"], [99, "Trovoadas fortes"]
]);

const $ = (selector) => document.querySelector(selector);
const formatNumber = new Intl.NumberFormat("pt-BR");
let settings = { ...DEFAULT_SETTINGS };

function updateClock() {
  const now = new Date();
  const hour = now.getHours();
  $("#clock").textContent = now.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" });
  $("#date").textContent = now.toLocaleDateString("pt-BR", { weekday: "long", day: "2-digit", month: "long", year: "numeric" });
  $("#greeting").textContent = hour < 12 ? "BOM DIA" : hour < 18 ? "BOA TARDE" : "BOA NOITE";
}


async function updateBrowsingStats() {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const [historyItems, topSites] = await Promise.all([
      chrome.history.search({ text: "", startTime: start.getTime(), maxResults: 10000 }),
      chrome.topSites.get()
    ]);
    $("#history-count").textContent = formatNumber.format(historyItems.length);

    const container = $("#top-sites");
    container.replaceChildren(...topSites.slice(0, 6).map((site) => {
      const link = document.createElement("a");
      link.className = "site-chip";
      link.href = site.url;
      link.textContent = site.title || new URL(site.url).hostname;
      link.title = site.url;
      return link;
    }));
  } catch (error) {
    $("#top-sites").innerHTML = '<p class="card-footnote">Dados de navegação indisponíveis.</p>';
    console.error("Browsing stats failed", error);
  }
}

async function updateNextDns() {
  const profile = settings.nextdnsProfile.trim();
  const apiKey = settings.nextdnsApiKey.trim();
  if (!profile || !apiKey) {
    $("#nextdns-empty").hidden = false;
    $("#nextdns-content").hidden = true;
    return;
  }

  try {
    const baseUrl = `https://api.nextdns.io/profiles/${encodeURIComponent(profile)}/analytics`;
    const headers = { "X-Api-Key": apiKey, Accept: "application/json" };
    const [statusResponse, domainsResponse] = await Promise.all([
      cachedFetch(`nextdns_status_${profile}`, `${baseUrl}/status?from=-1d`, 5 * 60 * 1000, headers),
      cachedFetch(`nextdns_domains_${profile}`, `${baseUrl}/domains?from=-1d&status=blocked&limit=3`, 5 * 60 * 1000, headers)
    ]);
    const statuses = statusResponse.data || [];
    const total = statuses.reduce((sum, item) => sum + item.queries, 0);
    const blocked = statuses.find((item) => item.status === "blocked")?.queries || 0;
    const blockedRate = total ? (blocked / total) * 100 : 0;

    $("#nextdns-queries").textContent = formatNumber.format(total);
    $("#nextdns-blocked").textContent = formatNumber.format(blocked);
    $("#nextdns-rate").textContent = `${blockedRate.toFixed(1)}%`;
    $("#nextdns-domains").replaceChildren(...(domainsResponse.data || []).map((item) => {
      const row = document.createElement("div");
      row.className = "blocked-domain";
      const domain = document.createElement("span");
      domain.textContent = item.domain;
      const queries = document.createElement("strong");
      queries.textContent = formatNumber.format(item.queries);
      row.append(domain, queries);
      return row;
    }));
    $("#nextdns-status").textContent = "ONLINE";
    $("#nextdns-empty").hidden = true;
    $("#nextdns-content").hidden = false;
  } catch (error) {
    $("#nextdns-empty p").textContent = "Não foi possível acessar o NextDNS. Confira o ID do perfil e a API key.";
    $("#nextdns-empty").hidden = false;
    $("#nextdns-content").hidden = true;
    $("#nextdns-status").textContent = "ERRO";
    console.error("NextDNS data failed", error);
  }
}

async function cachedFetch(key, url, maxAgeMs, headers = {}) {
  const stored = await chrome.storage.local.get(key);
  const cached = stored[key];
  if (cached && Date.now() - cached.savedAt < maxAgeMs) return cached.data;

  const response = await fetch(url, { headers });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const data = await response.json();
  await chrome.storage.local.set({ [key]: { savedAt: Date.now(), data } });
  return data;
}

async function updateGitHub() {
  const user = settings.githubUser.trim();
  $("#github-login").textContent = `@${user}`;
  $("#github-profile").href = `https://github.com/${encodeURIComponent(user)}`;
  try {
    const cachePrefix = `github_${user.toLowerCase()}`;
    const [profile, events] = await Promise.all([
      cachedFetch(`${cachePrefix}_profile`, `https://api.github.com/users/${encodeURIComponent(user)}`, 30 * 60 * 1000),
      cachedFetch(`${cachePrefix}_events`, `https://api.github.com/users/${encodeURIComponent(user)}/events/public?per_page=100`, 15 * 60 * 1000)
    ]);
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const recentEvents = events.filter((event) => new Date(event.created_at).getTime() >= sevenDaysAgo);
    $("#github-repos").textContent = formatNumber.format(profile.public_repos);
    $("#github-followers").textContent = formatNumber.format(profile.followers);
    $("#github-events").textContent = formatNumber.format(recentEvents.length);
    $("#github-detail").textContent = profile.bio || `Atividade pública de ${profile.name || user}`;
  } catch (error) {
    $("#github-detail").textContent = "Não foi possível carregar o GitHub agora.";
    console.error("GitHub data failed", error);
  }
}

async function resolveCity(city) {
  const query = encodeURIComponent(city.trim());
  const url = `https://geocoding-api.open-meteo.com/v1/search?name=${query}&count=1&language=pt&format=json`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const data = await response.json();
  if (!data.results?.length) throw new Error("Cidade não encontrada");
  return data.results[0];
}

async function updateWeather() {
  const city = settings.city.trim();
  if (!city) {
    $("#weather-empty").hidden = false;
    $("#weather-content").hidden = true;
    $("#weather-place").textContent = "Cidade não definida";
    return;
  }

  try {
    const location = await cachedFetch(`weather_location_${city.toLowerCase()}`, `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=1&language=pt&format=json`, 30 * 24 * 60 * 60 * 1000);
    if (!location.results?.length) throw new Error("Cidade não encontrada");
    const place = location.results[0];
    const weatherUrl = `https://api.open-meteo.com/v1/forecast?latitude=${place.latitude}&longitude=${place.longitude}&current=temperature_2m,apparent_temperature,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=1`;
    const weather = await cachedFetch(`weather_forecast_${place.latitude}_${place.longitude}`, weatherUrl, 10 * 60 * 1000);

    $("#weather-place").textContent = `${place.name}${place.admin1 ? `, ${place.admin1}` : ""}`;
    $("#weather-temp").textContent = `${Math.round(weather.current.temperature_2m)}°`;
    $("#weather-description").textContent = WEATHER_CODES.get(weather.current.weather_code) || "Condição atual";
    $("#weather-feels").textContent = `Sensação ${Math.round(weather.current.apparent_temperature)}°`;
    $("#weather-max").textContent = `${Math.round(weather.daily.temperature_2m_max[0])}°`;
    $("#weather-min").textContent = `${Math.round(weather.daily.temperature_2m_min[0])}°`;
    $("#weather-rain").textContent = `${weather.daily.precipitation_probability_max[0] ?? 0}%`;
    $("#weather-empty").hidden = true;
    $("#weather-content").hidden = false;
    $("#weather-status").classList.add("active");
  } catch (error) {
    $("#weather-place").textContent = city;
    $("#weather-empty p").textContent = "Não foi possível carregar essa cidade. Confira o nome nas configurações.";
    $("#weather-empty").hidden = false;
    $("#weather-content").hidden = true;
    console.error("Weather data failed", error);
  }
}

function openSettings() {
  $("#city").value = settings.city;
  $("#github-user").value = settings.githubUser;
  $("#nextdns-profile").value = settings.nextdnsProfile;
  $("#nextdns-api-key").value = settings.nextdnsApiKey;
  $("#settings-error").textContent = "";
  $("#settings-dialog").showModal();
}

async function saveSettings(event) {
  const submitter = event.submitter;
  if (!submitter || submitter.value === "cancel") return;
  event.preventDefault();

  const city = $("#city").value.trim();
  const githubUser = $("#github-user").value.trim();
  const nextdnsProfile = $("#nextdns-profile").value.trim();
  const nextdnsApiKey = $("#nextdns-api-key").value.trim();
  if (!githubUser || !/^[a-z\d](?:[a-z\d-]{0,37}[a-z\d])?$/i.test(githubUser)) {
    $("#settings-error").textContent = "Informe um usuário válido do GitHub.";
    return;
  }
  if (!nextdnsProfile && nextdnsApiKey) {
    $("#settings-error").textContent = "Informe o ID do perfil NextDNS.";
    return;
  }
  if (city) {
    try {
      await resolveCity(city);
    } catch {
      $("#settings-error").textContent = "Cidade não encontrada. Tente incluir o estado.";
      return;
    }
  }

  const previousNextDnsProfile = settings.nextdnsProfile;
  settings = { city, githubUser, nextdnsProfile, nextdnsApiKey };
  await chrome.storage.local.set({ settings });
  await chrome.storage.local.remove([
    `nextdns_status_${previousNextDnsProfile}`,
    `nextdns_domains_${previousNextDnsProfile}`,
    `nextdns_status_${nextdnsProfile}`,
    `nextdns_domains_${nextdnsProfile}`
  ]);
  $("#settings-dialog").close();
  await Promise.all([updateWeather(), updateGitHub(), updateNextDns()]);
}

async function initialize() {
  const stored = await chrome.storage.local.get("settings");
  settings = { ...DEFAULT_SETTINGS, ...stored.settings };

  updateClock();
  setInterval(updateClock, 1000);
  $("#open-bookmarks").addEventListener("click", async (event) => {
    event.preventDefault();
    await chrome.tabs.update({ url: "chrome://bookmarks/" });
  });
  $("#open-settings").addEventListener("click", openSettings);
  $("#configure-weather").addEventListener("click", openSettings);
  $("#configure-nextdns").addEventListener("click", openSettings);
  $("#settings-form").addEventListener("submit", saveSettings);

  await Promise.allSettled([updateBrowsingStats(), updateGitHub(), updateWeather(), updateNextDns()]);
}

initialize().catch((error) => console.error("Dashboard initialization failed", error));
