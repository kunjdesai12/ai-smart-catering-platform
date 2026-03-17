"""
ML Service — Loads all 3 trained models and provides prediction methods.
"""

import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict
from sklearn.metrics.pairwise import cosine_similarity

from app.config import get_settings
from app.utils.logger import setup_logger

logger = setup_logger("ml_service")

CURRENCY_TO_COUNTRY = {
    'indian rupees(rs.)': 'India',
    'rupees(rs.)': 'India',
    'dollar($)': 'United States',
    'dollars($)': 'United States',
    'pounds(£)': 'United Kingdom',
    'pound(£)': 'United Kingdom',
    'euro(€)': 'Europe',
    'euros(€)': 'Europe',
    'emirati diram(aed)': 'UAE',
    'brazilian real(r$)': 'Brazil',
    'indonesian rupiah(idr)': 'Indonesia',
    'turkish lira(tl)': 'Turkey',
    'sri lankan rupee(lkr)': 'Sri Lanka',
    'qatari rial(qr)': 'Qatar',
    'philippine peso(php)': 'Philippines',
    'new zealand($)': 'New Zealand',
    'rand(r)': 'South Africa',
    'botswana pula(p)': 'Botswana',
}

CURRENCY_TO_INR = {
    'indian rupees(rs.)': 1,
    'rupees(rs.)': 1,
    'dollar($)': 83,
    'dollars($)': 83,
    'pounds(£)': 105,
    'pound(£)': 105,
    'euro(€)': 90,
    'euros(€)': 90,
    'emirati diram(aed)': 23,
    'brazilian real(r$)': 17,
    'indonesian rupiah(idr)': 0.005,
    'turkish lira(tl)': 2.5,
    'sri lankan rupee(lkr)': 0.26,
    'qatari rial(qr)': 23,
    'philippine peso(php)': 1.5,
    'new zealand($)': 52,
    'rand(r)': 4.6,
    'botswana pula(p)': 6.2,
}


