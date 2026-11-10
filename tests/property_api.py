"""Run against a freshly migrated test database, never a player save."""
from concurrent.futures import ThreadPoolExecutor
import json
import os
import time
import urllib.error
import urllib.request
import uuid

base = os.environ.get("TOURISM_URL", "http://localhost:8766")


def request(path, token=None, payload=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    if payload is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(
        base + path, data=json.dumps(payload).encode() if payload is not None else None, headers=headers
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def command(action, target, **fields):
    return dict(key=str(uuid.uuid4()), action=action, target=target, **fields)


def run():
    assert request("/api/state")[0] == 401
    token = request("/api/session")[1]["token"]

    def act(action):
        return request("/api/actions", token, action)[0]

    def state():
        code, snapshot = request("/api/state", token)
        assert code == 200, snapshot
        return snapshot

    initial = state()
    assert not initial["leases"], "A dedicated fresh test database is required"
    assert act(command("build", "plot-a", kind="restaurant", x=11, y=21)) == 409
    assert act(command("lease", "protected")) == 409
    assert act(command("price", "restaurant", kind="restaurant", value=500)) == 409
    assert act(command("credit", "restaurant", value=999999)) == 409
    lease = command("lease", "restaurant")
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(act, [lease, command("lease", "restaurant")]))
    assert sorted(results) == [200, 409], results
    assert act(lease) == (200 if results[0] == 200 else 409)
    if results[0] == 200:
        assert act({**lease, "target": "homestay"}) == 409
    assert len(state()["leases"]) == 1
    assert act(command("pay", "restaurant")) == 200
    assert act(command("price", "restaurant", kind="restaurant", value=55)) == 200
    assert act(command("lease", "plot-a")) == 200
    assert act(command("build", "plot-a", kind="restaurant", x=8, y=21)) == 409
    assert act(command("build", "plot-a", kind="restaurant", x=12, y=22)) == 409
    assert act(command("build", "plot-a", kind="homestay", x=11, y=21)) == 409
    build = command("build", "plot-a", kind="restaurant", x=11, y=21)
    assert act(build) == 200
    assert act(build) == 200
    assert act(command("end", "plot-a")) == 409
    reloaded = state()
    facilities = [x for x in reloaded["facilities"] if x["assetId"] == "plot-a"]
    assert len(facilities) == 1 and facilities[0]["owner"] == "demo"
    for _ in range(25):
        snapshot = state()
        sales = [x for x in snapshot["ledger"] if x["kind"] == "Doanh thu dịch vụ"]
        if {x["assetId"] for x in sales} >= {"restaurant", "plot-a"}:
            assert len({x["id"] for x in snapshot["ledger"]}) == len(snapshot["ledger"])
            print("PROPERTY API PASS — two businesses earned server revenue without a Godot client")
            return
        time.sleep(1)
    raise AssertionError("Missing server revenue for both businesses")


if __name__ == "__main__":
    run()

