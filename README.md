# Protein Forge

Game edukasi biologi berbahasa Indonesia: baca kodon mRNA, pilih asam amino yang
tepat, dan rakit rantai peptida pendek. Permainan berjalan di browser, dilayani
oleh Python tanpa dependensi runtime tambahan.

## Menjalankan hasil unduhan ZIP

Ekstrak ZIP, buka terminal di folder hasil ekstraksi, lalu jalankan dengan
Python 3.12 atau lebih baru:

```bash
cd src
python -m protein_forge.server
```

Gunakan `python3` (macOS/Linux) atau `py` (Windows) jika perintah `python`
tidak tersedia. Buka browser pada host lokal komputer Anda, port `8000`.
Cara ini tidak memerlukan instalasi dependensi atau koneksi internet.
Panduan singkat juga tersedia dalam `MULAI_DI_SINI.txt`.

## Persiapan dan menjalankan game

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

Skor maksimum adalah 600. Rekor disimpan di browser perangkat yang sama;
permainan tetap berjalan jika penyimpanan browser tidak tersedia.

Permainan menggunakan **kode genetik standar**: AUG memulai latihan dengan
metionin, empat kodon berikutnya menambahkan residu, dan kodon stop mengakhiri
translasi tanpa menambahkan asam amino. Hasilnya rantai peptida lima residu,
bukan simulasi pelipatan atau pembentukan protein fungsional. Variasi kode
genetik organisme/organel dan modifikasi pascatranslasi tidak dimodelkan.

## Pengujian

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
dependensi dapat disimpan dalam snapshot, tetapi proses server harus dimulai
kembali pada task baru menggunakan instruksi `start_skill`.

Instalasi dependensi menggunakan `pypi.org` dan `files.pythonhosted.org` dengan
verifikasi TLS tetap aktif. Pemeriksaan browser memakai Chromium dari
distribusi resmi Playwright. Penyimpanan draft berbeda dari publikasi lingkungan
dan dari push kode ke GitHub.
