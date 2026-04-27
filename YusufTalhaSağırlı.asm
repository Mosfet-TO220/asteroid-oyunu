name "asteroid_oyunu"
org 100h

jmp basla   ; Degisken tanimlamalarini atlayip ana koda git

; =============================================
; DEGISKENLER
; =============================================

; Oyuncu baslangic konumu (sutun 40, satir 23 = ekranin alt ortasi)
oyuncu_x        db 40
oyuncu_y        db 23
oyuncu_char     db '^'      ; Oyuncuyu temsil eden karakter

; --- 1. ASTEROID ---
ast1_x          db 20       ; Baslangic sutunu
ast1_y          db 1        ; Baslangic satiri (ustten baslar)
ast1_boyut      db 1        ; Kac karakter genisliginde (1-3)
ast1_hiz        db 1        ; Her kac turda bir 1 satir asagi iner (1=hizli, 2=yavas)
ast1_hiz_sayaci db 1        ; Hiz sayaci: 0'a gelince asteroid hareket eder

; --- 2. ASTEROID ---
ast2_x          db 60
ast2_y          db 12       ; Ekranin ortasindan baslar (farkli konumdan cikar)
ast2_boyut      db 2
ast2_hiz        db 2
ast2_hiz_sayaci db 2

; --- 3. ASTEROID ---
ast3_x          db 40
ast3_y          db 6
ast3_boyut      db 3
ast3_hiz        db 1
ast3_hiz_sayaci db 1

ast_char        db '*'      ; Asteroidi temsil eden karakter

; --- KALKAN ---
kalkan_elde     db 0        ; 0 = kalkansiz, 1 = kalkan var
kalkan_dusen_x  db 30       ; Dusen kalkanin sutunu
kalkan_dusen_y  db 25       ; 25 = ekran disi (baslangicta gorunmez)
kalkan_char     db 'S'      ; Kalkani temsil eden karakter

tur_sayaci      db 0        ; Kac asteroid ekrandan gecti (skor)
oyun_bitti      db 0        ; 1 olunca oyun sona erer

; =============================================
; ANA KOD BASLANGICI
; =============================================
basla:
    mov ah, 00h
    mov al, 03h
    int 10h             ; Ekrani metin moduna al (80x25 karakter)

; =============================================
; ANA OYUN DONGUSU
; Her turda: ciz -> klavye oku -> hareket ettir -> carpisme kontrol
; =============================================
oyun_dongusu:
    call ekrani_temizle ; Her turda ekrani temizle, yeniden ciz

    ; -----------------------------------------
    ; KALKAN GOSTERGESI - Sol ust kose
    ; Kalkan varsa [S], yoksa [ ] gorunur
    ; -----------------------------------------
    mov ah, 02h
    mov bh, 0
    mov dh, 0           ; Satir 0 (en ust)
    mov dl, 0           ; Sutun 0 (en sol)
    int 10h             ; Imleci sol ust koseye tasi

    mov ah, 0Eh
    mov al, '['
    int 10h             ; '[' karakterini yaz

    cmp kalkan_elde, 1  ; Kalkanli miyiz?
    jne kalkan_yok      ; Degilse bosluk yaz
    mov al, 'S'
    jmp kalkan_yaz
kalkan_yok:
    mov al, ' '         ; Kalkan yoksa bosluk
