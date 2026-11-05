
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "service": "Order Service",
        "status": "healthy"
    }), 200

@app.route('/orders', methods=['GET'])
def get_orders():
    orders = [
        {"id": 101, "user_id": 1, "product_id": 1, "quantity": 1},
        {"id": 102, "user_id": 2, "product_id": 2, "quantity": 2}
    ]
    return jsonify(orders), 200

@app.route('/orders/<int:order_id>', methods=['GET'])
def get_order(order_id):
    orders = [
        {"id": 101, "user_id": 1, "product_id": 1, "quantity": 1},
        {"id": 102, "user_id": 2, "product_id": 2, "quantity": 2}
    ]

    for order in orders:
        if order["id"] == order_id:
            return jsonify(order), 200

    return jsonify({"error": "Order not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)
