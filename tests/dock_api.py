"""Run against a test database with the demo dock still unleased."""
import os
import time
from property_api import command, request

assert os.environ.get("TOURISM_URL"), "Set the isolated test server URL explicitly"
token = request("/api/session")[1]["token"]

def state():
    code, data = request("/api/state", token)
    assert code == 200, data
    return data

def act(action, **fields):
    status, data = request("/api/actions", token, command(action, "dock", **fields))
    assert status == 200, data

initial = state()
assert next(asset for asset in initial["assets"] if asset["id"] == "dock")["rent"] == 200
assert not any(lease["assetId"] == "dock" and lease["status"] == "Active" for lease in initial["leases"])
act("lease")
act("price", kind="dock", value=150)
start = state()["market"]["period"]
for _ in range(24):
    snapshot = state()
    market = snapshot["market"]
    if market["period"] > start and market["dockFare"] == 150:
        assert market["dockSeats"] == 1
        assert market["dockGross"] == 150
        assert any(entry["assetId"] == "dock" and entry["amount"] == 150
                   and entry["period"] == market["period"]
                   and entry["kind"] == "Doanh thu dịch vụ" for entry in snapshot["ledger"])
        print("DOCK API PASS: allocation, fare and ledger share a market period")
        break
    time.sleep(1)
else:
    raise AssertionError("No updated dock dispatch")

