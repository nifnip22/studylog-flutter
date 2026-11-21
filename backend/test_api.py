"""Uji otomatis backend demo Campus Report.

Menjalankan server pada port bebas, lalu memanggil kedua jalur dengan urllib.
Tidak butuh paket tambahan, jadi bisa dijalankan dengan: python test_api.py
"""

import json
import os
import sys
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import app as backend  # noqa: E402


class UjiBackendDemo(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        backend.BERKAS = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "reports_uji.json"
        )
        if os.path.exists(backend.BERKAS):
            os.remove(backend.BERKAS)
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), backend.Handler)
        cls.port = cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        if os.path.exists(backend.BERKAS):
            os.remove(backend.BERKAS)

    def alamat(self, jalur):
        return "http://127.0.0.1:%d%s" % (self.port, jalur)

    def kirim(self, payload):
        permintaan = urllib.request.Request(
            self.alamat("/reports"),
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(permintaan) as respons:
                return respons.status, json.loads(respons.read().decode("utf-8"))
        except urllib.error.HTTPError as galat:
            return galat.code, json.loads(galat.read().decode("utf-8"))

    def contoh(self, client_id="uji-0001"):
        return {
            "clientReportId": client_id,
            "title": "AC ruang IFB5A mati",
            "category": "Pendingin Ruangan",
            "description": "AC menyala tetapi tidak mengeluarkan udara dingin sejak pagi.",
            "priority": "tinggi",
            "createdAt": "2026-11-20T02:15:00Z",
        }

    def test_health_menjawab_ok(self):
        with urllib.request.urlopen(self.alamat("/health")) as respons:
            isi = json.loads(respons.read().decode("utf-8"))
        self.assertEqual(respons.status, 200)
        self.assertEqual(isi["status"], "ok")

    def test_laporan_baru_mendapat_server_id(self):
        kode, isi = self.kirim(self.contoh("uji-0002"))
        self.assertEqual(kode, 201)
        self.assertTrue(isi["serverId"].startswith("SRV-"))

    def test_kirim_ulang_tidak_menduplikasi(self):
        kode1, isi1 = self.kirim(self.contoh("uji-0003"))
        kode2, isi2 = self.kirim(self.contoh("uji-0003"))
        self.assertEqual(kode1, 201)
        self.assertEqual(kode2, 200)
        self.assertEqual(isi1["serverId"], isi2["serverId"])
        self.assertTrue(isi2.get("duplicate"))

        with open(backend.BERKAS, "r", encoding="utf-8") as berkas:
            data = json.load(berkas)
        jumlah = len([d for d in data if d["clientReportId"] == "uji-0003"])
        self.assertEqual(jumlah, 1)

    def test_validasi_gagal(self):
        kode, isi = self.kirim({"clientReportId": "uji-0004", "title": "a"})
        self.assertEqual(kode, 422)
        self.assertIn("error", isi)

    def test_jalur_tidak_dikenal(self):
        try:
            urllib.request.urlopen(self.alamat("/entah"))
            self.fail("seharusnya 404")
        except urllib.error.HTTPError as galat:
            self.assertEqual(galat.code, 404)


if __name__ == "__main__":
    unittest.main(verbosity=2)
