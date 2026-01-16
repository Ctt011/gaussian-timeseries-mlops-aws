import pickle
from flask import Flask, jsonify
import pandas as pd
import boto3
import os
from io import StringIO

# Flask app
app = Flask(__name__)

# Load ML model
model = pickle.load(open("./Output/model.pkl", "rb"))

# Function to get S3 config (only bucket, key, region)
def get_s3_config():
    return (
        os.getenv("S3_BUCKET"),  # S3 bucket name
        os.getenv("S3_KEY"),     # S3 object key
        os.getenv("AWS_REGION")  # AWS region
    )

# Health check
@app.route("/check")
def health_check():
    return "Yay! Flask app is running"

# Prediction route
@app.route("/", methods=["POST"])
def predict_from_s3():
    bucket, key, region = get_s3_config()

    # Connect to S3 using CodeBuild/IAM credentials (no access/secret needed)
    s3_client = boto3.client("s3", region_name=region)

    # Fetch CSV
    obj = s3_client.get_object(Bucket=bucket, Key=key)
    data = pd.read_csv(StringIO(obj["Body"].read().decode("utf-8-sig")))

    # Convert month to timestamp
    data["timestamp"] = pd.to_datetime(data["month"]).apply(lambda x: x.timestamp())

    # Predict
    X = data["timestamp"].values.reshape(-1, 1)
    predictions = model.predict(X).tolist()

    return jsonify({"status": 200, "predictions": predictions})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
