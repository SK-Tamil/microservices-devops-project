
from flask import Flask, jsonify

app = Flask(__name__)

# User Service health endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "service": "User Service",
        "status": "healthy"
    }), 200

# Get all users
@app.route('/users', methods=['GET'])
def get_users():
    users = [
        {"id": 1, "name": "Tamil", "role": "Admin"},
        {"id": 2, "name": "Arun", "role": "Customer"}
    ]

    return jsonify(users), 200

# Get user by ID
@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    users = [
        {"id": 1, "name": "Tamil", "role": "Admin"},
        {"id": 2, "name": "Arun", "role": "Customer"}
    ]

    for user in users:
        if user["id"] == user_id:
            return jsonify(user), 200

    return jsonify({"error": "User not found"}), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
