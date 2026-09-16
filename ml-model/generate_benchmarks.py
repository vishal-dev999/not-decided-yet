import json
import os
import pandas as pd

CSV_PATH = "data/price_history.csv"
OUTPUT_MOBILE_ASSET = "../mobile-app/assets/data/price_benchmarks.json"
OUTPUT_BACKEND_STATIC = "data/price_benchmarks.json"


def generate_benchmarks():
  if not os.path.exists(CSV_PATH):
    raise FileNotFoundError(f"Could not find {CSV_PATH}")

  df = pd.read_csv(CSV_PATH)
  df["date"] = pd.to_datetime(df["date"])

  latest_date = df["date"].max()
  latest_str = latest_date.strftime("%Y-%m-%d")

  benchmarks = {}
  materials_list = []

  # Calculate metrics per sub-category across the timeline
  for sub_cat, group in df.groupby("sub_category"):
    grp = group.sort_values("date").copy()
    latest_row = grp[grp["date"] == latest_date].iloc[0]

    # Prevailing Prices
    recycler_price = round(float(latest_row["recycler_offered_price"]), 2)
    mandi_price = round(float(latest_row["mandi_buying_price"]), 2)
    min_range = round(float(latest_row["market_range_min"]), 2)
    max_range = round(float(latest_row["market_range_max"]), 2)

    # Transparency Deltas
    direct_benefit_inr = round(recycler_price - mandi_price, 2)
    direct_benefit_pct = round((direct_benefit_inr / mandi_price) * 100, 1)

    # Momentum Math (7-day & 30-day change)
    unique_dates = grp["date"].drop_duplicates().sort_values()
    p_today = recycler_price

    p_7d_ago = (
        grp[grp["date"] == unique_dates.iloc[-8]]["recycler_offered_price"].iloc[
            0
        ]
        if len(unique_dates) >= 8
        else unique_dates.iloc[0]
    )
    p_30d_ago = (
        grp[grp["date"] == unique_dates.iloc[-31]][
            "recycler_offered_price"
        ].iloc[0]
        if len(unique_dates) >= 31
        else unique_dates.iloc[0]
    )

    trend_7d = round(((p_today - p_7d_ago) / p_7d_ago) * 100, 2)
    trend_30d = round(((p_today - p_30d_ago) / p_30d_ago) * 100, 2)

    trend_dir = "UP" if trend_7d > 0.5 else ("DOWN" if trend_7d < -0.5 else "STABLE")

    # 7-day sparkline coordinates for micro-charts
    sparkline = (
        grp.tail(7)["recycler_offered_price"].round(1).astype(float).tolist()
    )

    material_data = {
        "sub_category": sub_cat,
        "display_name": sub_cat.replace("_", " "),
        "material_category": latest_row["material_category"],
        "unit": latest_row["unit"],
        "recycler_price": recycler_price,
        "mandi_price": mandi_price,
        "direct_benefit_inr": direct_benefit_inr,
        "direct_benefit_pct": direct_benefit_pct,
        "market_range_min": min_range,
        "market_range_max": max_range,
        "trend_7d_pct": trend_7d,
        "trend_30d_pct": trend_30d,
        "trend_direction": trend_dir,
        "sparkline_7d": sparkline,
    }

    benchmarks[sub_cat] = material_data
    materials_list.append(material_data)

  payload = {
      "version": "2026.07.W4",
      "last_updated": latest_str,
      "cluster_reference": "Bhubaneswar-Cuttack Cluster",
      "benchmarks": benchmarks,
      "materials": materials_list,
  }

  for path in [OUTPUT_BACKEND_STATIC, OUTPUT_MOBILE_ASSET]:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
      json.dump(payload, f, indent=2)
    print(f"Exported price benchmarks to: {path}")


if __name__ == "__main__":
  generate_benchmarks()
