from pydantic import BaseModel, Field
from typing import List, Dict, Optional


class RecommendationRequest(BaseModel):
    cuisine: str = Field(..., description="Cuisine preference")
    budget_per_person: float = Field(..., gt=0, description="Budget per person in INR")
    num_people: int = Field(..., gt=0, le=5000, description="Number of guests")
    min_rating: float = Field(3.5, ge=0, le=5, description="Minimum rating")
    top_n: int = Field(5, ge=1, le=50, description="Number of recommendations")
    city: Optional[str] = Field(None, description="City filter")
    country: Optional[str] = Field(None, description="Country filter")

    model_config = {"json_schema_extra": {
        "examples": [{
            "cuisine": "north indian",
            "budget_per_person": 500,
            "num_people": 50,
            "min_rating": 3.5,
            "top_n": 5,
            "city": "New Delhi",
            "country": "India"
        }]
    }}


class RestaurantRecommendation(BaseModel):
    restaurant_id: int
    name: str = ""
    cuisines: str
    primary_cuisine: str
    rating: float
    price_range: int
    estimated_cost: float
    cost_per_person: float
    city: str = "Unknown"
    country: str = "Unknown"
    match_score: float
    cuisine_match: float
    suggested_menu: List[str]


class RecommendationResponse(BaseModel):
    success: bool = True
    query: Dict
    total_matches: int
    recommendations: List[RestaurantRecommendation]