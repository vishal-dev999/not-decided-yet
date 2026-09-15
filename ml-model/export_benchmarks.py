import json
import os
from datetime import datetime
import pandas as pd

# Paths
CSV_PATH = "data/price_history.csv"
OUTPUT_MOBILE_ASSET = "../mobile-app/assets/data/price_benchmarks.json"
OUTPUT_LOCAL_COPY = "data/price_benchmarks.json"

def generate_price_benchmarks():
    if not os.path.exists(CSV_PATH):
        raise FileNotFoundError(f"Missing {CSV_PATH}. Ensure the dataset is present.")

    df = pd.read_csv(CSV_PATH)

    # 1. Filter for the latest reporting date
    latest_date = df["date"].max()
    latest_df = df[df["date"] == latest_date]

    print(f"Aggregating latest price benchmarks for date: {latest_date}")

    # 2. Compute category benchmark dictionary
    benchmarks = {}
    
    # Calculate 30-day price trend for each sub_category
    date_30d_ago = (pd.to_datetime(latest_date) - pd.Timedelta(days=30)).strftime("%Y-%m-%d")
    past_df = df[df["date"] >= date_30d_ago]

    grouped = latest_df.groupby(["sub_category", "material_category", "unit"])
    for (sub_cat, cat, unit), group in grouped:
        avg_mandi = round(float(group["mandi_buying_price"].mean()), 2)
        avg_recycler = round(float(group["recycler_offered_price"].mean()), 2)
        min_market = round(float(group["market_range_min"].min()), 2)
        max_market = round(float(group["market_range_max"].max()), 2)

        # Basic 30-day percentage trend calculation
        sub_past = past_df[past_df["sub_category"] == sub_cat]
        oldest_price = sub_past.sort_values("date").iloc[0]["recycler_offered_price"]
        trend_pct = round(((avg_recycler - oldest_price) / oldest_price) * 100, 1)

        benchmarks[sub_cat] = {
            "material_category": cat,
            "unit": unit,
            "mandi_buying_price": avg_mandi,
            "recycler_offered_price": avg_recycler,
            "market_range_min": min_market,
            "market_range_max": max_market,
            "trend_30d_pct": trend_pct,
            "trend_direction": "UP" if trend_pct > 0 else ("DOWN" if trend_pct < 0 else "STABLE"),
        }

    payload = {
        "version": "2026.07.W4",
        "last_updated": latest_date,
        "source_records": len(latest_df),
        "benchmarks": benchmarks,
    }

    # 3. Save to local data folder and directly to Flutter assets
    for target_path in [OUTPUT_LOCAL_COPY, OUTPUT_MOBILE_ASSET]:
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)
        print(f"Successfully exported benchmarks to: {target_path}")

if __name__ == "__main__":
    generate_price_benchmarks()
