
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "service": "Product Service",
        "status": "healthy"
    }), 200

@app.route('/products', methods=['GET'])
def get_products():
    products = [
        {"id": 1, "name": "Laptop", "price": 55000},
        {"id": 2, "name": "Mobile", "price": 25000},
        {"id": 3, "name": "Keyboard", "price": 1500}
    ]
    return jsonify(products), 200

@app.route('/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    products = [
        {"id": 1, "name": "Laptop", "price": 55000},
        {"id": 2, "name": "Mobile", "price": 25000},
        {"id": 3, "name": "Keyboard", "price": 1500}
    ]

    for product in products:
        if product["id"] == product_id:
            return jsonify(product), 200

    return jsonify({"error": "Product not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
