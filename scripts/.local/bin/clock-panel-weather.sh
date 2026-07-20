#!/usr/bin/env bash
set -euo pipefail

curl -fsS --max-time 4 'https://wttr.in/?format=j1' | python3 -c '
import datetime as dt
import json
import sys

try:
    data = json.load(sys.stdin)
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
    }
    return aliases.get(text.lower(), text[:9])

now_hour = dt.datetime.now().hour
hourlies = []
for day in days[:2]:
    for hour in day.get("hourly", []):
        raw_time = int(hour.get("time", "0") or 0)
        hour_24 = raw_time // 100
        if len(hourlies) == 0 and hour_24 < now_hour and day is days[0]:
            continue
        hourlies.append((hour_24, hour))

forecast = hourlies[:4]
current_desc = desc(current)
temp = current.get("temp_C", "?")
humidity = current.get("humidity", "?")
wind = current.get("windspeedKmph", "?")

print(f"󰖐 {current_desc}")
print(f" +{temp}° · 󰖎 {humidity}% · 󰖝 {wind}km/h")
if forecast:
    print("")
    print("󰅐 próximas horas")
    for hour, item in forecast:
        item_temp = item.get("tempC", "?")
        print(f"{hour:02d}h  +{item_temp}°  {short(desc(item))}")
'