class MLService:

    def __init__(self):
        self.models_dir = get_settings().models_dir
        self._loaded = False
        self.demand_model = None
        self.demand_feature_cols = None
        self.demand_feature_stats = None
        self.demand_metrics = None
        self.eta_model = None
        self.eta_feature_cols = None
        self.eta_label_encoders = None
        self.eta_metrics = None
        self.rec_tfidf_vectorizer = None
        self.rec_tfidf_matrix = None
        self.rec_restaurant_data = None
        self.rec_cuisine_menu_map = None
        self.rec_metrics = None
        self.location_hierarchy = {}

    def load_all_models(self):
        if self._loaded:
            return
        logger.info("=" * 50)
        logger.info("LOADING ALL ML MODELS")
        logger.info("=" * 50)
        try:
            self._load_demand_model()
            self._load_eta_model()
            self._load_recommendation_model()
            self._loaded = True
            logger.info("=" * 50)
            logger.info("ALL MODELS LOADED SUCCESSFULLY")
            logger.info("=" * 50)
        except Exception as e:
            logger.error(f"CRITICAL: Model loading failed — {e}")
            raise

    def _load_demand_model(self):
        logger.info("Loading Demand model...")
        self.demand_model = joblib.load(self.models_dir / "demand_model.joblib")
        self.demand_feature_cols = joblib.load(self.models_dir / "demand_feature_cols.joblib")
        self.demand_feature_stats = joblib.load(self.models_dir / "demand_feature_stats.joblib")
        self.demand_metrics = joblib.load(self.models_dir / "demand_metrics.joblib")
        logger.info(f"  Demand: {len(self.demand_feature_cols)} features | R²={self.demand_metrics['r2']:.4f}")

    def _load_eta_model(self):
        logger.info("Loading ETA model...")
        self.eta_model = joblib.load(self.models_dir / "eta_model.joblib")
        self.eta_feature_cols = joblib.load(self.models_dir / "eta_feature_cols.joblib")
        self.eta_label_encoders = joblib.load(self.models_dir / "eta_label_encoders.joblib")
        self.eta_metrics = joblib.load(self.models_dir / "eta_metrics.joblib")
        logger.info(f"  ETA: {len(self.eta_feature_cols)} features | R²={self.eta_metrics['r2']:.4f}")

    def _load_recommendation_model(self):
        logger.info("Loading Recommendation engine...")
        self.rec_tfidf_vectorizer = joblib.load(self.models_dir / "rec_tfidf_vectorizer.joblib")
        self.rec_tfidf_matrix = joblib.load(self.models_dir / "rec_tfidf_matrix.joblib")
        self.rec_cuisine_menu_map = joblib.load(self.models_dir / "rec_cuisine_menu_map.joblib")
        self.rec_metrics = joblib.load(self.models_dir / "rec_metrics.joblib")
        self.rec_restaurant_data = pd.read_csv(self.models_dir / "rec_restaurant_data.csv")

        original_count = len(self.rec_restaurant_data)
        logger.info(f"  Original restaurant count: {original_count}")

        # Try to merge names and currency from zomato_cleaned.csv
        full_zomato_path = self.models_dir / "zomato_cleaned.csv"
        if full_zomato_path.exists():
            try:
                full_zomato = pd.read_csv(full_zomato_path)
                merge_cols = ['restaurant_id']
                for col in ['restaurant_name', 'city', 'address', 'locality', 'currency']:
                    if col in full_zomato.columns:
                        merge_cols.append(col)

                if len(merge_cols) > 1:
                    name_data = full_zomato[merge_cols].drop_duplicates(subset=['restaurant_id'], keep='first')
                    self.rec_restaurant_data = self.rec_restaurant_data.merge(
                        name_data, on='restaurant_id', how='left'
                    )
                    # CRITICAL: Remove any duplicates created by merge
                    self.rec_restaurant_data = self.rec_restaurant_data.drop_duplicates(
                        subset=['restaurant_id'], keep='first'
                    )
                    # CRITICAL: Reset index to match TF-IDF matrix
                    self.rec_restaurant_data = self.rec_restaurant_data.reset_index(drop=True)
                    logger.info(f"  Merged names/currency. Count: {len(self.rec_restaurant_data)}")
            except Exception as e:
                logger.warning(f"  Could not merge zomato data: {e}")

        # Add country from currency
        if 'currency' in self.rec_restaurant_data.columns:
            def safe_get_country(currency_str):
                try:
                    currency_lower = str(currency_str).lower().strip()
                    for key, country in CURRENCY_TO_COUNTRY.items():
                        if key in currency_lower:
                            return country
                except Exception:
                    pass
                return 'Other'

            self.rec_restaurant_data['country'] = self.rec_restaurant_data['currency'].apply(safe_get_country)
        else:
            self.rec_restaurant_data['country'] = 'Unknown'

        # Convert costs to INR
        if 'currency' in self.rec_restaurant_data.columns:
            def safe_convert_to_inr(row):
                try:
                    cost = float(row['average_cost_for_two'])
                    if pd.isna(cost) or cost <= 0:
                        return 500.0
                    currency = str(row.get('currency', '')).lower().strip()
                    rate = 1
                    for key, conv_rate in CURRENCY_TO_INR.items():
                        if key in currency:
                            rate = conv_rate
                            break
                    converted = cost * rate
                    if converted < 100:
                        converted = max(200, cost * 83)
                    return converted
                except Exception:
                    return 500.0

            self.rec_restaurant_data['average_cost_for_two'] = self.rec_restaurant_data.apply(safe_convert_to_inr, axis=1)
            logger.info("  Costs converted to INR")

        # Sanity clamp
        self.rec_restaurant_data['average_cost_for_two'] = (
            self.rec_restaurant_data['average_cost_for_two']
            .fillna(500)
            .clip(lower=200, upper=50000)
        )

        # Fill missing city
        if 'city' in self.rec_restaurant_data.columns:
            self.rec_restaurant_data['city'] = self.rec_restaurant_data['city'].fillna('Unknown')
        else:
            self.rec_restaurant_data['city'] = 'Unknown'

        # Rebuild TF-IDF if row count changed
        if len(self.rec_restaurant_data) != self.rec_tfidf_matrix.shape[0]:
            logger.warning(
                f"  TF-IDF mismatch: matrix={self.rec_tfidf_matrix.shape[0]}, "
                f"data={len(self.rec_restaurant_data)}. Rebuilding..."
            )
            from sklearn.feature_extraction.text import TfidfVectorizer
            tfidf = TfidfVectorizer(max_features=200, stop_words='english', ngram_range=(1, 2))
            self.rec_tfidf_matrix = tfidf.fit_transform(
                self.rec_restaurant_data['cuisines'].fillna('unknown')
            )
            self.rec_tfidf_vectorizer = tfidf
            logger.info(f"  TF-IDF rebuilt: {self.rec_tfidf_matrix.shape}")

        # Build location hierarchy
        self._build_location_hierarchy()

        logger.info(
            f"  Recommendation ready: {len(self.rec_restaurant_data):,} restaurants | "
            f"Cost: ₹{self.rec_restaurant_data['average_cost_for_two'].min():.0f}"
            f" - ₹{self.rec_restaurant_data['average_cost_for_two'].max():.0f}"
        )

    def _build_location_hierarchy(self):
        logger.info("  Building location hierarchy...")
        df = self.rec_restaurant_data
        if 'country' not in df.columns or 'city' not in df.columns:
            self.location_hierarchy = {}
            return

        hierarchy = {}
        for country in sorted(df['country'].unique()):
            if str(country).lower() in ['unknown', 'nan', 'other', '', 'none']:
                continue
            country_df = df[df['country'] == country]
            city_counts = (
                country_df.groupby('city')['restaurant_id'].count().reset_index()
            )
            city_counts.columns = ['city', 'restaurant_count']
            city_counts = city_counts.sort_values('restaurant_count', ascending=False)

            cities = []
            for _, row in city_counts.iterrows():
                city_name = str(row['city']).strip()
                if city_name and city_name.lower() not in ['unknown', 'nan', '', 'none']:
                    cities.append({
                        'city': city_name,
                        'restaurant_count': int(row['restaurant_count'])
                    })

            if cities:
                hierarchy[country] = {
                    'cities': cities,
                    'total_restaurants': sum(c['restaurant_count'] for c in cities),
                    'total_cities': len(cities)
                }

        self.location_hierarchy = hierarchy
        logger.info(f"  Locations: {len(hierarchy)} countries")

    def get_locations(self) -> Dict:
        return self.location_hierarchy

    # ═══════════════════════════════════════════
    # DEMAND PREDICTION (unchanged)
    # ═══════════════════════════════════════════
    def predict_demand(self, restaurant_id, day_of_week, hour_of_day,
                       is_weekend, holiday, restaurant_rating, price_range) -> Dict:
        hour_stats = self.demand_feature_stats['hour_stats']
        day_stats = self.demand_feature_stats['day_stats']
        rest_stats = self.demand_feature_stats['rest_stats']
        global_hour = self.demand_feature_stats['global_hour']

        ghm = global_hour[global_hour['hour_of_day'] == hour_of_day]
        global_hour_avg = float(ghm['global_hour_avg'].iloc[0]) if len(ghm) > 0 else float(global_hour['global_hour_avg'].mean())
        global_day_avg = float(day_stats['avg_orders_this_day'].mean())
        global_rest_avg = float(rest_stats['restaurant_avg_orders'].mean())

        hm = hour_stats[(hour_stats['restaurant_id'] == restaurant_id) & (hour_stats['hour_of_day'] == hour_of_day)]
        dm = day_stats[(day_stats['restaurant_id'] == restaurant_id) & (day_stats['day_of_week'] == day_of_week)]
        rm = rest_stats[rest_stats['restaurant_id'] == restaurant_id]

        restaurant_order_avg = float(rm['restaurant_avg_orders'].iloc[0]) if len(rm) > 0 else global_rest_avg
        is_sparse = restaurant_order_avg < 3.0
        blend = 0.7 if is_sparse else 0.2

        rha = float(hm['avg_orders_this_hour'].iloc[0]) if len(hm) > 0 else restaurant_order_avg
        rda = float(dm['avg_orders_this_day'].iloc[0]) if len(dm) > 0 else restaurant_order_avg

        features = {
            'day_of_week': day_of_week, 'hour_of_day': hour_of_day,
            'is_weekend': is_weekend, 'holiday': holiday,
            'restaurant_rating': restaurant_rating, 'price_range': price_range,
            'avg_orders_this_hour': blend * global_hour_avg + (1 - blend) * rha,
            'avg_orders_this_day': blend * global_day_avg + (1 - blend) * rda,
            'restaurant_avg_orders': blend * global_rest_avg + (1 - blend) * restaurant_order_avg,
            'global_hour_avg': global_hour_avg,
            'is_peak_hour': 1 if hour_of_day in [12, 13, 19, 20, 21] else 0,
            'is_late_night': 1 if hour_of_day < 6 else 0
        }

        feature_df = pd.DataFrame([features], columns=self.demand_feature_cols)
        prediction = self.demand_model.predict(feature_df)[0]
        predicted_orders = max(1, round(float(prediction)))
        confidence = min(0.95, max(0.60, self.demand_metrics['r2']))
        if is_sparse:
            confidence = round(confidence * 0.85, 4)

        return {
            'predicted_orders': predicted_orders,
            'confidence': round(confidence, 4),
            'model_rmse': round(self.demand_metrics['rmse'], 4),
            'features_used': features,
            'peak_status': 'peak' if features['is_peak_hour'] else ('dead' if features['is_late_night'] else 'normal')
        }

    # ═══════════════════════════════════════════
    # ETA PREDICTION (unchanged)
    # ═══════════════════════════════════════════
    def predict_eta(self, distance_km, preparation_time_min,
                    weather, traffic_level, time_of_day, vehicle_type) -> Dict:
        encoded = {}
        for col, value in {'weather': weather, 'traffic_level': traffic_level,
                           'time_of_day': time_of_day, 'vehicle_type': vehicle_type}.items():
            enc = self.eta_label_encoders.get(col)
            if enc is not None:
                val = value.lower().strip()
                encoded[col + '_encoded'] = int(enc.transform([val])[0]) if val in enc.classes_ else 0

        features = {'distance_km': distance_km, 'preparation_time_min': preparation_time_min, **encoded}
        fdf = pd.DataFrame([features], columns=self.eta_feature_cols)
        for c in self.eta_feature_cols:
            if c not in fdf.columns:
                fdf[c] = 0
        fdf = fdf[self.eta_feature_cols]

        pred = self.eta_model.predict(fdf)[0]
        eta = max(10, round(float(pred)))
        if eta < preparation_time_min:
            eta = int(preparation_time_min) + 10

        return {
            'eta_minutes': eta,
            'confidence': round(min(0.95, max(0.60, self.eta_metrics['r2'])), 4),
            'model_rmse': round(self.eta_metrics['rmse'], 4),
            'breakdown': {
                'preparation': int(preparation_time_min),
                'travel_estimate': max(5, eta - int(preparation_time_min)),
                'distance_km': round(distance_km, 2),
                'weather': weather, 'traffic': traffic_level
            }
        }

    # ═══════════════════════════════════════════
    # RECOMMENDATION (with safe location filter)
    # ═══════════════════════════════════════════
    def recommend(self, cuisine_query, budget_per_person, num_people,
                  min_rating=3.5, top_n=5, city=None, country=None) -> Dict:
        try:
            df = self.rec_restaurant_data.copy()
            df = df.reset_index(drop=True)

            # # Filter by country
            # if country and 'country' in df.columns:
            #     filtered = df[df['country'].str.lower().str.strip() == country.lower().strip()]
            #     if len(filtered) > 0:
            #         df = filtered.reset_index(drop=True)

            # # Filter by city
            # if city and 'city' in df.columns:
            #     filtered = df[df['city'].str.lower().str.strip() == city.lower().strip()]
            #     if len(filtered) > 0:
            #         df = filtered.reset_index(drop=True)

                    # Filter by country
            if country and 'country' in df.columns:
                filtered = df[df['country'].str.lower().str.strip() == country.lower().strip()]
                if len(filtered) > 0:
                    df = filtered.reset_index(drop=True)
                else:
                    df = df.iloc[0:0]

        # Filter by city
            if city and 'city' in df.columns:
                filtered = df[df['city'].str.lower().str.strip() == city.lower().strip()]
                if len(filtered) > 0:
                    df = filtered.reset_index(drop=True)
                else:
                    df = df.iloc[0:0]

            # Compute similarity safely
            query_vec = self.rec_tfidf_vectorizer.transform([cuisine_query.lower()])

            # If filtered, recompute TF-IDF for filtered set
            filtered_cuisines = df['cuisines'].fillna('unknown')
            filtered_matrix = self.rec_tfidf_vectorizer.transform(filtered_cuisines)
            similarity = cosine_similarity(query_vec, filtered_matrix).flatten()
            df['cuisine_similarity'] = similarity

            # Budget filter
            total_budget = budget_per_person * num_people
            df['cost_per_person'] = df['average_cost_for_two'] / 2
            df['estimated_cost'] = df['cost_per_person'] * num_people

            df_budget = df[df['cost_per_person'] <= budget_per_person * 1.3]
            df_rated = df_budget[df_budget['aggregate_rating'] >= min_rating]

            if len(df_rated) < top_n:
                df_rated = df_budget[df_budget['aggregate_rating'] >= max(2.0, min_rating - 1)]
            if len(df_rated) < top_n:
                df_rated = df.nlargest(top_n * 2, 'cuisine_similarity')
            if len(df_rated) == 0:
                df_rated = df.nlargest(top_n, 'cuisine_similarity')

            df_rated = df_rated.copy()
            max_rating = df_rated['aggregate_rating'].max()
            df_rated['norm_rating'] = df_rated['aggregate_rating'] / max_rating if max_rating > 0 else 0.5

            if 'popularity_score' not in df_rated.columns:
                df_rated['popularity_score'] = 0.5

            df_rated['final_score'] = (
                0.4 * df_rated['cuisine_similarity'] +
                0.3 * df_rated['norm_rating'] +
                0.3 * df_rated['popularity_score']
            )

            top = df_rated.nlargest(top_n, 'final_score')
            total_matches = len(df_rated)

            restaurants = []
            for _, row in top.iterrows():
                primary = str(row.get('primary_cuisine', cuisine_query)).lower().strip()
                menu = self.rec_cuisine_menu_map.get(primary, None)
                if menu is None:
                    for key, items in self.rec_cuisine_menu_map.items():
                        if key in primary or primary in key:
                            menu = items
                            break
                if menu is None:
                    menu = ['Chef Special', 'House Platter', 'Seasonal Items', 'Beverages']

                restaurants.append({
                    'restaurant_id': int(row['restaurant_id']),
                    'name': str(row.get('restaurant_name', f"Restaurant #{row['restaurant_id']}")),
                    'cuisines': str(row.get('cuisines', cuisine_query)),
                    'primary_cuisine': str(row.get('primary_cuisine', cuisine_query)),
                    'rating': round(float(row.get('aggregate_rating', 3.5)), 1),
                    'price_range': int(row.get('price_range', 2)),
                    'estimated_cost': int(round(float(row.get('estimated_cost', 0)))),
                    'cost_per_person': int(round(float(row.get('cost_per_person', 250)))),
                    'city': str(row.get('city', 'Unknown')),
                    'country': str(row.get('country', 'Unknown')),
                    'match_score': round(float(row.get('final_score', 0)), 4),
                    'cuisine_match': round(float(row.get('cuisine_similarity', 0)), 4),
                    'suggested_menu': menu
                })

            return {
                'query': {
                    'cuisine': cuisine_query,
                    'budget_per_person': budget_per_person,
                    'num_people': num_people,
                    'total_budget': total_budget,
                    'min_rating': min_rating,
                    'city': city,
                    'country': country
                },
                'total_matches': total_matches,
                'recommendations': restaurants
            }

        except Exception as e:
            logger.error(f"Recommendation error: {e}")
            return {
                'query': {'cuisine': cuisine_query, 'budget_per_person': budget_per_person,
                          'num_people': num_people, 'total_budget': budget_per_person * num_people,
                          'min_rating': min_rating, 'city': city, 'country': country},
                'total_matches': 0,
                'recommendations': []
            }

    def get_model_info(self) -> Dict:
        return {
            'models_loaded': self._loaded,
            'demand': {'features': len(self.demand_feature_cols) if self.demand_feature_cols else 0, 'metrics': self.demand_metrics},
            'eta': {'features': len(self.eta_feature_cols) if self.eta_feature_cols else 0, 'metrics': self.eta_metrics},
            'recommendation': {'restaurants': len(self.rec_restaurant_data) if self.rec_restaurant_data is not None else 0, 'metrics': self.rec_metrics}
        }


ml_service = MLService()