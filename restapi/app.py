from flask import Flask, jsonify, request


def create_app():
    app = Flask(__name__)
    @app.route("/", methods=["GET"])
    def index():
        return (
            jsonify(
                message="LookingGlass REST API",
                routes=["/health (GET)", "/echo (POST)"],
            ),
            200,
        )

    @app.route("/health", methods=["GET"])
    def health():
        """Health check endpoint."""
        return jsonify(status="ok"), 200

    @app.route("/echo", methods=["POST"])
    def echo():
        """Echo endpoint. Returns the JSON body back to the caller."""
        data = request.get_json(silent=True)
        return jsonify(received=data), 200

    @app.errorhandler(404)
    def handle_404(err):
        return (
            jsonify(
                error="not_found",
                message=str(err),
                available_routes=["/", "/health", "/echo"],
            ),
            404,
        )

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=8000, debug=True)