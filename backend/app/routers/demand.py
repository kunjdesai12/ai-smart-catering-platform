from fastapi import APIRouter, HTTPException
from app.schemas.demand import DemandRequest, DemandResponse
from app.services.ml_service import ml_service
from app.utils.logger import setup_logger

logger = setup_logger("demand_router")
router = APIRouter(prefix="/api/v1", tags=["Demand Prediction"])


@router.post("/predict-demand", response_model=DemandResponse)
async def predict_demand(request: DemandRequest):
    """
    Predict order demand for a restaurant at a specific time.
    Used by Flutter app to show demand forecast.
    """
    try:
        result = ml_service.predict_demand(
            restaurant_id=request.restaurant_id,
            day_of_week=request.day_of_week,
            hour_of_day=request.hour_of_day,
            is_weekend=request.is_weekend,
            holiday=request.holiday,
            restaurant_rating=request.restaurant_rating,
            price_range=request.price_range
        )

        logger.info(
            f"Demand: restaurant={request.restaurant_id}, "
            f"hour={request.hour_of_day} → "
            f"{result['predicted_orders']} orders"
        )

        return DemandResponse(success=True, **result)

    except Exception as e:
        logger.error(f"Demand prediction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict-demand-bulk")
async def predict_demand_bulk(request: DemandRequest):
    """
    Predict demand for ALL 24 hours for a restaurant.
    Returns full day forecast — used for demand chart in Flutter.
    """
    try:
        hourly_predictions = []

        for hour in range(24):
            is_weekend = 1 if request.day_of_week >= 5 else 0

            result = ml_service.predict_demand(
                restaurant_id=request.restaurant_id,
                day_of_week=request.day_of_week,
                hour_of_day=hour,
                is_weekend=is_weekend,
                holiday=request.holiday,
                restaurant_rating=request.restaurant_rating,
                price_range=request.price_range
            )

            hourly_predictions.append({
                'hour': hour,
                'predicted_orders': result['predicted_orders'],
                'peak_status': result['peak_status']
            })

        peak = max(
            hourly_predictions,
            key=lambda x: x['predicted_orders']
        )
        total = sum(
            p['predicted_orders'] for p in hourly_predictions
        )

        return {
            'success': True,
            'restaurant_id': request.restaurant_id,
            'day_of_week': request.day_of_week,
            'hourly_forecast': hourly_predictions,
            'peak_hour': peak['hour'],
            'peak_orders': peak['predicted_orders'],
            'total_day_orders': total,
            'best_time_to_order': (
                'Before 11 AM or after 9 PM for faster service'
                if peak['hour'] in [12, 13, 19, 20, 21]
                else f"Avoid hour {peak['hour']}:00"
            )
        }

    except Exception as e:
        logger.error(f"Bulk demand prediction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))