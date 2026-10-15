#!/usr/bin/env python3
"""Fail-closed parser for real Android WebView GLB framebuffer QA logcat.

reactivecircus/android-emulator-runner invokes script commands separately via sh -c.
"""
import json
import sys
from pathlib import Path

def verify(log: str) -> dict:
    if 'ALPHA_WEBGL_LAB_QA true' not in log:
        raise AssertionError('Android WebView WebGL2 context not confirmed')
    if 'ALPHA_ANDROID_MODEL_QA_FAIL' in log:
        raise AssertionError('Android GLB loader or GPU reported explicit FAIL')
    lines = [line.split('ALPHA_ANDROID_MODEL_QA ', 1)[1].strip()
             for line in log.splitlines() if 'ALPHA_ANDROID_MODEL_QA {' in line]
    if not lines:
        raise AssertionError('Missing real Android GPU framebuffer report')
    result = json.loads(lines[-1])
    assert result['ready'] is True, result
    assert result['face'] == 11 and result['front'] == 11, result
    assert result['parts'] == 21 and result['triangles'] == 40, result
    assert result['bright'] >= 16, result
    assert result['glError'] == 0, result
    return result

if __name__ == '__main__':
    assert len(sys.argv) == 2, 'Usage: check_android_gpu_qa.py native-webgl.log'
    result = verify(Path(sys.argv[1]).read_text())
    print('PASS_REAL_ANDROID_WEBVIEW_GLTF_20_FACES_GPU_PIXELS', json.dumps(result))
