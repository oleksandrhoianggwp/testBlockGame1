# Airport economy
One global airport has seven zones and three purchases per zone.
Prices live in data/configs/economy.json.

| Zone | Stage 1 | Stage 2 | Stage 3 |
|---|---:|---:|---:|
| Entrance | 180 | 330 | 620 |
| Check-in | 200 | 360 | 680 |
| Baggage | 210 | 390 | 750 |
| Security | 200 | 380 | 720 |
| Cafe | 160 | 300 | 600 |
| Tower | 220 | 420 | 800 |
| Runway | 230 | 450 | 850 |

Before: 7 × (100+150+220) × (1+2+3+4+5) = 49350 coins.
After: 9050 coins total, no world multiplier.

Ordinary first clear is 40 + 10×stars + 20 = 80–90 at 2–3 stars.
Priority adds 15. Final Cafe adds 10 to first clears; Check-in adds 5 to
campaign clears. Undo/Reveal are one free charge per board; Tower adds one
Priority move. Entrance/Runway remain cosmetic/prestige rather than mandatory
gates. Purchases never lock campaign progress.

Reproducible economy_report.gd simulates all 75 first clears, alternating 3/2
stars, successful Priority objectives, cheapest available purchase order,
and no Daily, Shift or replay income. Results: 7375 coins including initial
200, 18 purchases, 86% of 21 visual stages, 725 coins remaining. Upgrade
levels: 1,2,4,7,9,12,15,18,22,26,30,35,40,45,51,57,63,69.
Overall frequency 4.17 levels/purchase. First purchases take about 2–3 clears;
middle stages around 4–5; final prestige stages around 6–9.

This is an estimate under a stated policy, not player telemetry. Daily first
clears and Shift banking provide optional additional income. No IAP is needed.

Migration takes the highest old stage in each zone. Old duplicate investment
above its replacement value is refunded. Less expensive old purchases are
grandfathered; coins, completions and boosters are not reduced.