kalkan_yaz:
    int 10h             ; S veya bosluk yaz
    mov al, ']'
    int 10h             ; ']' yaz -> gosterge tamamlandi

    ; -----------------------------------------
    ; TUR SAYACI - Sag ust kose
    ; "TUR:XX" formatinda hayatta kalinan tur sayisini gosterir
    ; -----------------------------------------
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 70          ; Sutun 70 (sag tarafa yakin)
    int 10h             ; Imleci sag ust koseye tasi

    mov ah, 0Eh
    mov al, 'T'
    int 10h
    mov al, 'U'
    int 10h
    mov al, 'R'
    int 10h
    mov al, ':'
    int 10h             ; "TUR:" yazisini tek tek yaz

    mov al, tur_sayaci  ; Tur sayisini AL'e al
    mov ah, 0
    mov bl, 10
    div bl              ; AL = onluk basamak, AH = birlik basamak
    push ax             ; AH'yi kaybetmemek icin stack'e kaydet
    add al, '0'         ; Rakimi ASCII karaktere cevir
    mov ah, 0Eh
    int 10h             ; Onluk basami yaz
    pop ax
    mov al, ah          ; Birlik basami AL'e al
    add al, '0'         ; ASCII'ye cevir
    mov ah, 0Eh
    int 10h             ; Birlik basami yaz

    ; -----------------------------------------
    ; OYUNCUYU CIZ
    ; '^' karakterini oyuncunun x,y konumuna yaz
    ; -----------------------------------------
    mov dl, oyuncu_x
    mov dh, oyuncu_y
    mov al, oyuncu_char
    call karakter_ciz

    ; -----------------------------------------
    ; DUSEN KALKANI CIZ
    ; Kalkan ekrandaysa (y < 24) konumuna 'S' yaz
    ; -----------------------------------------
    cmp kalkan_dusen_y, 24  ; Kalkan ekran disina cikti mi?
    jge asteroidleri_ciz    ; Ciktiysa cizme
    mov dl, kalkan_dusen_x
    mov dh, kalkan_dusen_y
    mov al, kalkan_char
    call karakter_ciz        ; Kalkani ciz

asteroidleri_ciz:
    ; -----------------------------------------
    ; 1. ASTEROIDI CIZ
    ; Boyutu kadar '*' karakteri yan yana yazar
    ; -----------------------------------------
    mov cl, ast1_boyut  ; Dongu sayaci = asteroid genisligi
    mov dl, ast1_x
    mov dh, ast1_y
    mov al, ast_char
cizim_dongusu1:
    push cx             ; CX'i koru (karakter_ciz icinde bozulabilir)
    call karakter_ciz   ; Bir '*' ciz
    inc dl              ; Bir saga kay (genislik icin)
    pop cx
    dec cl
    jnz cizim_dongusu1  ; Boyut kadar tekrarla

    ; 2. ASTEROIDI CIZ
    mov cl, ast2_boyut
    mov dl, ast2_x
    mov dh, ast2_y
    mov al, ast_char
cizim_dongusu2:
    push cx
    call karakter_ciz
    inc dl
    pop cx
    dec cl
    jnz cizim_dongusu2

    ; 3. ASTEROIDI CIZ
    mov cl, ast3_boyut
    mov dl, ast3_x
    mov dh, ast3_y
    mov al, ast_char
cizim_dongusu3:
    push cx
    call karakter_ciz
    inc dl
    pop cx
    dec cl
    jnz cizim_dongusu3

; =============================================
; KLAVYE GIRISI
; A = sola, D = saga, Q = cikis
; =============================================
klavye_kontrol:
    mov ah, 01h
    int 16h             ; Klavyede basilI tus var mi? (beklemeden kontrol)
    jz kalkan_hareketi  ; Yoksa klavye kontrolunu atla

    mov ah, 00h
    int 16h             ; Tusu oku (AL = karakter kodu)

    cmp al, 'a'
    je sola_git
    cmp al, 'd'
    je saga_git
    cmp al, 'q'
    je bitir_etiketi    ; Q = oyunu kapat
    cmp al, 'Q'
    je bitir_etiketi
    jmp kalkan_hareketi ; Taninmayan tus, devam et

sola_git:
    cmp oyuncu_x, 1     ; Sol kenara dayandi mi?
    jle kalkan_hareketi ; Dayandiysa hareket etme
    dec oyuncu_x        ; Bir sutun sola git
    jmp kalkan_hareketi

saga_git:
    cmp oyuncu_x, 78    ; Sag kenara dayandi mi?
    jge kalkan_hareketi ; Dayandiysa hareket etme
    inc oyuncu_x        ; Bir sutun saga git

; =============================================
; KALKAN HAREKETI
; Kalkan her turda bir satir asagi iner
; Oyuncuya degerse kalkan_elde = 1 olur
; =============================================
kalkan_hareketi:
    cmp kalkan_dusen_y, 24  ; Kalkan ekran disinda mi?
    jge kalkan_rastgele_uret ; Evet -> yeni kalkan uretmeye bak

    inc kalkan_dusen_y       ; Kalkani bir satir asagi indir

    cmp kalkan_dusen_y, 24   ; Ekranin altina ulasti mi?
    jge kalkan_sifirla       ; Ulastiysa sifirla

    ; Oyuncu kalkanla ayni konumda mi? (toplama kontrolu)
    mov al, oyuncu_y
    cmp al, kalkan_dusen_y   ; Ayni satirda mi?
    jne asteroid1_hareket
    mov al, oyuncu_x
    cmp al, kalkan_dusen_x   ; Ayni sutunda mi?
    jne asteroid1_hareket
    mov kalkan_elde, 1       ; Evet -> kalkan toplandi!

