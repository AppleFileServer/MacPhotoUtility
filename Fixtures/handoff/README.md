# Handoff fixtures

Made by `mpu fixtures` (MacPhoto Utility D-0.0.3) from the
generated test images, so nothing private. FILE_FORMATS.md §5: the
Macintosh Transfer Utility copies these into its own tests and never
writes here. Every `bad-` file has exactly one thing wrong with it,
listed below; MacPhoto's validators refuse each one (a test checks).

The print PICTs are made of test patterns, so they pack far smaller
than photographs do (about 1.1 MB at 360 PPI).

| File | Tests | Valid | Bytes | SHA-256 |
|---|---|---|---:|---|
| `print-portrait-300.pict` | 8-bit print PICT, 750 × 1050, 300 PPI, portrait | yes | 110234 | `59057e669fc43a917388915e16878b6ded0e45af09f064d3cfa984422b817328` |
| `print-portrait-360.pict` | 8-bit print PICT, 900 × 1260, 360 PPI, portrait | yes | 136364 | `27f7202d97a303e4beab515fcb72e5e4195ddb44285b7c298e77bd8a7eb743a5` |
| `print-landscape-300.pict` | 8-bit print PICT, 1050 × 750, 300 PPI, landscape | yes | 72416 | `932b043690463c9bbca7840622bbdac69e705445c5e047ba9b59541c233336a1` |
| `print-landscape-360.pict` | 8-bit print PICT, 1260 × 900, 360 PPI, landscape | yes | 105276 | `07a077a06c8e4caef269b8415e0ca5a081f4caab54fa524976444dffff140d14` |
| `screen.pict` | 1-bit screen PICT | yes | 13066 | `221650390232b116a7ead6d3d5d8d5e8cda3e4d2e90662d431502c6c3653b1d3` |
| `screen-ramp.pict` | 1-bit screen PICT, dithered grey ramp (packs badly) | yes | 17394 | `e161b1dcc0fc1416874bbe193e65bcb6215210dbc1153ab4546a9066a14b744a` |
| `macpaint.MAC` | MacPaint, screen image centred | yes | 13824 | `d92b6f99faa99fc94d3ecfc791fa1e7d1bfc65e15fe47889242481fd21f76015` |
| `macpaint-ramp.MAC` | MacPaint, dithered grey ramp | yes | 18944 | `c8cf788a72136ef0463f456dc1b454a01173ba16d3ead4454103f24f625c19e7` |
| `bad-print-truncated.pict` | cut short in the pixel rows | **no** | 48278 | `c3c92dbcadbce24db3b15311d6728862a5ab9bae3758b83e3aade35a88e68e82` |
| `bad-print-header.pict` | 512-byte header not all zeros | **no** | 72416 | `1ad158756357b94f7e46419aec6c8e6afc749c9f273ca4943a01cb7b820ba46a` |
| `bad-print-version.pict` | version 02FF changed to 01FF | **no** | 72416 | `b939f1e7d3944c3170a74812d8631ccbaeb6bf9a26ea049fcf6e584f63bec584` |
| `bad-print-size.pict` | picFrame 1000 × 750, not a print size | **no** | 72416 | `c5aef09902a058d6a52c0ca60cb5d1512e3674a78a277ad89207e24cac130332` |
| `bad-print-colour-table.pict` | colour 128's red changed | **no** | 72416 | `3ab6c5e1f5e78c6a914c47b885fe4f529257c4707ab6ab21eaef94e632b4692d` |
| `bad-print-row-length.pict` | row 0's length one more than its data | **no** | 72416 | `1758030432cc5a3b58e068c0459fabde89f69943309b01770a51d5c48ba165c9` |
| `bad-print-crc.pict` | MacPhoto's record's CRC-32 wrong | **no** | 72416 | `7b9a777bcc77786d11f5a1b966a11fb5f8bc2773ede809b55bc94f7d5af015e9` |
| `bad-print-pixels.pict` | one pixel changed (only the CRC-32 notices) | **no** | 72416 | `ac619edd349f17a11551688aeb089660ec58c69f47e4e55da7cfc544b59003dc` |
| `bad-screen-truncated.pict` | cut short | **no** | 11066 | `f365bb49848324b7b98cb2fefbce030b6bae0361d15a4b0522808844fbfa8c67` |
| `bad-screen-picsize.pict` | picSize one too big | **no** | 13066 | `de745ea40850372de8105af8b7067d07c1cfcbaecdb5b77c40d7d9c478bba6b4` |
| `bad-screen-rowbytes.pict` | rowBytes 72, not 64 | **no** | 13066 | `8af595b192fcc562123a488bd66d7af9afd1d8250efb0e7af31d927321acef22` |
| `bad-screen-end.pict` | no FF at the end | **no** | 13066 | `60e8b6a229efbf0a64757edd2b21951b7611e2775ccb05c72cbb7e3ae5cdc829` |
| `bad-macpaint-version.MAC` | header version 2 (would replace the user's patterns) | **no** | 13824 | `1c012d2944e896a12c672fe9be8c90fe2e9de518ba8d520d89aa9ad9edd81f5d` |
| `bad-macpaint-row-length.MAC` | row 0 unpacks to 73 bytes (MacPaint beeps) | **no** | 13824 | `930de31088397c75a94b7974c3f1ca9f2585697b92676835afe4eaa2dfc3f870` |
| `bad-macpaint-outside.MAC` | a dot outside the centred image (MacPhoto's placement rule) | **no** | 13824 | `ea74232d6b19203b968751c3acedc859ed2ba28b1b6eedb6b4699e2cc3e7e212` |
| `bad-macpaint-padding.MAC` | not a multiple of 512 bytes | **no** | 13825 | `fc33b567db21825bafbc6228dc1852e488c091d84eeb2073f7474fa8c012d882` |
| `bad-not-a-picture.pict` | text, not a picture | **no** | 23 | `9f313ba6ae4e11a52fce33d9484f829d813a66758b98399d778922cc57eb08c4` |
