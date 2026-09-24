import os
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

OUTPUT_HISTORY = "data/price_history.csv"
OUTPUT_QUOTES = "data/price_quotes.csv"
os.makedirs("data", exist_ok=True)

np.random.seed(42)

# Core e-waste categories
categories = [
    ("PCB", "MOTHERBOARD_HIGH_GRADE", 300.0, 350.0),
    ("PCB", "POWER_SUPPLY_LOW_GRADE", 50.0, 68.0),
    ("CABLE", "COPPER_HEAVY_INSULATED", 440.0, 500.0),
    ("CABLE", "ALUMINIUM_WIRE", 115.0, 140.0),
    ("BATTERY", "LEad_ACID", 90.0, 110.0),
    ("BATTERY", "BATTERY_LITHIUM_PORTABLE", 130.0, 165.0),
    ("DISPLAY", "LCD_PANEL_INTACT", 160.0, 220.0),
    ("DISPLAY", "CRT_MONITOR", 20.0, 35.0),
    ("PLASTIC", "MIXED_EWASTE_CASING", 20.0, 30.0)
]

# Major economic hubs mapped to states where recyclers exist
hub_states = {
    "Delhi": "Delhi",
    "Mumbai": "Maharashtra",
    "Pune": "Maharashtra",
    "Nagpur": "Maharashtra",
    "Bengaluru": "Karnataka",
    "Mysuru": "Karnataka",
    "Chennai": "Tamil Nadu",
    "Coimbatore": "Tamil Nadu",
    "Hyderabad": "Telangana",
    "Ahmedabad": "Gujarat",
    "Surat": "Gujarat",
    "Kolkata": "West Bengal",
    "Lucknow": "Uttar Pradesh",
    "Noida": "Uttar Pradesh",
    "Kanpur": "Uttar Pradesh",
    "Bhubaneswar": "Odisha",
    "Cuttack": "Odisha",
    "Patna": "Bihar",
    "Jaipur": "Rajasthan",
    "Jodhpur": "Rajasthan",
    "Bhopal": "Madhya Pradesh",
    "Indore": "Madhya Pradesh",
    "Chandigarh": "Punjab",
    "Ludhiana": "Punjab",
    "Dehradun": "Uttarakhand",
    "Raipur": "Chhattisgarh",
    "Ranchi": "Jharkhand",
    "Guwahati": "Assam",
    "Thiruvananthapuram": "Kerala",
    "Panaji": "Goa",
    "Jammu": "Jammu & Kashmir",
    "Shimla": "Himachal Pradesh"
}

start_date = datetime(2026, 5, 1)
history_records = []
quote_records = []

# Generate 90 days of price history
for day_offset in range(90):
    current_date = start_date + timedelta(days=day_offset)
    date_str = current_date.strftime("%Y-%m-%d")
    market_drift = np.sin(day_offset / 12.0 * np.pi) * 8.0 + np.random.normal(0, 1.2)

    for city, state in hub_states.items():
        # Add slight regional variance based on city hash
        city_bias = (hash(city) % 15) - 7
        
        for cat, subcat, base_buy, base_max in categories:
            buy_rate = round(max(base_buy * 0.7, base_buy + market_drift + city_bias), 2)
            
            history_records.append({
                "material_code": subcat,
                "city": city,
                "as_of": date_str,
                "buy_rate_per_kg": buy_rate
            })

            # Keep latest day for price_quotes table
            if day_offset == 89:
                quote_records.append({
                    "material_code": subcat,
                    "city": city,
                    "state": state,
                    "buy_rate_per_kg": buy_rate,
                    "min_rate": round(buy_rate * 0.88, 2),
                    "max_rate": round(buy_rate * 1.15, 2),
                    "source": "cpcb-national-mandi-index",
                    "updated_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
                })

df_history = pd.DataFrame(history_records)
df_history.to_csv(OUTPUT_HISTORY, index=False)

df_quotes = pd.DataFrame(quote_records)
df_quotes.to_csv(OUTPUT_QUOTES, index=False)

print(f"SUCCESS: Generated {len(df_history)} history records and {len(df_quotes)} active market quotes across {len(hub_states)} regional hubs!")
