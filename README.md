# Protein Forge

Game edukasi biologi berbahasa Indonesia: baca kodon mRNA, pilih asam amino yang
tepat, dan rakit rantai peptida pendek. Versi utama sekarang merupakan proyek
native **Godot 4**, dengan antarmuka dan logika permainan dalam GDScript.

## Buka dan jalankan di Godot

1. Ekstrak ZIP proyek.
2. Jalankan **Godot 4.6.x** (diuji menggunakan Godot 4.6.3).
3. Di Project Manager, pilih **Import** dan pilih berkas **project.godot**
   pada folder utama hasil ekstraksi.
4. Buka proyek, lalu tekan **F5** atau tombol **Run Project**.
5. Pilih **Mulai merakit** untuk bermain.

Versi Godot berjalan secara lokal tanpa Python, browser, server, plugin,
koneksi internet, atau aset tambahan. Scene utama berada di
`godot/scenes/main.tscn`; logika sesi ada di `godot/scripts/game_session.gd`.
Gunakan mouse atau keyboard untuk memilih jawaban dan tombol Escape untuk
menutup tabel kodon. Rekor disimpan melalui `user://` milik Godot.

Proyek menggunakan renderer **Compatibility**. Tidak perlu melakukan export
atau memasang export templates untuk menjalankannya dari editor.

### Pengujian Godot

Di lingkungan cloud yang sudah menyediakan Godot:

```bash
cd /workspace/Protein_Forge
bash scripts/check-godot.sh
```

Skrip melakukan import proyek, menguji kode genetik dan aturan permainan,
lalu menjalankan scene asli untuk menguji alur tombol, skor, STOP, main ulang,
tabel kodon, dan penyimpanan rekor. `GODOT_BIN` dapat digunakan untuk memilih
lokasi executable Godot. Saat dipakai di luar cloud, arahkan `XDG_CACHE_HOME`
dan `XDG_DATA_HOME` ke direktori yang dapat ditulis.

## Versi web Python (opsional)

Ekstrak ZIP, buka terminal di folder hasil ekstraksi, lalu jalankan dengan
Python 3.12 atau lebih baru:

```bash
cd src
python -m protein_forge.server
```

Gunakan `python3` (macOS/Linux) atau `py` (Windows) jika perintah `python`
tidak tersedia. Buka browser pada host lokal komputer Anda, port `8000`.
Cara ini tidak memerlukan instalasi dependensi atau koneksi internet.
Versi web lama tetap tersedia sebagai alternatif; tidak diperlukan untuk Godot.

## Setup pengembangan versi web (opsional)

Gunakan Python 3.12 dan `uv`, yang sudah tersedia di lingkungan cloud ini.

```bash
cd /workspace/Protein_Forge
bash scripts/setup.sh
bash scripts/start.sh
```

Server memakai port `8000`. `PROTEIN_FORGE_HOST` dan `PROTEIN_FORGE_PORT` dapat
diatur sebelum menjalankan skrip; nilai default masing-masing `0.0.0.0` dan
`8000`. Hentikan server dengan Ctrl+C. Tidak diperlukan akun, database, API key,
atau GPU. Server tidak memerlukan internet saat dimainkan.

Skrip setup memasang paket ke `.venv` memakai `uv.lock`, memeriksa kompatibilitas
dependensi, menjalankan tes Python, membuat paket di `dist/`, dan memeriksa CLI.
Skrip dapat diulang tanpa mengubah sumber atau lockfile. Di luar cloud,
arahkan `UV_CACHE_DIR` ke direktori cache yang dapat ditulis jika diperlukan.

## Cara bermain

1. Pilih **Mulai merakit** untuk memulai enam ronde.
2. Baca tiga basa pada kodon mRNA dan pilih satu dari empat jawaban.
3. Jawaban benar pada percobaan pertama bernilai 100 poin. Jika sebelumnya
   salah pada ronde itu, jawaban benar bernilai 50 poin. Tidak ada batas waktu.
4. Baca penjelasan sebelum melanjutkan. Tabel kodon dapat dibuka sebagai bantuan.
5. Akhiri translasi pada kodon stop, lihat hasil, lalu mainkan rantai baru.

Skor maksimum adalah 600. Rekor disimpan secara lokal: melalui `user://` pada
Godot atau penyimpanan browser pada versi web.

Permainan menggunakan **kode genetik standar**: AUG memulai latihan dengan
metionin, empat kodon berikutnya menambahkan residu, dan kodon stop mengakhiri
translasi tanpa menambahkan asam amino. Hasilnya rantai peptida lima residu,
bukan simulasi pelipatan atau pembentukan protein fungsional. Variasi kode
genetik organisme/organel dan modifikasi pascatranslasi tidak dimodelkan.

## Pengujian versi web

```bash
cd /workspace/Protein_Forge
.venv/bin/python -m pytest -q
```

Tes mencakup 64 kodon, pemetaan asam amino, pembentukan soal, validasi urutan,
CLI, dan respons HTTP. Aset HTML/CSS/JavaScript ikut dimasukkan ke paket wheel,
sehingga game juga dapat dijalankan dari instalasi paket di luar checkout.

Untuk menguji alur browser, jalankan server terlebih dahulu, lalu:

```bash
cd /workspace/Protein_Forge
bash scripts/setup-browser.sh
node scripts/check-game.cjs
```

Pemeriksaan browser memakai Playwright dan Chromium yang disediakan dalam
lingkungan pengembangan ini. Chromium berada di
`/workspace/.cache/ms-playwright`; lokasi lain dapat ditentukan melalui
`PLAYWRIGHT_BROWSERS_PATH`. Di luar lingkungan ini, sediakan Node.js,
Playwright, dan browser Chromium yang sesuai terlebih dahulu. URL pengujian
dapat diatur melalui `PROTEIN_FORGE_TEST_URL`.

## CLI validasi protein

CLI awal tetap tersedia:

```bash
.venv/bin/protein-forge " acd ef "
```

Hasilnya `{"sequence": "ACDEF", "length": 5}`. Validasi menerima 20 kode asam
amino kanonik, mengabaikan whitespace, dan menormalkan huruf menjadi kapital.
Input kosong, residu ambigu/nonkanonik, simbol stop, dan header FASTA ditolak.

## Lingkungan cloud

Gunakan checkout `/workspace/Protein_Forge` yang sudah tersedia. Setiap task
cloud terisolasi; tidak perlu membuat Git worktree kecuali diminta. File dan
dependensi dapat disimpan dalam snapshot. Untuk versi Godot, buka proyek dengan
engine Godot; tidak ada layanan server yang perlu dijalankan. Jika memakai
versi web, mulai kembali server pada task baru.

Instalasi dependensi menggunakan `pypi.org` dan `files.pythonhosted.org` dengan
verifikasi TLS tetap aktif. Pemeriksaan browser memakai Chromium dari
distribusi resmi Playwright. Penyimpanan draft berbeda dari publikasi lingkungan
dan dari push kode ke GitHub.
