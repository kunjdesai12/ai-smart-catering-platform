from fastapi import APIRouter, HTTPException
from datetime import datetime
from typing import Optional
from app.services.ml_service import ml_service
from app.utils.logger import setup_logger

logger = setup_logger("health_router")
router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "models_loaded": ml_service._loaded
    }


@router.get("/model-info")
async def model_info():
    return {"status": "ok", "models": ml_service.get_model_info()}


@router.get("/api/v1/locations")
async def get_locations():
    try:
        hierarchy = ml_service.get_locations()
        countries = []
        for name, data in hierarchy.items():
            countries.append({
                'country': name,
                'total_restaurants': data['total_restaurants'],
                'total_cities': data['total_cities'],
                'cities': data['cities']
            })
        countries.sort(key=lambda x: x['total_restaurants'], reverse=True)
        return {'success': True, 'total_countries': len(countries), 'countries': countries}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/v1/cities")
async def get_cities(country: Optional[str] = None):
    try:
        df = ml_service.rec_restaurant_data
        if 'city' not in df.columns:
            return {'success': True, 'total': 0, 'cities': []}

        if country and 'country' in df.columns:
            df = df[df['country'].str.lower().str.strip() == country.lower().strip()]

        city_counts = df.groupby('city')['restaurant_id'].count().reset_index()
        city_counts.columns = ['city', 'restaurant_count']
        city_counts = city_counts.sort_values('restaurant_count', ascending=False)

        cities = []
        for _, row in city_counts.iterrows():
            city_name = str(row['city']).strip()
            if city_name and city_name.lower() not in ['nan', 'unknown', '', 'none']:
                cities.append({'city': city_name, 'restaurant_count': int(row['restaurant_count'])})

        return {'success': True, 'total': len(cities), 'cities': cities}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/v1/restaurants")
async def list_restaurants(city: Optional[str] = None, country: Optional[str] = None,
                           search: Optional[str] = None, limit: int = 50):
    try:
        df = ml_service.rec_restaurant_data.copy()

        if country and 'country' in df.columns:
            df = df[df['country'].str.lower().str.strip() == country.lower().strip()]
        if city and 'city' in df.columns:
            df = df[df['city'].str.lower().str.strip() == city.lower().strip()]
        if search:
            sl = search.lower()
            mask = df['cuisines'].str.lower().str.contains(sl, na=False)
            if 'restaurant_name' in df.columns:
                mask = mask | df['restaurant_name'].str.lower().str.contains(sl, na=False)
            df = df[mask]

        df = df.sort_values('aggregate_rating', ascending=False).head(limit)

        restaurants = []
        for _, row in df.iterrows():
            restaurants.append({
                'restaurant_id': int(row['restaurant_id']),
                'name': str(row.get('restaurant_name', f"Restaurant #{row['restaurant_id']}")),
                'cuisines': str(row.get('cuisines', 'Unknown')),
                'primary_cuisine': str(row.get('primary_cuisine', 'Unknown')),
                'rating': round(float(row.get('aggregate_rating', 3.5)), 1),
                'price_range': int(row.get('price_range', 2)),
                'city': str(row.get('city', 'Unknown')),
                'country': str(row.get('country', 'Unknown')),
                'average_cost_for_two': float(row.get('average_cost_for_two', 500)),
            })

        return {'success': True, 'total': len(restaurants), 'restaurants': restaurants}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/v1/restaurant/{restaurant_id}")
async def get_restaurant(restaurant_id: int):
    try:
        df = ml_service.rec_restaurant_data
        match = df[df['restaurant_id'] == restaurant_id]

        if len(match) == 0:
            return {'success': True, 'found': False, 'restaurant': {
                'restaurant_id': restaurant_id, 'name': f'Restaurant #{restaurant_id}',
                'cuisines': 'Unknown', 'rating': 3.5, 'price_range': 2,
                'city': 'Unknown', 'country': 'Unknown'
            }}

        row = match.iloc[0]
        return {'success': True, 'found': True, 'restaurant': {
            'restaurant_id': int(row['restaurant_id']),
            'name': str(row.get('restaurant_name', f"Restaurant #{restaurant_id}")),
            'cuisines': str(row.get('cuisines', 'Unknown')),
            'primary_cuisine': str(row.get('primary_cuisine', 'Unknown')),
            'rating': round(float(row.get('aggregate_rating', 3.5)), 1),
            'price_range': int(row.get('price_range', 2)),
            'city': str(row.get('city', 'Unknown')),
            'country': str(row.get('country', 'Unknown')),
            'average_cost_for_two': float(row.get('average_cost_for_two', 500)),
        }}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))