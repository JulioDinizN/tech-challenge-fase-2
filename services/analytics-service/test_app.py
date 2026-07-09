import json
import os
import unittest
from types import SimpleNamespace

os.environ["ANALYTICS_WORKER_ENABLED"] = "false"

import app as analytics_app


class FakeQueueClient:
    def __init__(self):
        self.deleted = []

    def delete_message(self, queue_id, receipt):
        self.deleted.append((queue_id, receipt))


class FakeNosqlClient:
    def __init__(self):
        self.updates = []

    def update_row(self, table, details):
        self.updates.append((table, details))


class ProcessMessageTests(unittest.TestCase):
    def setUp(self):
        analytics_app.OCI_QUEUE_OCID = "ocid1.queue.test"
        analytics_app.OCI_NOSQL_TABLE = "ToggleMasterAnalytics"
        analytics_app.OCI_COMPARTMENT_OCID = "ocid1.compartment.test"
        self.queue = FakeQueueClient()
        self.nosql = FakeNosqlClient()

    def test_persists_event_before_acknowledging_message(self):
        message = SimpleNamespace(
            id=123,
            receipt="receipt-123",
            content=json.dumps(
                {
                    "user_id": "user-1",
                    "flag_name": "new-checkout",
                    "result": True,
                    "timestamp": "2026-07-09T12:00:00Z",
                }
            ),
        )

        processed = analytics_app.process_message(message, self.queue, self.nosql)

        self.assertTrue(processed)
        self.assertEqual(self.queue.deleted, [("ocid1.queue.test", "receipt-123")])
        self.assertEqual(len(self.nosql.updates), 1)
        table, details = self.nosql.updates[0]
        self.assertEqual(table, "ToggleMasterAnalytics")
        self.assertEqual(details.value["event_id"], "123")
        self.assertEqual(details.value["occurred_at"], "2026-07-09T12:00:00Z")
        self.assertEqual(details.value["result"], True)

    def test_does_not_acknowledge_invalid_event(self):
        message = SimpleNamespace(
            id="bad-event",
            receipt="receipt-bad",
            content=json.dumps({"user_id": "user-1"}),
        )

        processed = analytics_app.process_message(message, self.queue, self.nosql)

        self.assertFalse(processed)
        self.assertEqual(self.queue.deleted, [])
        self.assertEqual(self.nosql.updates, [])


if __name__ == "__main__":
    unittest.main()
