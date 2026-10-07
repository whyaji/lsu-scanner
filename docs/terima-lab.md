# Terima Lab

Terima Lab menerima sampel pupuk yang sudah dikirim ke laboratorium. Fitur bekerja offline terlebih dahulu. Data tersimpan di SQLite, lalu dikirim ke SampleTrack ketika pengguna memilih unggah.

## Alur pengguna

1. Pengguna membuka `Terima Lab` dari halaman Sampel Pupuk.
2. Pengguna memindai satu atau lebih QR label pupuk.
3. Nomor surat mengikuti sampel sistem pertama.
4. Pengguna menambahkan kode manual jika kode belum ada di SampleTrack.
5. Pengguna mengisi lima langkah form.
6. Pengguna meninjau data dan foto, lalu memilih `Simpan penerimaan`.
7. Aplikasi menyimpan satu receipt lokal dengan satu `clientUuid`.
8. Saat jaringan tersedia, pengguna memilih `Unggah Semua`.
9. SampleTrack memvalidasi receipt, meneruskan form ke SmartLab, lalu memperbarui tracking sampel sistem.

## Layar

| Layar | Tanggung jawab |
| --- | --- |
| `PupukLabReceiveScreen` | Wizard lima langkah dan penyimpanan offline |
| `PupukLabScanScreen` | Satu pemindaian per sampel, kamera menutup setelah label diterima |
| `PupukLabPhotoScreen` | Foto label atau penerimaan |
| `PupukLabDetailScreen` | Detail lokal, status unggah, edit dan hapus |
| `UploadSampelPupukScreen` | Mengirim receipt tertunda dan menampilkan hasil |

## Status receipt

```text
not_uploaded
    |
    | unggah berhasil
    v
uploaded

not_uploaded
    |
    | validasi gagal permanen
    v
error (needsEdit)

not_uploaded
    |
    | jaringan, timeout atau SmartLab 5xx
    v
error (retryable)
```

Receipt `error` dengan `retryable = false` tidak dikirim ulang. Pengguna harus mengedit receipt. Edit menghapus error dan mengembalikan status `not_uploaded`.

## Validasi utama

| Aturan | Hasil |
| --- | --- |
| QR harus berisi lima bagian dipisahkan `^` | Dialog error |
| Sampel sistem harus ada di sync lokal | Tawarkan sinkronisasi |
| Sampel harus sudah melalui Kirim Lab | Dialog peringatan |
| Sampel tidak boleh sudah diterima | Dialog peringatan |
| Kode tidak boleh duplikat dalam receipt | Toast info |
| Kode tidak boleh ada di receipt lokal lain | Dialog peringatan |
| Semua sampel sistem harus memiliki nomor surat yang sama | Dialog peringatan dengan nomor surat |
| Kode manual harus unik dan tidak sama dengan kode sistem | Error form |
| Jumlah kode harus sama dengan `jumlah_sampel` | Error form |
| Parameter tidak boleh dipilih dua kali | Error form |
| Kode parameter harus berasal dari receipt | Error form |
| Estimasi KUPA tidak boleh sebelum tanggal terima | Error form |
| Foto maksimal lima file | Error form |

## Pemetaan data

| Mobile | SampleTrack API | SmartLab |
| --- | --- | --- |
| `clientUuid` | `pupukLab[].clientUuid` | `external_ref` |
| `noSurat` | `pupukLab[].noSurat` | `nomor_surat` |
| `samples[].kodeSampel` | `samples[].kodeSampel` | `kode_sampel[]` |
| `jenisSampelId` | `form.jenisSampelId` | `jenis_sampel` |
| `jenisPupuk` | `form.jenisPupuk` | `jenis_pupuk` |
| `statusPengerjaan` | `form.statusPengerjaan` | `status_pengerjaan` |
| `tanggalMemo` | `form.tanggalMemo` | `tanggal_memo` |
| `tanggalTerima` | `form.tanggalTerima` | `tanggal_terima` |
| `estimasiKupa` | `form.estimasiKupa` | `estimasi` |
| `namaPengirim` | `form.namaPengirim` | `nama_pengirim` |
| `departemen` | `form.departemen` | `departemen` |
| `parameters[]` | `form.parameters[]` | `track_parameter` |
| `fotoPaths` | `fotoPaths[]` | `foto_sampel` |

