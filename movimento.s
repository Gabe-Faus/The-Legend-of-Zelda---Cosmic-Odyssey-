.globl LeTeclado
.globl ProcessaMovimento
.globl RedesenhaLink

############################################################
# Lê o teclado -> retorna em x10
############################################################
LeTeclado:
    li   x5, 0xFF200004
    lw   x10, 0(x5)    # tecla lida -> x10
    ret


############################################################
# Processa Movimento + limites + direção
# deslocamento por tecla = 4 pixels
# limites: X = [0 .. 304]  (320 - 16)
#         Y = [0 .. 210]  (240 - 30)
############################################################
ProcessaMovimento:

    la   x6, LinkX         # endereço LinkX
    lw   x7, 0(x6)         # x = x7

    la   x8, LinkY         # endereço LinkY
    lw   x9, 0(x8)         # y = x9

    la   x11, DirecaoLink  # endereço DirecaoLink

    # compara tecla em x10
    li   x12, 'w'
    beq  x10, x12, MOVE_UP

    li   x12, 's'
    beq  x10, x12, MOVE_DOWN

    li   x12, 'a'
    beq  x10, x12, MOVE_LEFT

    li   x12, 'd'
    beq  x10, x12, MOVE_RIGHT

    ret

MOVE_UP:
    addi x9, x9, -4            # y -= 4
    blt  x9, x0, CLAMP_TOP
    li   x13, 0
    sw   x13, 0(x11)           # DirecaoLink = 0 (cima)
    j    STORE_POS

CLAMP_TOP:
    li   x9, 0
    li   x13, 0
    sw   x13, 0(x11)
    j    STORE_POS

MOVE_DOWN:
    addi x9, x9, 4             # y += 4
    li   x13, 210              # max Y = 240 - 30
    bgt  x9, x13, CLAMP_BOTTOM
    li   x14, 1
    sw   x14, 0(x11)           # DirecaoLink = 1 (baixo)
    j    STORE_POS

CLAMP_BOTTOM:
    li   x9, 210
    li   x14, 1
    sw   x14, 0(x11)
    j    STORE_POS

MOVE_LEFT:
    addi x7, x7, -4            # x -= 4
    blt  x7, x0, CLAMP_LEFT
    li   x15, 2
    sw   x15, 0(x11)           # DirecaoLink = 2 (esquerda)
    j    STORE_POS

CLAMP_LEFT:
    li   x7, 0
    li   x15, 2
    sw   x15, 0(x11)
    j    STORE_POS

MOVE_RIGHT:
    addi x7, x7, 4             # x += 4
    li   x13, 304              # max X = 320 - 16
    bgt  x7, x13, CLAMP_RIGHT
    li   x15, 3
    sw   x15, 0(x11)           # DirecaoLink = 3 (direita)
    j    STORE_POS

CLAMP_RIGHT:
    li   x7, 304
    li   x15, 3
    sw   x15, 0(x11)

STORE_POS:
    sw   x7, 0(x6)    # salva LinkX
    sw   x9, 0(x8)    # salva LinkY
    ret


############################################################
# RedesenhaLink — desenha sprite 16x30 com transparência 255
############################################################
RedesenhaLink:

    li   x20, 0xFF100000   # framebuffer base

    la   x21, LinkX
    lw   x22, 0(x21)       # x

    la   x23, LinkY
    lw   x24, 0(x23)       # y

    # offset = y*320 + x
    li   x25, 320
    mul  x26, x24, x25
    add  x20, x20, x26
    add  x20, x20, x22     # x20 = endereço inicial do sprite na tela

    # escolhe sprite segundo DirecaoLink
    la   x27, DirecaoLink
    lw   x28, 0(x27)

    beq  x28, x0, SPR_CIMA    # 0 = cima
    li   x29, 1
    beq  x28, x29, SPR_BAIXO
    li   x29, 2
    beq  x28, x29, SPR_ESQ
    j    SPR_DIR

SPR_CIMA:
    la   x5, LinkCostEsq
    j    LOAD_SPR

SPR_BAIXO:
    la   x5, LinkFrentDir
    j    LOAD_SPR

SPR_ESQ:
    la   x5, LinkEscEsqPar
    j    LOAD_SPR

SPR_DIR:
    la   x5, LinkEscDirPar

LOAD_SPR:
    lw   x6, 0(x5)       # largura (esperada 16)
    lw   x7, 4(x5)       # altura  (esperada 30)
    addi x5, x5, 8       # ponteiro para os pixels do sprite

    li   x8, 0           # linha atual
    li   x9, 255         # valor transparente

DRAW_LY:
    beq  x8, x7, END_RL

    li   x10, 320
    mul  x11, x8, x10
    add  x12, x20, x11   # x12 = início desta linha na tela

    li   x13, 0          # coluna atual

DRAW_LX:
    beq  x13, x6, NEXT_LINE

    lbu  x14, 0(x5)      # lê pixel do sprite
    beq  x14, x9, SKIP_PIX

    sb   x14, 0(x12)     # escreve pixel na tela

SKIP_PIX:
    addi x5, x5, 1
    addi x12, x12, 1
    addi x13, x13, 1
    j    DRAW_LX

NEXT_LINE:
    addi x8, x8, 1
    j    DRAW_LY

END_RL:
    ret
