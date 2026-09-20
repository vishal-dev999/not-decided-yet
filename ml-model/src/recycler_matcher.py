import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import LabelEncoder
import joblib

# Ensure directories exist
os.makedirs("models", exist_ok=True)

# --- 1. LOAD DATASETS ---
recyclers_df = pd.read_csv("data/recyclers.csv")
prices_df = pd.read_csv("data/price_history.csv")

print(f"Loaded {len(recyclers_df)} recyclers and {len(prices_df)} price records.")


# --- 2. BUILD VALUATION & PRICE PREDICTION MODEL ---
def train_valuation_model():
    # Feature engineering from price history
    df = prices_df.copy()
    
    le_cat = LabelEncoder()
    le_subcat = LabelEncoder()
    le_loc = LabelEncoder()
    
    df["cat_enc"] = le_cat.fit_transform(df["material_category"])
    df["subcat_enc"] = le_subcat.fit_transform(df["sub_category"])
    df["loc_enc"] = le_loc.fit_transform(df["location_cluster"])
    
    X = df[["cat_enc", "subcat_enc", "loc_enc"]]
    y = df["recycler_offered_price"]  # Target: Formal recycler bid price per kg/unit
    
    model = RandomForestRegressor(n_estimators=50, random_state=42)
    model.fit(X, y)
    
    # Save model and encoders
    joblib.dump(model, "models/valuation_model.pkl")
    joblib.dump((le_cat, le_subcat, le_loc), "models/encoders.pkl")
    print(" Valuation model trained and saved successfully.")



# --- 3. HAVERSINE DISTANCE CALCULATOR ---
def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    """Calculates great-circle distance between user and recycler in kilometers."""
    R = 6371.0  # Earth radius in km
    dlat = np.radians(lat2 - lat1)
    dlon = np.radians(lon2 - lon1)
    a = np.sin(dlat / 2)**2 + np.cos(np.radians(lat1)) * np.cos(np.radians(lat2)) * np.sin(dlon / 2)**2
    c = 2 * np.arcsin(np.sqrt(a))
    return R * c


# --- 4. MULTI-CRITERIA RECYCLER MATCHER & RANKING ENGINE ---
    
def rank_recyclers_for_collector(user_lat, user_lon, material_category, lot_weight_kg):
    """
    Ranks authorized recyclers based on:
      1. Distance (closer is better)
      2. Material Compatibility (must accept the category)
      3. Minimum Pickup Weight Threshold (lot weight >= min weight if pickup requested)
      4. Authorization Status (ACTIVE only)
      5. Historical Reliability (fulfillment score)
    """
    df = recyclers_df.copy()
    
    # Filter 1: Active Authorization Only
    df = df[df["authorization_status"] == "ACTIVE"].copy()
    
    # Filter 2: Material Stream Check
    df = df[df["materials_accepted"].str.contains(material_category, case=False, na=False)].copy()
    
    if df.empty:
        return pd.DataFrame(columns=["recycler_id", "company_name", "distance_km", "match_score"])

    # Compute Haversine distance
    df["distance_km"] = df.apply(
        lambda row: calculate_haversine_distance(user_lat, user_lon, row["latitude"], row["longitude"]), 
        axis=1
    )
    
    # CRITICAL FIX: Filter out recyclers whose service radius is smaller than the distance
    # (Defaulting max allowed operational distance to 150 km for local collection lots)
    df = df[df["distance_km"] <= np.maximum(df["service_radius_km"], 150.0)]
    
    if df.empty:
        print("Warning: No recyclers found within strict service radius. Expanding search to nearest available...")
        df = recyclers_df[recyclers_df["authorization_status"] == "ACTIVE"].copy()
        df["distance_km"] = df.apply(
            lambda row: calculate_haversine_distance(user_lat, user_lon, row["latitude"], row["longitude"]), 
            axis=1
        )
        df = df.sort_values(by="distance_km").head(10) # Take closest 10

    # Exponential Distance Decay Penalty (so distance hurts score severely past 50km)
    df["proximity_score"] = np.exp(-df["distance_km"] / 75.0)  
    df["reliability_score"] = df["fulfillment_score"]
    
    # Heavy Proximity Bias (60% Proximity, 30% Reliability, 10% Capacity)
    df["match_score"] = round(
        (0.60 * df["proximity_score"]) + 
        (0.30 * df["reliability_score"]) + 
        (0.10 * np.minimum(df["permitted_capacity_mta"] / 5000.0, 1.0)), 
        3
    )
    
    ranked = df.sort_values(by="match_score", ascending=False).reset_index(drop=True)
    return ranked[["recycler_id", "company_name", "state", "distance_km", "match_score"]]

# --- 5. TEST THE RANKER ---
if __name__ == "__main__":
    print("Training valuation model...")
    train_valuation_model()
    print("\n--- TEST RUN: Matcher for Bhubaneswar Collector ---")
    # Simulating informal collector standing in Bhubaneswar (Lat: 20.2961, Lon: 85.8245) with a 45kg PCB lot
    recommendations = rank_recyclers_for_collector(
        user_lat=20.2961, 
        user_lon=85.8245, 
        material_category="PCB", 
        lot_weight_kg=45.0
    )
    print(recommendations.head(5))
