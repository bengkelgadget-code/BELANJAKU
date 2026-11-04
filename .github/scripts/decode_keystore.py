import os
import sys
import re
import base64
import subprocess

def clean_val(val, default=''):
    if not val:
        return default
    lines = [l.strip() for l in val.splitlines() if l.strip()]
    if not lines:
        return default
    if len(lines) > 1 and any(k in lines[0].upper() for k in ['ANDROID', 'PASSWORD', 'ALIAS', 'SECRET', '1.', '2.', '3.', '4.']):
        return lines[-1].strip()
    return lines[0].strip()

def main():
    raw_b64 = os.environ.get('ANDROID_KEYSTORE_BASE64', '')
    if not raw_b64.strip():
        print("::error title=Missing Secret::Secret ANDROID_KEYSTORE_BASE64 is empty or not set in GitHub Settings!")
        sys.exit(1)

    store_pass = clean_val(os.environ.get('ANDROID_KEYSTORE_PASSWORD'), 'yHMO09lXyJw9ucZ7vEjz')
    key_pass = clean_val(os.environ.get('ANDROID_KEY_PASSWORD'), store_pass)
    key_alias = clean_val(os.environ.get('ANDROID_KEY_ALIAS'), 'belanjaku_upload')

    # Sanitize and decode base64
    b64 = raw_b64
    if 'MIIL' in b64:
        b64 = b64[b64.find('MIIL'):]
    b64_clean = re.sub(r'[^A-Za-z0-9+/=]', '', b64)
    missing_padding = len(b64_clean) % 4
    if missing_padding:
        b64_clean += '=' * (4 - missing_padding)

    try:
        decoded = base64.b64decode(b64_clean)
    except Exception as e:
        print(f"::error title=Base64 Decode Error::Failed to decode keystore base64: {e}")
        sys.exit(1)

    os.makedirs('android/app', exist_ok=True)
    with open('android/app/upload-keystore.jks', 'wb') as f:
        f.write(decoded)

    key_prop = f"storePassword={store_pass}\nkeyPassword={key_pass}\nkeyAlias={key_alias}\nstoreFile=upload-keystore.jks\nstoreType=PKCS12\n"
    with open('android/key.properties', 'w', encoding='utf-8') as f:
        f.write(key_prop)
    with open('android/app/key.properties', 'w', encoding='utf-8') as f:
        f.write(key_prop)

    print(f"Keystore successfully decoded: {len(decoded)} bytes")
    print(f"Configured keyAlias: {key_alias}")

    # Verify with keytool
    res = subprocess.run(
        ['keytool', '-list', '-keystore', 'android/app/upload-keystore.jks', '-storepass', store_pass, '-alias', key_alias],
        capture_output=True,
        text=True
    )
    if res.returncode == 0:
        print("Keystore verification with keytool: SUCCESS!")
    else:
        print(f"::warning title=Keytool Check Warning::{res.stderr}")

if __name__ == '__main__':
    main()
