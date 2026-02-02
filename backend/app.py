from flask import Flask, request, jsonify
import pickle
import numpy as np

app = Flask(__name__)

# Load model
with open("disease_model.pkl", "rb") as f:
    model = pickle.load(f)

with open("label_encoder.pkl", "rb") as f:
    label_encoder = pickle.load(f)

# Symptoms order (same as training)
SYMPTOMS = model.feature_names_in_.tolist()

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "Backend running",
        "endpoint": "/predict"
    })

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()

    if not data or "symptoms" not in data:
        return jsonify({"error": "symptoms list required"}), 400

    user_symptoms = data["symptoms"]

    input_vector = [1 if s in user_symptoms else 0 for s in SYMPTOMS]

    prediction = model.predict([input_vector])[0]
    probabilities = model.predict_proba([input_vector])[0]

    disease = label_encoder.inverse_transform([prediction])[0]
    confidence = float(np.max(probabilities))

    top3_idx = np.argsort(probabilities)[-3:][::-1]
    top3_diseases = label_encoder.inverse_transform(top3_idx)

    return jsonify({
        "predicted_disease": disease,
        "confidence_percent": round(confidence * 100, 2),
        "top_3_diseases": top3_diseases.tolist(),
        "disclaimer": "This is not a medical diagnosis"
    })

if __name__ == "__main__":
    # Bind to all interfaces so physical devices on the same network can connect
    app.run(host="0.0.0.0", port=5000, debug=True)