kalkan_sifirla:
    mov kalkan_dusen_y, 25   ; Kalkani ekran disina tasi (gizle)
    jmp asteroid1_hareket

kalkan_rastgele_uret:
    ; Zaman sayacindan (INT 1Ah) rastgele sayi uret
    mov ah, 00h
    int 1Ah                  ; DX = dusuk 16 bit zaman sayaci
    mov ax, dx
    and al, 03Fh             ; 0-63 arasi deger al
    cmp al, 15               ; Sadece 15 gelirse yeni kalkan uret (nadir ciksin)
    jne asteroid1_hareket    ; 15 degilse kalkan uretme

    mov kalkan_dusen_y, 1    ; Kalkani ekranin ustunden basla

    mov ah, 00h
    int 1Ah                  ; Tekrar rastgele sayi al (X konumu icin)
    mov ax, dx
    shr ax, 4                ; Biraz kaydýr (daha farkli deger icin)
    and al, 3Fh              ; 0-63 arasi
    add al, 5                ; 5-68 arasi (kenarlara cok yakin olmasin)
    mov kalkan_dusen_x, al   ; Kalkanin yatay konumunu ayarla

; =============================================
; ASTEROID HAREKETLERI
; Her asteroid kendi hiz sayaciyla hareket eder
; Sayac 0'a gelince 1 satir asagi iner
; Ekrani gecince tur sayaci artar, yeni rastgele degerler alir
; =============================================
asteroid1_hareket:
    dec ast1_hiz_sayaci      ; Hiz sayacini azalt
    jnz asteroid2_hareket    ; Henuz 0 olmadiysa bu asteroid hareket etmez

    mov al, ast1_hiz
    mov ast1_hiz_sayaci, al  ; Sayaci sifirla (tekrar saymaya basla)

    inc ast1_y               ; Asteroidi 1 satir asagi indir
    cmp ast1_y, 24           ; Ekranin altina ulasti mi?
    jl asteroid2_hareket     ; Hayir -> devam et

    ; Asteroid ekrandan cikti -> skor artir, yeni degerler ver
    inc tur_sayaci

    mov ast1_y, 1            ; Asteroidi tekrar ustten basla

    ; Rastgele boyut belirle (1-3)
    mov ah, 00h
    int 1Ah
    mov ax, dx
    and al, 03h              ; 0-3 arasi deger
    cmp al, 3
    jne boyut_ok1
    mov al, 2                ; 3 gelirse 2 yap (max boyut 3 olsun diye +1 sonrasi)
boyut_ok1:
    inc al                   ; 1-3 arasi boyut
    mov ast1_boyut, al

    ; Rastgele hiz belirle (1 veya 2)
    mov ax, dx
    shr ax, 5
    and al, 01h              ; 0 veya 1
    inc al                   ; 1 veya 2 (1=hizli, 2=yavas)
    mov ast1_hiz, al
    mov ast1_hiz_sayaci, al

    ; Rastgele X konumu belirle (ekrandan tasmasin diye boyut cikarilir)
    mov ah, 00h
    int 1Ah
    mov ax, dx
    shr ax, 2
    and al, 3Fh              ; 0-63
    add al, 5                ; 5-68
    mov bl, ast1_boyut
    sub al, bl               ; Boyut kadar geri cek (sag kenarda tasmasin)
    cmp al, 5
    jge x1_tamam
    mov al, 5                ; Minimum 5 (sol kenara yapýsmasýn)
x1_tamam:
    mov ast1_x, al

asteroid2_hareket:
    dec ast2_hiz_sayaci
    jnz asteroid3_hareket

    mov al, ast2_hiz
    mov ast2_hiz_sayaci, al

    inc ast2_y
    cmp ast2_y, 24
    jl asteroid3_hareket

    inc tur_sayaci
    mov ast2_y, 1

    mov ah, 00h
    int 1Ah
    mov ax, dx
    and al, 03h
    cmp al, 3
    jne boyut_ok2
    mov al, 2
