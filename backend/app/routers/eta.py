from fastapi import APIRouter, HTTPException
from app.schemas.eta import ETARequest, ETAResponse
from app.services.ml_service import ml_service
from app.utils.logger import setup_logger

logger = setup_logger("eta_router")
router = APIRouter(prefix="/api/v1", tags=["ETA Prediction"])


@router.post("/predict-eta", response_model=ETAResponse)
async def predict_eta(request: ETARequest):
    """
    Predict delivery time for an order.
    Used by Flutter app to show estimated delivery time.
    """
    try:
        result = ml_service.predict_eta(
            distance_km=request.distance_km,
            preparation_time_min=request.preparation_time_min,
            weather=request.weather,
            traffic_level=request.traffic_level,
            time_of_day=request.time_of_day,
            vehicle_type=request.vehicle_type
        )

        logger.info(
            f"ETA: {request.distance_km}km, "
            f"{request.traffic_level} traffic → "
            f"{result['eta_minutes']} min"
        )

        return ETAResponse(success=True, **result)

    except Exception as e:
        logger.error(f"ETA prediction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))