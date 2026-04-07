#!/usr/bin/env python3
"""Small resumable segmented downloader using only Python stdlib."""

import argparse
import concurrent.futures
import os
import shutil
import sys
import time
import urllib.request


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("output")
    parser.add_argument("--size", type=int, required=True)
    parser.add_argument("--connections", type=int, default=8)
    parser.add_argument("--retries", type=int, default=20)
    parser.add_argument("--timeout", type=int, default=120)
    return parser.parse_args()


def download_range(url, output, start, end, retries, timeout):
    os.makedirs(os.path.dirname(output), exist_ok=True)
    expected = end - start + 1
    existing = os.path.getsize(output) if os.path.exists(output) else 0

    if existing == expected:
        return expected
    if existing > expected:
        os.remove(output)
        existing = 0

    for attempt in range(1, retries + 1):
        current_start = start + existing
        if current_start > end:
            return expected

        request = urllib.request.Request(
            url,
            headers={"Range": "bytes={}-{}".format(current_start, end)},
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                if response.status != 206:
                    raise RuntimeError("unexpected HTTP status {}".format(response.status))
                mode = "ab" if existing else "wb"
                with open(output, mode) as handle:
                    shutil.copyfileobj(response, handle, length=1024 * 1024)
            existing = os.path.getsize(output)
            if existing == expected:
                return expected
        except Exception as exc:
            if attempt == retries:
                raise
            print(
                "[retry] {} attempt {}/{}: {}".format(
                    os.path.basename(output), attempt, retries, exc
                ),
                flush=True,
            )
            time.sleep(min(30, attempt * 2))

    raise RuntimeError("failed to download {}".format(output))


def merge_parts(parts, output, expected_size):
    tmp_output = output + ".tmp"
    with open(tmp_output, "wb") as merged:
        for part in parts:
            with open(part, "rb") as handle:
                shutil.copyfileobj(handle, merged, length=1024 * 1024)

    actual = os.path.getsize(tmp_output)
    if actual != expected_size:
        raise RuntimeError(
            "merged size mismatch for {}: got {}, expected {}".format(
                output, actual, expected_size
            )
        )
    os.replace(tmp_output, output)


def seed_parts_from_partial_output(output, parts, expected_size):
    if not os.path.exists(output):
        return
    if any(os.path.exists(part) for part in parts):
        return

    existing_size = os.path.getsize(output)
    if existing_size <= 0 or existing_size >= expected_size:
        return

    print(
        "[resume] seeding {} bytes from {}".format(
            existing_size, os.path.basename(output)
        ),
        flush=True,
    )
    remaining = existing_size
    with open(output, "rb") as source:
        for part in parts:
            if remaining <= 0:
                break
            to_copy = min(remaining, (expected_size + len(parts) - 1) // len(parts))
            with open(part, "wb") as target:
                copied = 0
                while copied < to_copy:
                    chunk = source.read(min(1024 * 1024, to_copy - copied))
                    if not chunk:
                        break
                    target.write(chunk)
                    copied += len(chunk)
            remaining -= to_copy


def main():
    args = parse_args()
    output = os.path.abspath(args.output)
    expected_size = args.size

    if os.path.exists(output) and os.path.getsize(output) == expected_size:
        print("[skip] {} already complete".format(os.path.basename(output)))
        return 0

    part_dir = output + ".parts"
    os.makedirs(part_dir, exist_ok=True)

    connections = max(1, min(args.connections, expected_size))
    chunk_size = (expected_size + connections - 1) // connections
    tasks = []
    parts = []
    for index in range(connections):
        start = index * chunk_size
        end = min(expected_size - 1, start + chunk_size - 1)
        if start > end:
            break
        part = os.path.join(part_dir, "part-{:03d}".format(index))
        tasks.append((args.url, part, start, end, args.retries, args.timeout))
        parts.append(part)

    seed_parts_from_partial_output(output, parts, expected_size)

    print(
        "[download] {} with {} connections".format(
            os.path.basename(output), len(tasks)
        ),
        flush=True,
    )

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(tasks)) as executor:
        futures = [executor.submit(download_range, *task) for task in tasks]
        while True:
            done = sum(1 for future in futures if future.done())
            downloaded = sum(
                os.path.getsize(part) for part in parts if os.path.exists(part)
            )
            print(
                "[progress] {}/{} bytes ({:.1f}%), parts {}/{}".format(
                    downloaded,
                    expected_size,
                    downloaded * 100.0 / expected_size,
                    done,
                    len(futures),
                ),
                flush=True,
            )
            if done == len(futures):
                break
            time.sleep(10)
        for future in futures:
            future.result()

    merge_parts(parts, output, expected_size)
    shutil.rmtree(part_dir)
    print("[ok] {}".format(output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
