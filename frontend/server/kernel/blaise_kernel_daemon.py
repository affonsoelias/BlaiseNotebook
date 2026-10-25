#!/usr/bin/env python3
"""
BlaiseKernel Daemon - Persistent CPython Session Daemon for BlaiseNotebook
Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

Maintains continuous Python state across cell executions:
- Preserves variables, DataFrames, Models, and imports in memory
- Serves low-latency JSON RPC over local HTTP (127.0.0.1)
- Supports /ping, /exec, /eval, /reset, /shutdown
"""

import sys
import os
import json
import io
import traceback
import argparse
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

# In-memory persistent globals
_SESSION_GLOBALS = {
    '__name__': '__main__',
    '__doc__': 'BlaiseNotebook Persistent Kernel Session',
}

_EXEC_LOCK = threading.Lock()

def _init_session():
    """Initializes or resets the persistent session environment."""
    global _SESSION_GLOBALS
    _SESSION_GLOBALS.clear()
    _SESSION_GLOBALS['__name__'] = '__main__'
    _SESSION_GLOBALS['__doc__'] = 'BlaiseNotebook Persistent Kernel Session'
    
    # Pre-populate common data science imports
    bootstrap_code = """
import sys
import os
import json
try:
    import numpy as np
except ImportError:
    pass
try:
    import pandas as pd
except ImportError:
    pass
"""
    try:
        exec(bootstrap_code, _SESSION_GLOBALS)
    except Exception as e:
        print(f"[BlaiseDaemon] Warning during bootstrap: {e}", file=sys.stderr)

class BlaiseKernelHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress routine HTTP access logs to keep console clean
        pass

    def _send_json(self, status_code, data):
        payload = json.dumps(data).encode('utf-8')
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == '/ping':
            self._send_json(200, {
                'status': 'ok',
                'service': 'BlaiseKernelDaemon',
                'python': sys.version,
                'pid': os.getpid()
            })
        else:
            self._send_json(404, {'status': 'not_found', 'error': 'Unknown endpoint'})

    def do_POST(self):
        content_len = int(self.headers.get('Content-Length', 0))
        raw_body = self.rfile.read(content_len).decode('utf-8') if content_len > 0 else '{}'
        
        try:
            body = json.loads(raw_body)
        except Exception:
            body = {}

        if self.path == '/exec':
            code = body.get('code', '')
            out_buf = io.StringIO()
            err_buf = io.StringIO()
            
            with _EXEC_LOCK:
                old_stdout = sys.stdout
                old_stderr = sys.stderr
                sys.stdout = out_buf
                sys.stderr = err_buf
                success = True
                err_msg = ''
                try:
                    exec(code, _SESSION_GLOBALS)
                except Exception:
                    success = False
                    err_msg = traceback.format_exc()
                finally:
                    sys.stdout = old_stdout
                    sys.stderr = old_stderr

            self._send_json(200, {
                'status': 'ok' if success else 'error',
                'stdout': out_buf.getvalue(),
                'stderr': err_buf.getvalue(),
                'error': err_msg
            })

        elif self.path == '/eval':
            expr = body.get('expr', '')
            val_str = ''
            success = True
            err_msg = ''
            with _EXEC_LOCK:
                try:
                    val = eval(expr, _SESSION_GLOBALS)
                    val_str = str(val) if val is not None else ''
                except Exception:
                    success = False
                    err_msg = traceback.format_exc()

            self._send_json(200, {
                'status': 'ok' if success else 'error',
                'value': val_str,
                'error': err_msg
            })

        elif self.path == '/reset':
            with _EXEC_LOCK:
                _init_session()
            self._send_json(200, {'status': 'reset', 'message': 'Kernel state cleared'})

        elif self.path == '/shutdown':
            self._send_json(200, {'status': 'shutting_down'})
            threading.Thread(target=self.server.shutdown, daemon=True).start()

        else:
            self._send_json(404, {'status': 'not_found', 'error': 'Unknown endpoint'})

def run_daemon(host='127.0.0.1', port=9099):
    _init_session()
    server_address = (host, port)
    httpd = HTTPServer(server_address, BlaiseKernelHandler)
    print(f"[BlaiseDaemon] Persistent Kernel running on http://{host}:{port} (PID: {os.getpid()})")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("[BlaiseDaemon] Shutting down...")
    finally:
        httpd.server_close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='BlaiseNotebook Persistent Kernel Daemon')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=9099, help='Port to bind (default: 9099)')
    args = parser.parse_args()
    run_daemon(args.host, args.port)
