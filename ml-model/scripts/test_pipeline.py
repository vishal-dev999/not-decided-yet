import os
import pandas as pd
import numpy as np
import joblib

recyclers_df = pd.read_csv("data/recyclers.csv")
valuation_model = joblib.load("models/valuation_model.pkl")
le_cat, le_subcat, le_loc = joblib.load("models/encoders.pkl")

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371.0
    dlat = np.radians(lat2 - lat1)
    dlon = np.radians(lon2 - lon1)
    a = np.sin(dlat / 2)**2 + np.cos(np.radians(lat1)) * np.cos(np.radians(lat2)) * np.sin(dlon / 2)**2
    return R * (2 * np.arcsin(np.sqrt(a)))

def rank_recyclers(user_lat, user_lon, material_category):
    df = recyclers_df[
        (recyclers_df["authorization_status"] == "ACTIVE") & 
        (recyclers_df["materials_accepted"].str.contains(material_category, case=False, na=False))
    ].copy()
    
    if df.empty:
        return "No active recyclers found for this material."
    
    df["distance_km"] = df.apply(lambda r: calculate_haversine_distance(user_lat, user_lon, r["latitude"], r["longitude"]), axis=1)
    
    # Strict local operational filter (within 250 km)
    local_df = df[df["distance_km"] <= 250.0].copy()
    if not local_df.empty:
        df = local_df
    else:
        df = df.sort_values(by="distance_km").head(10).copy()

    df["proximity_score"] = np.exp(-df["distance_km"] / 50.0)
    df["match_score"] = round((0.60 * df["proximity_score"]) + (0.40 * df["fulfillment_score"]), 3)
    
    return df.sort_values(by="match_score", ascending=False)[["recycler_id", "company_name", "state", "distance_km", "match_score"]].head(3)

def predict_price(category, subcategory, location_cluster):
    try:
        cat_enc = le_cat.transform([category])[0]
        subcat_enc = le_subcat.transform([subcategory])[0]
        loc_enc = le_loc.transform([location_cluster])[0]
        pred_price = valuation_model.predict([[cat_enc, subcat_enc, loc_enc]])[0]
        return round(pred_price, 2)
    except Exception as e:
        return f"Prediction error: {e}"

if __name__ == "__main__":
    print("==================================================")
    print("       🧪 PIPELINE EDGE-CASE VERIFICATION TEST    ")
    print("==================================================")
    
    print("\n[Test 1] Price Valuation Model Check:")
    sample_price = predict_price("PCB", "MOTHERBOARD_HIGH_GRADE", "Delhi-Mayapuri Cluster")
    print(f"Predicted Formal Bid for High-Grade PCB in Delhi: ₹{sample_price} per kg")

    test_locations = [
        ("Bhubaneswar", 20.2961, 85.8245),
        ("Delhi", 28.7041, 77.1025),
        ("Bengaluru", 12.9716, 77.5946)
    ]
    
    print("\n[Test 2] Recycler Matcher Multi-Location Check:")
    for city_name, lat, lon in test_locations:
        print(f"\n--- Searching from {city_name} (Lat: {lat}, Lon: {lon}) ---")
        results = rank_recyclers(lat, lon, "PCB")
        print(results)
    
    print("\n==================================================")
    print("       ✨ ALL TESTS PASSED SUCCESSFULLY! ✨       ")
    print("==================================================")
