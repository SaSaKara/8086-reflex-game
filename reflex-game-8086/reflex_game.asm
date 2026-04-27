org 100h

jmp start

;ekranda kullanilacak mesajlar
title_msg db 'SAIDIN REFLEKS OYUNU$'
msg db 'Basilacak tus: $'
correct_msg db 'DOGRU!$'
wrong_msg db 'YANLIS!$'
timeout_msg db 'SURE DOLDU!$'
game_over db 'OYUN BITTI!$'
menu_msg db '1 - Tekrar Oyna   2 - Cikis$'

;oyun degiskenleri
target db ?
time_limit dw 36 ;2 saniye
start_tick dw ? ;turun basladigi zaman

score_msg db 'Skor: $'

correct_count db 0 ;dogru cevap sayisi
total_reaction dw 0 ;dogru cevaplarin toplam tepki suresi
avg_msg db 'Ortalama refleks suresi: $'
ms_msg db ' ms$'

lives db 3 ; can sayisi
life_msg db 'Can: $'

start:
    ;ekrani temizle
    mov ah, 00h
    mov al, 03h
    int 10h

    ;baslik yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 2
    mov dl, 29
    int 10h

    mov ah, 09h
    lea dx, title_msg
    int 21h

    ;cani ilk kez yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 36
    int 10h

    call print_lives


main_loop:
    ;hedef satirini temizle
    mov ah, 02h
    mov bh, 0
    mov dh, 4
    mov dl, 0
    int 10h

    mov cx, 80
    mov dl, ' '

clear_target_line:
    mov ah, 02h
    int 21h
    loop clear_target_line

    ;sonuc satirini temizle
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 0
    int 10h

    mov cx, 80
    mov dl, ' '

clear_result_line:
    mov ah, 02h
    int 21h
    loop clear_result_line

    ;random sayi uret 1-4
    mov ah, 2Ch
    int 21h

    mov al, dl
    and al, 03h
    add al, '1'
    mov target, al

    ;onceki turdan kalan tuslari temizle
    call clear_keyboard_buffer

    ;hedefi ekrana yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 4
    mov dl, 31
    int 10h

    mov ah, 09h
    lea dx, msg
    int 21h

    mov dl, target
    mov ah, 02h
    int 21h

    ;baslangic zamanini al
    mov ah, 00h
    int 1Ah
    mov start_tick, dx


wait_key_loop:
    ;klavyede tus var mi kontrol et
    mov ah, 01h
    int 16h
    jnz key_pressed

    ;gecen sureyi hesapla
    mov ah, 00h
    int 1Ah

    mov ax, dx
    sub ax, start_tick

    ;sure dolduysa timeout
    cmp ax, time_limit
    jae timeout

    jmp wait_key_loop


key_pressed:
    ;basilan tusu oku
    mov ah, 00h
    int 16h


check_key:
    ;basilan tus hedefe esit mi?
    cmp al, target
    je correct
    jmp wrong


wrong:
    ;yanlis mesajini yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 36
    int 10h

    mov ah, 09h
    lea dx, wrong_msg
    int 21h

    jmp lose_life


timeout:
    ;sure doldu mesajini yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 34
    int 10h

    mov ah, 09h
    lea dx, timeout_msg
    int 21h

    jmp lose_life


lose_life:;can kaybetme
    dec lives
    
    ;can satirini temizle
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 0
    int 10h

    mov cx, 80
    mov dl, ' '

clear_life_line:;can satirini temizleme
    mov ah, 02h
    int 21h
    loop clear_life_line
    ;cani yeniden yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 36
    int 10h

    call print_lives

    ;can bittiðinde oyunu bitir
    cmp lives, 0
    je end_game

    jmp main_loop


correct:
    ;tepki suresini hesapla
    mov ah, 00h
    int 1Ah

    mov ax, dx
    sub ax, start_tick

    add total_reaction, ax
    inc correct_count

    ;dogru mesajini yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 37
    int 10h

    mov ah, 09h
    lea dx, correct_msg
    int 21h

    ;sureyi kisalt
    cmp time_limit, 6
    jbe skip_speed_up

    sub time_limit, 2

skip_speed_up:
    jmp main_loop


end_game:
    ;bitis ekranini temizle
    mov ah, 00h
    mov al, 03h
    int 10h

    ;oyun bitti yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 4
    mov dl, 34
    int 10h

    mov ah, 09h
    lea dx, game_over
    int 21h

    ;ortalama refleks suresini yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 25
    int 10h

    call print_average

    ;skoru yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 8
    mov dl, 35
    int 10h

    call print_score

    ;tekrar oynama/cikis menusunu yaz
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 26
    int 10h

    mov ah, 09h
    lea dx, menu_msg
    int 21h

menu_wait:;menu secimi bekle
    
    mov ah, 00h
    int 16h

    cmp al, '1'
    je restart

    cmp al, '2'
    je exit

    jmp menu_wait


print_lives:;cani yaz
    
    mov ah, 09h
    lea dx, life_msg
    int 21h

    ;can karaktere cevir
    mov al, lives
    add al, '0'

    mov dl, al
    mov ah, 02h
    int 21h

    ret


clear_keyboard_buffer:
    ;klavye bufferinda data var mi?
    mov ah, 01h
    int 16h
    jz buffer_empty

    ;varsa oku ve temizle tamamini
    mov ah, 00h
    int 16h
    jmp clear_keyboard_buffer

buffer_empty:
    ret


print_number:
    ;AX icindeki sayiyi ekrana yazdirir
    cmp ax, 0
    jne pn_start

    mov dl, '0'
    mov ah, 02h
    int 21h
    ret

pn_start:
    mov cx, 0
    mov bx, 10

pn_divide:
    ;sayiyi basamaklarina ayir
    mov dx, 0
    div bx
    push dx
    inc cx

    cmp ax, 0
    jne pn_divide

pn_print:
    ;basamaklari ters sirada yaz
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop pn_print

    ret


print_average:
    ;ortalama mesajini yaz
    mov ah, 09h
    lea dx, avg_msg
    int 21h

    ;hic dogru yoksa 0 yaz
    cmp correct_count, 0
    je no_correct_answer

    ;ortalama tick = toplam sure / dogru sayisi
    mov ax, total_reaction
    mov bl, correct_count
    div bl

    ;tick degerini ms'ye cevir
    mov ah, 0
    mov bx, 55
    mul bx

    call print_number

    mov ah, 09h
    lea dx, ms_msg
    int 21h

    ret


no_correct_answer:
    ;dogru cevap yoksa ortalama 0 ms
    mov ax, 0
    call print_number

    mov ah, 09h
    lea dx, ms_msg
    int 21h

    ret


print_score:;skor mesajini yaz
   
    mov ah, 09h
    lea dx, score_msg
    int 21h

    ;skor = dogru cevap sayisi * 10
    mov al, correct_count
    mov ah, 0
    mov bx, 10
    mul bx

    call print_number

    ret


restart:
    ;oyunu yeniden baslatmak icin degerleri sifirla
    mov lives, 3
    mov correct_count, 0
    mov total_reaction, 0
    mov time_limit, 36

    jmp start


exit:;programdan cik
    
    mov ah, 4Ch
    int 21h