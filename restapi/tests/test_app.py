from restapi.app import create_app


def test_health():
    app = create_app()
    client = app.test_client()

    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_echo():
    app = create_app()
    client = app.test_client()

    payload = {"message": "hello"}
    resp = client.post("/echo", json=payload)
    assert resp.status_code == 200
    assert resp.get_json().get("received") == payload
