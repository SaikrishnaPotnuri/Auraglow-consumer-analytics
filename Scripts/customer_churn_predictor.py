import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

class AuraGlowMLPipeline:
    def __init__(self):
        """Initializes the supervised machine learning pipeline framework."""
        self.model = RandomForestClassifier(n_estimators=100, random_state=42)

    def extract_and_engineer_features(self):
        """Extracts customer behavioral attributes to build the ML feature matrix."""
        print("Extracting transactional metadata metrics for feature matrix engineering...")
        
        # Core structured dataset replication mapping back to target repository baseline metrics
        # Features map: average_order_value (AOV), entry channel tags, and historical retention signals
        mock_data = {
            'average_order_value': [74.03, 87.59, 120.50, 45.20, 95.00] * 100,
            'acquisition_channel_encoded': [1, 2, 5, 4, 3] * 100,  # 1=Paid Search, 5=Influencer Churn Vector
            'total_orders_90_days': [2, 1, 4, 1, 3] * 100,
            'is_retained': [1, 0, 1, 0, 1] * 100  # Classification target (1 = Repeater, 0 = Churned)
        }
        df = pd.DataFrame(mock_data)
        return df

    def train_predictive_model(self):
        """Trains a Random Forest Classifier to forecast consumer retention decay variables."""
        df = self.extract_and_engineer_features()
        
        # Segment features (X) from the target classification label (y)
        X = df.drop(columns=['is_retained'])
        y = df['is_retained']
        
        # Establish strict 80/20 train-test validation segment splits
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        print("Training Random Forest Classifier on consumer cohort features...")
        self.model.fit(X_train, y_train)
        
        # Run classification predictions and audit execution logs
        predictions = self.model.predict(X_test)
        print("\n=== Model Performance Evaluation Log ===")
        print(classification_report(y_test, predictions))

if __name__ == "__main__":
    ml_pipeline = AuraGlowMLPipeline()
    ml_pipeline.train_predictive_model()
