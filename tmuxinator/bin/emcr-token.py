#!/usr/bin/env python3
"""Generate an Editorial Manager RS256 report token."""

import argparse
import base64
import hashlib
import json
import time
import urllib.parse
import xml.etree.ElementTree as ET


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def read_rsa_private_key(xml_private_key: str) -> tuple[int, int]:
    """Read the modulus and private exponent from a .NET RSAKeyValue document."""
    try:
        root = ET.fromstring(xml_private_key)
        modulus = root.findtext("Modulus")
        private_exponent = root.findtext("D")
        if root.tag != "RSAKeyValue" or not modulus or not private_exponent:
            raise ValueError("missing RSAKeyValue Modulus or D")
        return (
            int.from_bytes(base64.b64decode(modulus), "big"),
            int.from_bytes(base64.b64decode(private_exponent), "big"),
        )
    except (ET.ParseError, ValueError) as error:
        raise ValueError(f"Private key is not valid .NET RSA XML: {error}") from error


def sign_rs256(signing_input: bytes, modulus: int, private_exponent: int) -> bytes:
    """Create an RSASSA-PKCS1-v1_5 SHA-256 signature using RSA key integers."""
    digest_info = bytes.fromhex("3031300d060960864801650304020105000420")
    digest_info += hashlib.sha256(signing_input).digest()
    key_size = (modulus.bit_length() + 7) // 8
    padding_size = key_size - len(digest_info) - 3
    if padding_size < 8:
        raise ValueError("RSA key is too small for an RS256 signature")
    encoded_message = b"\x00\x01" + (b"\xff" * padding_size) + b"\x00" + digest_info
    signature = pow(int.from_bytes(encoded_message, "big"), private_exponent, modulus)
    return signature.to_bytes(key_size, "big")


def build_jwt(xml_private_key: str, claims: dict) -> str:
    modulus, private_exponent = read_rsa_private_key(xml_private_key)
    header = {"alg": "RS256", "typ": "JWT"}
    header_b64 = b64url(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = b64url(json.dumps(claims, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
    signature = sign_rs256(signing_input, modulus, private_exponent)
    return f"{header_b64}.{payload_b64}.{b64url(signature)}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--private-key-file", required=True)
    parser.add_argument("--journal", required=True)
    parser.add_argument("--doc-id", required=True, type=int)
    parser.add_argument("--revision", required=True, type=int)
    parser.add_argument("--people-id", required=True, type=int)
    parser.add_argument("--role-family-id", required=True, type=int)
    parser.add_argument("--ithenticate-id", default=None)
    parser.add_argument("--ttl-minutes", type=int, default=60)
    parser.add_argument("--base-url", default="http://localhost:8080")
    args = parser.parse_args()

    with open(args.private_key_file, encoding="utf-8") as private_key_file:
        private_key = private_key_file.read().strip()
    if not private_key:
        raise ValueError("Parameter Store returned no private key.")

    now = int(time.time())
    claims = {
        "iss": "EM",
        "aud": "EvaluateManuscript",
        "publicationCode": args.journal,
        "documentId": str(args.doc_id),
        "revision": str(args.revision),
        "peopleId": str(args.people_id),
        "roleFamilyId": str(args.role_family_id),
        "nbf": now,
        "iat": now,
        "exp": now + args.ttl_minutes * 60,
    }
    if args.ithenticate_id:
        claims["iThenticateId"] = args.ithenticate_id

    jwt = build_jwt(private_key, claims)
    outer_token = base64.b64encode(jwt.encode()).decode("ascii")
    url_safe_token = urllib.parse.quote(outer_token, safe="")

    print("Compact JWT:", jwt)
    print()
    print("Path token (outer base64):", outer_token)
    print()
    print("Path token (URL-encoded):", url_safe_token)
    print()
    print("Ready-to-use local URL:")
    print(f"{args.base_url.rstrip('/')}/manuscript/text/token/{url_safe_token}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"error: {error}")
        raise SystemExit(1)
