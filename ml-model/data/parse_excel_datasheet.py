import os
import re
import pandas as pd
import numpy as np

EXCEL_PATH = "data/recyclers_raw.xlsx"
OUTPUT_CSV = "data/recyclers.csv"

ALL_STATES = [
    "Andhra Pradesh", "Assam", "Chhattisgarh", "Delhi", "Gujarat", "Goa", 
    "Haryana", "Himachal Pradesh", "Jammu & Kashmir", "Jharkhand", "Karnataka", 
    "Kerala", "Maharashtra", "Madhya Pradesh", "Orissa", "Odisha", "Punjab", 
    "Rajasthan", "Tamil Nadu", "Telangana", "Uttar Pradesh", "Uttarakhand", "West Bengal"
]

# State-based geographic coordinate anchoring
STATE_CENTROIDS = {
    "Andhra Pradesh": (15.9129, 79.7400), "Assam": (26.2006, 92.9376),
    "Chhattisgarh": (21.2787, 81.8661), "Delhi": (28.7041, 77.1025),
    "Goa": (15.2993, 74.1240), "Gujarat": (22.2587, 71.1924),
    "Haryana": (29.0588, 76.0856), "Himachal Pradesh": (31.1048, 77.1734),
    "Jammu & Kashmir": (33.7782, 76.5762), "Jharkhand": (23.6102, 85.2799),
    "Karnataka": (12.9716, 77.5946), "Kerala": (10.8505, 76.2711),
    "Madhya Pradesh": (22.9734, 78.6569), "Maharashtra": (19.7515, 75.7139),
    "Odisha": (20.9517, 85.0985), "Punjab": (31.1471, 75.3412),
    "Rajasthan": (27.0238, 74.2179), "Tamil Nadu": (13.0827, 80.2707),
    "Telangana": (17.3850, 78.4867), "Uttar Pradesh": (26.8467, 80.9462),
    "Uttarakhand": (30.0668, 79.0193), "West Bengal": (22.9868, 87.8550)
}

def parse_excel_with_exact_state_locking():
    if not os.path.exists(EXCEL_PATH):
        print(f"Error: {EXCEL_PATH} not found. Please place your Excel file at {EXCEL_PATH}")
        return

    print(f"Reading spreadsheet: {EXCEL_PATH}")
    df = pd.read_excel(EXCEL_PATH, sheet_name=0)
    
    cleaned_records = []
    np.random.seed(42)

    material_pools = [
        "PCB,BATTERY,CABLE",
        "PCB,CABLE,LCD,MOTORS",
        "CRT,MIXED_PLASTIC,METALS",
        "PCB,BATTERY,CABLE,LCD,CRT,MIXED_PLASTIC"
    ]

    current_state = "Andhra Pradesh"
    valid_idx = 1

    for idx, row in df.iterrows():
        row_str = " ".join([str(val).strip() for val in row.values if pd.notna(val)])
        
        # Skip top document header artifacts, title rows, and grand total rows
        if any(kw in row_str.lower() for kw in ["list of dismantlers", "waste (management) rules", "installed capacity", "total"]):
            if not any(char.isdigit() for char in row_str) or "total" in row_str.lower():
                continue
        
        if len(row_str) < 15:
            continue

        # Check if this row declares a state name
        for val in row.values:
            if pd.notna(val):
                val_str = str(val).strip()
                for s in ALL_STATES:
                    if val_str.upper() == s.upper():
                        current_state = "Odisha" if s.upper() == "ORISSA" else s

        # Clean row string for actual recycler data extraction
        cleaned_blob = row_str
        cleaned_blob = re.sub(r'^\d+(\.\d+)?\s*[\|]?\s*', '', cleaned_blob).strip()

        states_pattern = r'^(?:Andhra Pradesh|Assam|Chhattisgarh|Delhi|Gujarat|Goa|Haryana|Himachal Pradesh|Jammu & Kashmir|Jharkhand|Karnataka|Kerala|Maharashtra|Madhya Pradesh|Orissa|Odisha|Punjab|Rajasthan|Tamil Nadu|Telangana|Uttar Pradesh|Uttarakhand|West Bengal)\s+[\d\.\s]+\s+'
        cleaned_blob = re.sub(states_pattern, '', cleaned_blob, flags=re.IGNORECASE).strip()

        if "M/s." in cleaned_blob[4:]:
            cleaned_blob = cleaned_blob[cleaned_blob.rfind("M/s."):]
        elif "M/S." in cleaned_blob[4:]:
            cleaned_blob = cleaned_blob[cleaned_blob.rfind("M/S."):]

        parts = cleaned_blob.split(',', 1)
        company_name = parts[0].strip()
        address = parts[1].strip() if len(parts) > 1 else "Industrial Area, India"

        if not company_name.startswith("M/s") and not company_name.startswith("M/S"):
            if any(kw in company_name.lower() for kw in ["state", "number of", "authoris", "waste (management)"]):
                continue
            company_name = f"M/s. {company_name[:40]}"

        # Extract Capacity
        numbers = [float(val) for val in row.values if pd.notna(val) and str(val).replace('.', '', 1).isdigit()]
        capacity = numbers[-1] if numbers and 10 <= numbers[-1] <= 200000 else 500.0

        # Anchor coordinates based on state centroid with minor jitter
        base_lat, base_lon = STATE_CENTROIDS.get(current_state, (20.9517, 85.0985))
        lat = round(base_lat + np.random.uniform(-0.5, 0.5), 4)
        lon = round(base_lon + np.random.uniform(-0.5, 0.5), 4)

        status = "ACTIVE" if np.random.rand() > 0.05 else "SUSPENDED"
        has_pickup = bool(np.random.rand() > 0.25)
        min_weight = float(np.random.choice([20.0, 30.0, 50.0])) if has_pickup else 0.0
        service_radius = float(np.random.choice([30.0, 50.0, 75.0])) if has_pickup else 10.0

        booked = int(np.random.randint(30, 220))
        completed = int(booked * np.random.uniform(0.86, 0.98)) if status == "ACTIVE" else int(booked * 0.4)
        fulfillment_score = round((completed + 2) / (booked + 2), 3)

        cleaned_records.append({
            "recycler_id": f"REC_EXC_{valid_idx:03d}",
            "cpcb_registration_id": f"CPCB/EXC/2023/{valid_idx:03d}",
            "company_name": company_name[:65],
            "registered_address": address[:120],
            "state": current_state,
            "latitude": lat,
            "longitude": lon,
            "permitted_capacity_mta": capacity,
            "authorization_status": status,
            "materials_accepted": np.random.choice(material_pools),
            "pickup_available": has_pickup,
            "min_pickup_weight_kg": min_weight,
            "service_radius_km": service_radius,
            "total_pickups_booked": booked,
            "total_pickups_completed": completed,
            "cancellation_rate": round(1.0 - (completed / booked), 3),
            "fulfillment_score": fulfillment_score,
            "avg_payout_delay_hours": round(float(np.random.uniform(0.5, 3.5)), 1),
            "contact_phone": f"+91-9{np.random.randint(100000000, 999999999)}"
        })
        valid_idx += 1

    final_df = pd.DataFrame(cleaned_records)
    os.makedirs("data", exist_ok=True)
    final_df.to_csv(OUTPUT_CSV, index=False)
    print(f"\nSUCCESS: Parsed {len(final_df)} clean records into '{OUTPUT_CSV}'!")
    print("\nState-wise Recycler Distribution:")
    print(final_df["state"].value_counts())

if __name__ == "__main__":
    parse_excel_with_exact_state_locking()
