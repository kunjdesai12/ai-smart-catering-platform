from pydantic import BaseModel, Field
from typing import Dict


class DemandRequest(BaseModel):
    restaurant_id: int = Field(..., description="Restaurant ID")
    day_of_week: int = Field(..., ge=0, le=6, description="0=Monday, 6=Sunday")
    hour_of_day: int = Field(..., ge=0, le=23, description="Hour 0-23")
    is_weekend: int = Field(..., ge=0, le=1, description="1=Weekend, 0=Weekday")
    holiday: int = Field(0, ge=0, le=1, description="1=Holiday, 0=Normal")
    restaurant_rating: float = Field(..., ge=0, le=5, description="Rating 0-5")
    price_range: int = Field(..., ge=1, le=4, description="Price range 1-4")

    model_config = {"json_schema_extra": {
        "examples": [{
            "restaurant_id": 285,
            "day_of_week": 5,
            "hour_of_day": 19,
            "is_weekend": 1,
            "holiday": 0,
            "restaurant_rating": 4.2,
            "price_range": 3
        }]
    }}


class DemandResponse(BaseModel):
    success: bool = True
    predicted_orders: int
    confidence: float
    model_rmse: float
    peak_status: str
    features_used: Dict