Nomor lab, nomor KUPA dan kode tracking ditetapkan SmartLab. Aplikasi tidak membuat nomor tersebut secara offline.

## Penanganan unggah

- HTTP 422: data permanen tidak valid. Aplikasi menyimpan alasan dan meminta pengguna mengedit.
- HTTP 401: konfigurasi API key salah. Perbaiki konfigurasi server, lalu unggah ulang.
- HTTP 5xx, timeout atau jaringan putus: receipt tetap dapat dicoba lagi.
- `external_ref` mencegah SmartLab membuat dua `track_sampel` untuk satu receipt.
- Setelah SmartLab berhasil, SampleTrack mengisi tuple tracking index 4 dengan tanggal terima dan menyimpan `pupuk_lab_terima_id`.

## Checklist uji manual

- [ ] Sinkronkan master SmartLab sampai form dapat dibuka.
- [ ] Pindai dua sampel sistem dari nomor surat yang sama.
- [ ] Pindai sampel dari nomor surat berbeda. Pastikan dialog menjelaskan perbedaan dan sampel tidak masuk daftar.
- [ ] Tambahkan satu kode manual.
- [ ] Isi form tanpa jaringan.
- [ ] Simpan penerimaan dan pastikan receipt muncul di daftar Menunggu.
- [ ] Unggah saat jaringan tersedia.
- [ ] Pastikan hasil menampilkan kode track, nomor lab dan nomor KUPA.
- [ ] Pastikan row `track_sampel` muncul di SmartLab.
- [ ] Pastikan tuple index 4 dan `tanggal_registrasi_lab` terisi di SampleTrack.
- [ ] Putuskan jaringan saat unggah. Pastikan receipt dapat dicoba lagi.
- [ ] Kirim data form tidak valid. Pastikan receipt ditandai perlu diedit dan tidak diulang otomatis.
# Terima Lab (Pupuk Lab)

Terima Lab is the step after Kirim Lab. The lab receives the physical sample, scans its label, fills the SmartLab intake form on the phone, and the data travels to SampleTrack and on to SmartLab as a new `track_sampel` row. It works offline: nothing on the way to "Simpan penerimaan" needs a network.

Who sees it: users with the permission `pupuk:mobile-pupuk-lab` (role `Pupuk Lab`). A lab-only account has no regional to pick, because the samples it can receive come from every regional.

## User flow

1. Home, `Aktivitas`, `Terima Lab` opens the wizard.
2. **Sampel.** `Pindai label` opens the camera for one sample. When a label is accepted the camera closes and the sample appears in the list; tap `Pindai label` again for the next one. A rejected label keeps the camera open. Or type a code (`Ketik kode`) for a sample that does not exist in SampleTrack yet. The no. surat fills from the first scanned sample.
3. **Informasi.** Jenis komoditas, jenis pupuk, status pengerjaan, asal sampel, dates, kemasan, kondisi, tujuan, prioritas, peralatan.
4. **Pengirim.** Sender, department, lab staff, customer emails, WhatsApp numbers, discount, confirmation switch, KUPA document numbers.
5. **Parameter.** Rows of analysis parameters: which parameter, how many tests, on which samples.
6. **Ringkasan.** Read the summary, add up to 5 photos and a note, `Simpan penerimaan`.
7. The receipt is stored in SQLite with status `not_uploaded`. `Unggah sekarang` goes to the upload screen; `Nanti saja` returns home.

A receipt can be edited or deleted until SmartLab accepted it.

## Rules the form enforces

