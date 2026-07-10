#!/usr/bin/env python3
"""Dependency-free concurrent HTTP load fallback for the OKE HPA demo."""

import argparse
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED
import time
from urllib.request import urlopen


def parse_duration(value):
    suffixes = {"s": 1, "m": 60}
    try:
        return float(value[:-1]) * suffixes[value[-1].lower()]
    except (KeyError, ValueError):
        raise argparse.ArgumentTypeError("duration must end in s or m, for example 30s or 2m")


def request(url):
    try:
        with urlopen(url, timeout=15) as response:
            return response.status == 200
    except Exception:
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("--duration", type=parse_duration, default="2m")
    parser.add_argument("--concurrency", type=int, default=40)
    args = parser.parse_args()

    deadline = time.monotonic() + args.duration
    completed = successful = 0
    with ThreadPoolExecutor(max_workers=args.concurrency) as executor:
        pending = {executor.submit(request, args.url) for _ in range(args.concurrency)}
        while pending:
            done, pending = wait(pending, return_when=FIRST_COMPLETED)
            for task in done:
                completed += 1
                successful += int(task.result())
                if time.monotonic() < deadline:
                    pending.add(executor.submit(request, args.url))

    print(f"requests={completed} success={successful} failed={completed - successful}")
    if successful == 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