boyut_ok2:
    inc al
    mov ast2_boyut, al

    mov ax, dx
    shr ax, 3
    and al, 01h
    inc al
    mov ast2_hiz, al
    mov ast2_hiz_sayaci, al

    mov ah, 00h
    int 1Ah
    mov ax, dx
    shr ax, 5
    and al, 3Fh
    add al, 5
    mov bl, ast2_boyut
    sub al, bl
    cmp al, 5
    jge x2_tamam
    mov al, 5
x2_tamam:
    mov ast2_x, al

asteroid3_hareket:
    dec ast3_hiz_sayaci
    jnz carpisma_kontrol_ast1

    mov al, ast3_hiz
    mov ast3_hiz_sayaci, al

    inc ast3_y
    cmp ast3_y, 24
    jl carpisma_kontrol_ast1

    inc tur_sayaci
    mov ast3_y, 1

    mov ah, 00h
    int 1Ah
    mov ax, dx
    and al, 03h
    cmp al, 3
    jne boyut_ok3
    mov al, 2
boyut_ok3:
    inc al
    mov ast3_boyut, al

    mov ax, dx
    shr ax, 4
    and al, 01h
    inc al
    mov ast3_hiz, al
    mov ast3_hiz_sayaci, al

    mov ah, 00h
    int 1Ah
    mov ax, dx
    shr ax, 3
    and al, 3Fh
    add al, 5
    mov bl, ast3_boyut
    sub al, bl
    cmp al, 5
    jge x3_tamam
    mov al, 5
x3_tamam:
    mov ast3_x, al

; =============================================
; CARPISME KONTROLU
; Oyuncunun x,y konumu asteroidin kapladigi
; alanla ortusüyor mu diye kontrol eder
; =============================================
carpisma_kontrol_ast1:
    mov al, oyuncu_y
    cmp al, ast1_y          ; Oyuncu asteroitle ayni satirda mi?
    jne carpisma_kontrol_ast2 ; Hayir -> sonraki asteroide gec

    mov al, oyuncu_x
    mov bl, ast1_x
    mov cl, ast1_boyut
kontrol_dongusu1:
    cmp al, bl              ; Oyuncunun X'i asteroidin bir parcasiyla ortusuyor mu?
    je vuruldu_ast1         ; Evet -> carpisme!
    inc bl                  ; Asteroidin sonraki parcasina gec
    dec cl
    jnz kontrol_dongusu1   ; Tum genisligi kontrol et

carpisma_kontrol_ast2:
    mov al, oyuncu_y
    cmp al, ast2_y
    jne carpisma_kontrol_ast3

    mov al, oyuncu_x
    mov bl, ast2_x
    mov cl, ast2_boyut
kontrol_dongusu2:
    cmp al, bl
    je vuruldu_ast2
    inc bl
    dec cl
    jnz kontrol_dongusu2

carpisma_kontrol_ast3:
    mov al, oyuncu_y
    cmp al, ast3_y
    jne bekleme

    mov al, oyuncu_x
    mov bl, ast3_x
    mov cl, ast3_boyut
kontrol_dongusu3:
    cmp al, bl
    je vuruldu_ast3
    inc bl
    dec cl
    jnz kontrol_dongusu3
    jmp bekleme

; --- CARPISME SONUCLARI ---
vuruldu_ast1:
    cmp kalkan_elde, 1      ; Kalkanli miyiz?
    jne oyun_sonu           ; Kalkansizsa oyun biter
    mov kalkan_elde, 0      ; Kalkani harca
    mov ast1_y, 24          ; Asteroidi ekranin altina gonder (yok et)
    jmp bekleme

vuruldu_ast2:
    cmp kalkan_elde, 1
    jne oyun_sonu
    mov kalkan_elde, 0
    mov ast2_y, 24
    jmp bekleme

vuruldu_ast3:
    cmp kalkan_elde, 1
    jne oyun_sonu
    mov kalkan_elde, 0
    mov ast3_y, 24
    jmp bekleme

oyun_sonu:
    jmp oyun_bitti_ekrani   ; Donguye donmeden direkt oyun sonu ekranina git

