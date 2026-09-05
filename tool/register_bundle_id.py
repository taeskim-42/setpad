#!/usr/bin/env python3
"""Apple Developer 포털에 번들 ID 를 등록한다.

    python3 tool/register_bundle_id.py com.taeskim.setpad setpad

**왜 이게 필요한가.** fastlane 의 `match` 는 App ID 를 만들지 않는다 — 없으면
"Could not find App ID" 로 멈춘다. 만들어 주는 `produce` 는 App Store Connect
API 키를 안 받고 Apple ID 로그인(2FA)을 요구한다. 그래서 그 한 칸만 API 를
직접 부른다. 키가 이미 있으니 사람이 끼어들 일이 없다.

환경변수: ASC_KEY_ID, ASC_ISSUER_ID  (키 파일은 ~/.appstoreconnect/private_keys/)
"""
import os
import sys
import time
import json
import urllib.request
import urllib.error

import jwt

API = 'https://api.appstoreconnect.apple.com/v1'


def token() -> str:
    key_id = os.environ['ASC_KEY_ID']
    issuer = os.environ['ASC_ISSUER_ID']
    path = os.environ.get(
        'ASC_KEY_PATH',
        os.path.expanduser(f'~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8'),
    )
    with open(path) as f:
        secret = f.read()
    now = int(time.time())
    return jwt.encode(
        {'iss': issuer, 'iat': now, 'exp': now + 20 * 60, 'aud': 'appstoreconnect-v1'},
        secret,
        algorithm='ES256',
        headers={'kid': key_id, 'typ': 'JWT'},
    )


def call(method: str, path: str, body=None):
    req = urllib.request.Request(
        f'{API}{path}',
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={
            'Authorization': f'Bearer {token()}',
            'Content-Type': 'application/json',
        },
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read() or b'{}')
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{e.code} {e.reason}\n{e.read().decode()}')


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(f'쓰기: {sys.argv[0]} <bundle-id> <name>')
    bundle_id, name = sys.argv[1], sys.argv[2]

    existing = call('GET', f'/bundleIds?filter[identifier]={bundle_id}')
    if existing.get('data'):
        print(f'이미 등록됨: {bundle_id} (id={existing["data"][0]["id"]})')
        return

    created = call('POST', '/bundleIds', {
        'data': {
            'type': 'bundleIds',
            'attributes': {'identifier': bundle_id, 'name': name, 'platform': 'IOS'},
        }
    })
    print(f'등록했다: {bundle_id} (id={created["data"]["id"]})')


if __name__ == '__main__':
    main()
