import os
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

OUTPUT_CSV = "data/price_history.csv"
os.makedirs("data", exist_ok=True)

np.random.seed(42)

# Core e-waste categories & base rates (₹/kg or ₹/piece)
categories = [
    ("PCB", "MOTHERBOARD_HIGH_GRADE", "KG", 280.0, 320.0),
    ("PCB", "POWER_SUPPLY_LOW_GRADE", "KG", 45.0, 60.0),
    ("CABLE", "COPPER_HEAVY_INSULATED", "KG", 420.0, 470.0),
    ("CABLE", "ALUMINIUM_WIRE", "KG", 110.0, 135.0),
    ("BATTERY", "LEAD_ACID", "KG", 85.0, 102.0),
    ("BATTERY", "BATTERY_LITHIUM_PORTABLE", "KG", 120.0, 150.0),
    ("DISPLAY", "LCD_PANEL_INTACT", "PIECE", 150.0, 210.0),
    ("DISPLAY", "CRT_MONITOR", "PIECE", 60.0, 90.0),
    ("PLASTIC", "MIXED_EWASTE_CASING", "KG", 18.0, 26.0)
]

# Major regional mandi clusters in India
clusters = [
    "Delhi-Mayapuri Cluster",
    "Mumbai-Dharavi Cluster",
    "Bengaluru-Peenya Cluster",
    "Bhubaneswar-Cuttack Cluster",
    "Chennai-Ambattur Cluster"
]

start_date = datetime(2026, 5, 1)
price_records = []
price_id_counter = 1

# Generate 90 days of historical price logs across regions
for day_offset in range(90):
    current_date = start_date + timedelta(days=day_offset)
    date_str = current_date.strftime("%Y-%m-%d")
    
    # Simulate market commodity price fluctuation using a sine wave + normal noise
    market_drift = np.sin(day_offset / 12.0) * 10.0 + np.random.normal(0, 1.5)

    for cluster in clusters:
        for cat, subcat, unit, base_mandi, base_formal in categories:
            # Mandi (informal) cash price vs Formal recycler offered price
            mandi_price = round(max(base_mandi * 0.65, base_mandi + market_drift), 2)
            formal_price = round(max(mandi_price + 8.0, base_formal + (market_drift * 1.1)), 2)
            
            price_records.append({
                "price_id": f"PRC_{price_id_counter:05d}",
                "date": date_str,
                "material_category": cat,
                "sub_category": subcat,
                "location_cluster": cluster,
                "mandi_buying_price": mandi_price,       # Spot cash rate for informal collectors
                "recycler_offered_price": formal_price,  # Authorized facility bid price
                "unit": unit,
                "market_range_min": round(mandi_price * 0.90, 2),
                "market_range_max": round(formal_price * 1.10, 2)
            })
            price_id_counter += 1

df_prices = pd.DataFrame(price_records)
df_prices.to_csv(OUTPUT_CSV, index=False)

print(f"SUCCESS: Generated {len(df_prices)} historical price records into '{OUTPUT_CSV}'!")
print(df_prices[["price_id", "date", "material_category", "sub_category", "mandi_buying_price", "recycler_offered_price"]].head(5))