| Rule | Where | Why |
| --- | --- | --- |
| One receipt, one no. surat | scan resolver | SmartLab stores one `nomor_surat` per `track_sampel` row |
| A scanned sample with another no. surat is refused, with both numbers named | `PupukLabScanResolver` | The user then saves this receipt and starts a second one |
| A sample must have Kirim Lab recorded and no Terima Lab | `pupukLabEligibility` | The tracking tuple index 3 set, index 4 empty |
| A sample held by another local receipt is refused | `getReservedKodeSampel` | Uploaded receipts still count until the next sync stamps the record |
| A manual code may not equal a SampleTrack code (ABCD parents expand to A, B, C, D) | `PupukLabScanResolver.isSystemKode` | SmartLab would get two rows for one sample |
| Manual code: 2 to 100 characters, `' " \ $` and control characters removed | `PupukLabDraftNotifier.addManual` | Same cleanup SmartLab applies |
| Tanggal terima follows the memo date, one day later from 12:00, until the user picks a date | `PupukLabForm.defaultTanggalTerima` | Same as the web form |
| Estimasi KUPA is not before tanggal terima | `validatePupukLabForm` | SmartLab rule |
| Each parameter once, quantity 1 to 1000, at least one sample, only samples of this receipt | `validatePupukLabForm` | SmartLab rule |
| Text lengths follow the `track_sampel` column widths | `PupukLabLimits` | A longer value would be a permanent 422 after the user has left the lab |
| WhatsApp numbers: `08` becomes `628`, 10 to 15 digits | `normalizeWaPhone` | SmartLab `numberformat_excel` |

Nomor kupa and nomor lab are not in the form. SmartLab assigns them when the data arrives, so the summary says so.

## Screens and files

| Screen | File | Notes |
| --- | --- | --- |
| Wizard | `features/pupuk_lab/screens/pupuk_lab_receive_screen.dart` | Hosts the five steps, back confirmation, save |
| Steps | `features/pupuk_lab/widgets/steps/` | One widget per step, all read the same draft |
| Scanner | `features/pupuk_lab/screens/pupuk_lab_scan_screen.dart` | Keeps scanning after each label, one dialog per problem |
| Photo | `features/pupuk_lab/screens/pupuk_lab_photo_screen.dart` | Camera, stamp, compress, save |
| Detail | `features/pupuk_lab/screens/pupuk_lab_detail_screen.dart` | Saved receipt, SmartLab result, edit and delete |
| List row | `features/pupuk_lab/widgets/pupuk_lab_list_tile.dart` | Used by lists of local rows |
| Shared camera view | `widgets/scanner/qr_scan_view.dart` | Torch, framing guide, permission recovery, repeat throttle |

## State

`PupukLabDraft` (immutable) holds everything typed so far. `PupukLabDraftNotifier` (`pupukLabDraftProvider`, auto dispose) changes it:

- `start(draft)`: the screen calls it once the master data is loaded.
- `addScanned`, `addManual`, `removeSample`
- `setJenis`, `setMemo`, `setTanggalTerima`
- `addParameter`, `updateParameter`, `removeParameter`
- `addPhoto`, `removePhoto`
- `patch(change)` for plain fields
- `save(master)`: validates, inserts or updates through `PupukLabDao`, refreshes the reserved codes and the home counts

`PupukLabDraft.validate(master)` returns errors keyed by field. `errorsOf(step, master)` keeps the ones that belong to a step (`pupukLabStepOfError`). Untouched pickers say "Pilih ..." instead of "tidak valid".

Reason for an immutable draft in one notifier instead of controllers per field: validation, step gating, the review summary and the saved receipt all need the same values, and the tests can drive the whole form without a widget.

## Data mapping

