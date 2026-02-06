#!/usr/bin/env python3
import argparse
import socket
import struct
import sys

SERVERDATA_AUTH = 3
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_EXECCOMMAND = 2


def send_packet(sock, req_id, req_type, body):
    payload = body.encode("utf-8") + b"\x00\x00"
    packet = struct.pack("<iii", req_id, req_type, req_id) + payload
    sock.sendall(struct.pack("<i", len(packet)) + packet)


def recv_packet(sock):
    raw_len = sock.recv(4)
    if len(raw_len) < 4:
        return None
    (length,) = struct.unpack("<i", raw_len)
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            break
        data += chunk
    if len(data) < 12:
        return None
    req_id, resp_type = struct.unpack("<ii", data[:8])
    body = data[8:-2].decode("utf-8", errors="ignore")
    return req_id, resp_type, body


def rcon_command(host, port, password, command, timeout):
    with socket.create_connection((host, port), timeout=timeout) as sock:
        req_id = 1
        send_packet(sock, req_id, SERVERDATA_AUTH, password)
        auth_resp = recv_packet(sock)
        if not auth_resp or auth_resp[0] == -1:
            return 1
        send_packet(sock, req_id, SERVERDATA_EXECCOMMAND, command)
        recv_packet(sock)
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=27015)
    parser.add_argument("--password", required=True)
    parser.add_argument("--timeout", type=float, default=3.0)
    parser.add_argument("command")
    args = parser.parse_args()
    return rcon_command(args.host, args.port, args.password, args.command, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
