from pydantic import BaseModel, Field
from typing import Dict


class ETARequest(BaseModel):
    distance_km: float = Field(..., gt=0, le=50, description="Distance in km")
    preparation_time_min: float = Field(..., gt=0, le=60, description="Prep time in minutes")
    weather: str = Field("clear", description="clear/rainy/foggy/snowy/windy")
    traffic_level: str = Field("medium", description="low/medium/high")
    time_of_day: str = Field("evening", description="morning/afternoon/evening/night")
    vehicle_type: str = Field("bike", description="bike/scooter/car/bicycle")

    model_config = {"json_schema_extra": {
        "examples": [{
            "distance_km": 5.5,
            "preparation_time_min": 20,
            "weather": "clear",
            "traffic_level": "medium",
            "time_of_day": "evening",
            "vehicle_type": "bike"
        }]
    }}


class ETAResponse(BaseModel):
    success: bool = True
    eta_minutes: int
    confidence: float
    model_rmse: float
    breakdown: Dict