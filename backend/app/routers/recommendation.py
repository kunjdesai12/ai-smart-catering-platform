from fastapi import APIRouter, HTTPException
from app.schemas.recommendation import RecommendationRequest
from app.services.ml_service import ml_service
from app.utils.logger import setup_logger

logger = setup_logger("recommendation_router")
router = APIRouter(prefix="/api/v1", tags=["Recommendations"])


@router.post("/recommend")
async def recommend_restaurants(request: RecommendationRequest):
    try:
        result = ml_service.recommend(
            cuisine_query=request.cuisine,
            budget_per_person=request.budget_per_person,
            num_people=request.num_people,
            min_rating=request.min_rating,
            top_n=request.top_n,
            city=request.city,
            country=request.country
        )

        logger.info(
            f"Recommendation: '{request.cuisine}', "
            f"{request.num_people} people, "
            f"₹{request.budget_per_person}/person, "
            f"city={request.city} → "
            f"{len(result['recommendations'])} results"
        )

        return {'success': True, **result}

    except Exception as e:
        logger.error(f"Recommendation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))