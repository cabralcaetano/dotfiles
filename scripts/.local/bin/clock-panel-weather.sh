#!/usr/bin/env bash
set -euo pipefail

if ! payload="$(curl -fsS --max-time 4 'https://wttr.in/?format=j1')"; then
  printf '󰖐 Tempo indisponível\n'
  exit 0
fi

python3 -c '
import datetime as dt
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    current = data["current_condition"][0]
    days = data["weather"]
except Exception:
    print("󰖐 Tempo indisponível")
    raise SystemExit(0)

def desc(item):
    values = item.get("weatherDesc") or []
    if values and values[0].get("value"):
        return values[0]["value"].strip()
    return "—"

def short(text):
    text = text.strip()
    aliases = {
        "partly cloudy": "cloudy",
        "light rain": "rain",
        "moderate rain": "rain",
        "overcast": "cloudy",
        "mist": "fog",
    }
    return aliases.get(text.lower(), text[:12])

def temp_value(item):
    raw = item.get("tempC") or item.get("temp_C") or "?"
    try:
        return int(round(float(raw)))
    except Exception:
        return None

def signed_temp(value):
    if value is None:
        return "?°"
    return f"{value:+d}°"

def sparkline(values):
    blocks = "▁▂▃▄▅▆▇█"
    nums = [v for v in values if v is not None]
    if not nums:
        return " ".join("···" for _ in values)
    low = min(nums)
    high = max(nums)
    if low == high:
        return " ".join("▄▄▄" for _ in values)
    chars = []
    for value in values:
        if value is None:
            chars.append("·")
        else:
            idx = round((value - low) * (len(blocks) - 1) / (high - low))
            chars.append(blocks[idx])
    return " ".join(ch * 3 for ch in chars)

now_hour = dt.datetime.now().hour
hourlies = []
for day_index, day in enumerate(days[:2]):
    for hour in day.get("hourly", []):
        raw_time = int(hour.get("time", "0") or 0)
        hour_24 = raw_time // 100
        if day_index == 0 and hour_24 < now_hour:
            continue
        hourlies.append((hour_24, hour))

forecast = hourlies[:6]
current_desc = short(desc(current))
temp = temp_value(current)
humidity = current.get("humidity", "?")
wind = current.get("windspeedKmph", "?")

print(f"󰖐 {current_desc}")
print(f" {signed_temp(temp)}  ·  󰖎 {humidity}%  ·  󰖝 {wind}km/h")

if forecast:
    hours = [f"{hour:02d}" for hour, _ in forecast]
    temps = [temp_value(item) for _, item in forecast]
    print("󰅐 " + " ".join(hours) + "h")
    print(" " + " ".join(f"{value:+d}" if value is not None else " ?" for value in temps) + "°")
    print("   " + sparkline(temps))
' <<< "$payload"