; --- DONGU SONU: BEKLEME ---
bekleme:
    ; 15 ms bekle (INT 15h / AH=86h = mikrosaniye cinsinden bekleme)
    ; CX:DX = 03A98h mikrosaniye = ~15ms -> oyun hizini belirler
    mov ah, 86h
    mov cx, 0000h
    mov dx, 03A98h
    int 15h
    jmp oyun_dongusu        ; Dongunun basina don

; =============================================
; OYUN BITTI EKRANI
; Ekrani temizler, skoru ve cikis mesajini gosterir
; Q'ya basilana kadar bekler
; =============================================
oyun_bitti_ekrani:
    call ekrani_temizle

    ; "OYUN BITTI!" yaz - ekranin ortasi (satir 10, sutun 30)
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 30
    int 10h
    mov ah, 0Eh
    mov al, 'O'
    int 10h
    mov al, 'Y'
    int 10h
    mov al, 'U'
    int 10h
    mov al, 'N'
    int 10h
    mov al, ' '
    int 10h
    mov al, 'B'
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'T'
    int 10h
    mov al, 'T'
    int 10h
    mov al, 'I'
    int 10h
    mov al, '!'
    int 10h

    ; "TURINIZ: XX" yaz - satir 12, sutun 30
    mov ah, 02h
    mov bh, 0
    mov dh, 12
    mov dl, 30
    int 10h
    mov ah, 0Eh
    mov al, 'T'
    int 10h
    mov al, 'U'
    int 10h
    mov al, 'R'
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'N'
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'Z'
    int 10h
    mov al, ':'
    int 10h
    mov al, ' '
    int 10h

    ; Tur sayisini iki basamakli yaz
    mov al, tur_sayaci
    mov ah, 0
    mov bl, 10
    div bl                  ; AL = onluk basamak, AH = birlik basamak
    push ax                 ; Birlik basami kaybetmemek icin sakla
    add al, '0'             ; Onluk basami ASCII'ye cevir
    mov ah, 0Eh
    int 10h                 ; Yaz
    pop ax
    mov al, ah              ; Birlik basami al
    add al, '0'             ; ASCII'ye cevir
    mov ah, 0Eh
    int 10h                 ; Yaz

    ; "CIKMAK ICIN Q" yaz - satir 14, sutun 27
    mov ah, 02h
    mov bh, 0
    mov dh, 14
    mov dl, 27
    int 10h
    mov ah, 0Eh
    mov al, 'C'
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'K'
    int 10h
    mov al, 'M'
    int 10h
    mov al, 'A'
    int 10h
    mov al, 'K'
    int 10h
    mov al, ' '
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'C'
    int 10h
    mov al, 'I'
    int 10h
    mov al, 'N'
    int 10h
    mov al, ' '
    int 10h
    mov al, 'Q'
    int 10h

bitti_bekle:
    mov ah, 00h
    int 16h                 ; Tusa basilmasini bekle (bloklu okuma)
    cmp al, 'q'
    je bitir_etiketi        ; Q = cikis
    cmp al, 'Q'
    je bitir_etiketi        ; Buyuk Q da kabul et
    jmp bitti_bekle         ; Baska tussa tekrar bekle

bitir_etiketi:
    mov ah, 4Ch
    int 21h                 ; DOS'a don (programi kapat)

; =============================================
; FONKSIYONLAR
; =============================================

; karakter_ciz: DH=satir, DL=sutun, AL=karakter
; Imleci DH,DL konumuna tasir ve AL karakterini yazar
karakter_ciz proc
    push ax                 ; AL'deki karakteri koru (INT 10h bozabilir)
    mov ah, 02h
    mov bh, 0
    int 10h                 ; Imleci DH,DL konumuna tasi
    pop ax
    mov ah, 0Eh
    int 10h                 ; AL karakterini ekrana yaz
    ret
karakter_ciz endp

; ekrani_temizle: Tum ekrani boslukla doldurur, imleci sol uste alir
ekrani_temizle proc
    mov ah, 06h
    mov al, 0               ; 0 = tum ekrani temizle
    mov bh, 07h             ; Renk: beyaz yazi, siyah arka plan
    mov cx, 0               ; Sol ust kose (satir 0, sutun 0)
    mov dh, 24              ; Sag alt kose satiri
    mov dl, 79              ; Sag alt kose sutunu
    int 10h                 ; Ekrani temizle
    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h                 ; Imleci sol ust koseye (0,0) tasi
    ret
ekrani_temizle endp

end basla