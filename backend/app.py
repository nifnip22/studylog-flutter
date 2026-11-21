"""Backend demo Campus Report.

Menjalankan dua jalur:
  GET  /health    memeriksa apakah server hidup
  POST /reports   menerima laporan dari aplikasi

Data disimpan pada berkas reports.json di direktori yang sama supaya
isinya bisa diperiksa langsung, dan bisa dihapus untuk mengulang pengujian
dari keadaan kosong.

Jalankan dengan: python app.py
"""

import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))
BERKAS = os.path.join(ROOT, "reports.json")
KUNCI = threading.Lock()
PORT = int(os.environ.get("PORT", "8000"))


def muat():
    if not os.path.exists(BERKAS):
        return []
    with open(BERKAS, "r", encoding="utf-8") as berkas:
        isi = berkas.read().strip()
    if not isi:
        return []
    return json.loads(isi)


def simpan(data):
    with open(BERKAS, "w", encoding="utf-8") as berkas:
        json.dump(data, berkas, ensure_ascii=False, indent=2)


def id_server(data):
    return "SRV-%06d" % (len(data) + 1)


def validasi(payload):
    pesan = []
    for kolom in ("clientReportId", "title", "category", "description"):
        nilai = payload.get(kolom)
        if not isinstance(nilai, str) or not nilai.strip():
            pesan.append("%s wajib diisi" % kolom)
    if isinstance(payload.get("title"), str) and len(payload["title"].strip()) < 6:
        pesan.append("title terlalu pendek")
    if isinstance(payload.get("description"), str) and len(payload["description"].strip()) < 20:
        pesan.append("description terlalu pendek")
    return pesan


class Handler(BaseHTTPRequestHandler):
    server_version = "CampusReportDemo/1.0"

    def log_message(self, format, *args):
        print("[backend] " + (format % args))

    def _kirim(self, kode, isi):
        badan = json.dumps(isi, ensure_ascii=False).encode("utf-8")
        self.send_response(kode)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(badan)))
        self.end_headers()
        self.wfile.write(badan)

    def do_GET(self):
        if self.path.split("?")[0] != "/health":
            self._kirim(404, {"error": "jalur tidak dikenal"})
            return
        with KUNCI:
            data = muat()
        self._kirim(200, {"status": "ok", "jumlah": len(data)})

    def do_POST(self):
        if self.path.split("?")[0] != "/reports":
            self._kirim(404, {"error": "jalur tidak dikenal"})
            return

        panjang = int(self.headers.get("Content-Length", "0"))
        mentah = self.rfile.read(panjang).decode("utf-8") if panjang else ""
        try:
            payload = json.loads(mentah) if mentah else {}
        except json.JSONDecodeError:
            self._kirim(400, {"error": "badan permintaan bukan JSON"})
            return
        if not isinstance(payload, dict):
            self._kirim(400, {"error": "badan permintaan harus objek JSON"})
            return

        masalah = validasi(payload)
        if masalah:
            self._kirim(422, {"error": "; ".join(masalah)})
            return

        client_id = payload["clientReportId"]
        with KUNCI:
            data = muat()
            for entri in data:
                if entri["clientReportId"] == client_id:
                    self._kirim(
                        200,
                        {
                            "serverId": entri["serverId"],
                            "clientReportId": client_id,
                            "duplicate": True,
                        },
                    )
                    return

            entri = {
                "serverId": id_server(data),
                "clientReportId": client_id,
                "title": payload["title"],
                "category": payload["category"],
                "description": payload["description"],
                "priority": payload.get("priority", "sedang"),
                "createdAt": payload.get("createdAt"),
                "latitude": payload.get("latitude"),
                "longitude": payload.get("longitude"),
                "punyaFoto": bool(payload.get("photoBase64")),
            }
            data.append(entri)
            simpan(data)

        self._kirim(201, {"serverId": entri["serverId"], "clientReportId": client_id})


def jalankan(port=PORT):
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("Backend demo Campus Report berjalan di http://0.0.0.0:%d" % port)
    print("Periksa lewat browser: http://127.0.0.1:%d/health" % port)
    print("Data tersimpan di: %s" % BERKAS)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nBackend dihentikan.")
    finally:
        server.server_close()


if __name__ == "__main__":
    jalankan()