| Form field | `PupukLabForm` key | SmartLab request field | `track_sampel` column |
| --- | --- | --- | --- |
| No. surat | receipt `noSurat` | `nomor_surat` | `nomor_surat` |
| Sampel (codes) | receipt `samples` | `kode_sampel[]` | `kode_sampel`, joined with `$` |
| Jumlah sampel | not sent by the form | `jumlah_sampel` (count of codes) | `jumlah_sampel` |
| Jenis komoditas | `jenisSampelId` | `jenis_sampel` | `jenis_sampel` |
| Jenis pupuk | `jenisPupuk` | `jenis_pupuk` | `jenis_pupuk` |
| Status pengerjaan | `statusPengerjaan` | `status_pengerjaan` | `progress` |
| Asal sampel | `asalSampel` | `asal_sampel` | `asal_sampel` |
| Tanggal memo | `tanggalMemo` | `tanggal_memo` | `tanggal_memo` |
| Tanggal terima | `tanggalTerima` | `tanggal_terima` | `tanggal_terima` |
| Estimasi KUPA | `estimasiKupa` | `estimasi` | `estimasi` |
| Nama pengirim | `namaPengirim` | `nama_pengirim` | `nama_pengirim` |
| Departemen | `departemen` | `departemen` | `departemen` |
| Kemasan sampel | `kemasanSampel` | `kemasan_sampel` | `kemasan_sampel` |
| Kondisi sampel | `kondisiSampel` | `kondisi_sampel` | `kondisi_sampel` |
| Tujuan | `tujuan` | `tujuan` | `tujuan` |
| Skala prioritas | `skalaPrioritas` | `skala_prioritas` | `skala_prioritas` |
| Peralatan | `peralatan` | `peralatan[]` | `personel`, `alat`, `bahan` |
| Penerima sampel | `penerimaSampel` | `penerima_sampel` | `penerima_sampel` |
| Petugas preparasi | `petugasPreperasi` | `petugas_preperasi` | `petugas_preparasi` |
| Penyelia | `penyelia` | `penyelia` | `penyelia` |
| Dokumen KUPA | `noDocument`, `noDocumentIdentitas`, `namaFormulir` | `no_document`, `no_document_indentitas`, `nama_formulir` | `no_doc`, `no_doc_indentitas`, `formulir` |
| Email tujuan, CC | `emailTo`, `emailCc` | `email_to[]`, `email_cc[]` | `emailTo`, `emailCc` |
| Diskon | `diskon` | `diskon` | `discount` |
| Konfirmasi | `konfirmasi` | `konfirmasi` | `konfirmasi` |
| WhatsApp | `noHp` | `no_hp[]` | `no_hp` |
| Parameter | `parameters[]` | `parameters[]` | `track_parameter` rows |
| Catatan | `catatan` | `catatan` | `catatan` |
| Foto | receipt `fotoPaths` | `fotos[]` | `foto_sampel` |
| (server) | | | `nomor_kupa`, `nomor_lab`, `kode_track`, `lab_label_tahun` |

The JSON the app stores in `form_json` is exactly what `POST /data-sampel-pupuk/upload` carries, so the camelCase keys above are the contract with the SampleTrack backend (see `sampletrack/docs/MOBILE-SAMPEL-PUPUK-API-DOCS.md`).

## Upload and failure handling

Photos go first, one request each to `/upload/photo-pupuk-lab`, then the receipt travels in `pupukLab[]` with its `clientUuid` as idempotency key. The server answers per receipt.

| Server answer | Receipt status | Next upload |
| --- | --- | --- |
| Accepted, with `kodeTrack`, `nomorLab`, `nomorKupa` | `uploaded` | not sent |
| Accepted as `duplicate` (an earlier request already worked) | `uploaded` | not sent |
| Failed, `retryable: true` (SmartLab down, timeout) | `error`, retryable | sent again, same `clientUuid` |
| Failed, `retryable: false` (SmartLab rejected the data, sample already received, other no. surat) | `error`, `error_retryable = 0` | skipped, photos included, until the receipt is edited |
| Photo upload failed twice | `error`, retryable | sent again |

Saving an edit (`PupukLabDao.updateDraft`) puts the receipt back to `not_uploaded` and `error_retryable = 1`, keeps `client_uuid`, and the next upload sends it.

The detail screen says which of these applies and what to do. A rejected receipt shows the server message and `Ubah penerimaan`.

## Offline and master data

The form needs the SmartLab lists (komoditas, status, parameter, departemen, options). They come with the pupuk sync and are cached in `pupuk_lab_master`. Without a cached master the wizard shows "Data master SmartLab belum ada" with `Sinkronkan sekarang`. An old master (server flag or older than 24 hours) shows a warning banner and the form stays usable.

## Tests

`flutter test test/features/pupuk_lab` covers: draft defaults, validation messages and step mapping, notifier rules (first sample sets no. surat, manual code rules, parameter pruning, date rule, save and edit), the scan resolver against a real SQLite database, and the wizard screen in light and dark at 360x640 and text scale 1.3. `test/widgets/scanner` covers the camera view wrapper.

Not covered by tests: the real camera, the real photo pipeline, and a round trip against SmartLab. Check those on a device before a release.
