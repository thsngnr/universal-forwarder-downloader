# Universal Forwarder Downloader

Splunk Universal Forwarder'ın Linux (amd64) `.tgz` paketlerini indirmek için
küçük bir bash aracı. Hangi versiyonu indirmek istediğinizi bir menüden
seçersiniz, script de doğru build hash'ini bulup paketi doğrudan
`download.splunk.com`'dan çeker.

![Menü önizlemesi](docs/menu-preview.svg)

> Yukarıdaki görsel, script'in `whiptail` ile açtığı seçim menüsünün
> örnek/temsili bir görünümüdür (gerçek terminalden alınmış bir ekran
> görüntüsü değildir) — gerçek görünüm terminaliniza ve `whiptail`/`dialog`
> temanıza göre küçük farklılıklar gösterebilir.

## Kullanım

```bash
./uf-downloader.sh                # menüden versiyon seç
./uf-downloader.sh 10.4.3         # versiyonu doğrudan argümanla ver
./uf-downloader.sh 10.4.3 /opt    # ...ve indirme klasörünü belirt
```

Argümansız çalıştırıldığında:

1. `version.list` içindeki versiyonları en yeniden en eskiye doğru bir menüde listeler.
2. Sistemde varsa `whiptail`, yoksa `dialog`, o da yoksa düz numaralı bir `select` menüsü kullanılır — yani script `whiptail`/`dialog` kurulu olmayan bir host'ta da çalışır.
3. Seçilen versiyonun build hash'ini `version.list`'ten bulur.
4. `https://download.splunk.com/products/universalforwarder/releases/<version>/linux/splunkforwarder-<version>-<build>-linux-amd64.tgz` adresinden indirir.
5. İndirilen dosyanın boş olmadığını doğrular; hata varsa yarım kalan dosyayı siler.

## version.list

`version.list`, Splunk'ın sitesinde (güncel + previous-releases sayfaları)
hâlâ gerçekten yayında olan Universal Forwarder versiyon/build hash
eşleşmelerini içerir (CSV: `version,build`). Artık indirilemeyen eski
versiyonlar listede tutulmaz — yeni bir Splunk sürümü çıktığında bu dosyayı
güncellemek gerekir.

## Gereksinimler

- `bash`, `curl`
- (opsiyonel, daha iyi menü için) `whiptail` veya `dialog`
