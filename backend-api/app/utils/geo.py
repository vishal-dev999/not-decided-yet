from math import asin, cos, radians, sin, sqrt
from typing import Optional


def haversine_km(
    lat1: Optional[float],
    lon1: Optional[float],
    lat2: Optional[float],
    lon2: Optional[float],
) -> float:
    if None in (lat1, lon1, lat2, lon2):
        return 999.0
    r = 6371.0
    dlat = radians(lat2 - lat1)  # type: ignore[operator]
    dlon = radians(lon2 - lon1)  # type: ignore[operator]
    a = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2  # type: ignore[arg-type]
    )
    return 2 * r * asin(sqrt(a))
