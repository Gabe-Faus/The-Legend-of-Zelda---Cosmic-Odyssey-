.data
# Sprites
.include "./imagens/imagens_convertidas/arquivos .data/EspacoSideral.data"
.include "./imagens/imagens_convertidas/arquivos .data/Marte.data"
.include "./imagens/imagens_convertidas/arquivos .data/Lua.data"
.include "./imagens/imagens_convertidas/arquivos .data/Venus.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkFrentDir.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkFrentEsq.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkCostEsq.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkCostDir.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkEscEsqPar.data"
.include "./imagens/imagens_convertidas/arquivos .data/LinkEscDirPar.data"
.include "./imagens/imagens_convertidas/arquivos .data/abertura.data"
.include "./imagens/imagens_convertidas/arquivos .data/inimigo1.data"
.include "./imagens/imagens_convertidas/arquivos .data/inimigo2.data"
.include "./imagens/imagens_convertidas/arquivos .data/gameover.data"
.include "./imagens/imagens_convertidas/arquivos .data/win.data"
# Controle de ataque
TeclaT_Pressionada: .word 0
# Posição inicial do Link
LinkX: .word 0      # Começa na borda esquerda
LinkY: .word 105    # Meio vertical (240 – 30) / 2 = 105

# Direção inicial (opcional)
DirecaoLink: .word 1

# Controle de cenário (0 = Espaço Sideral, 1 = Marte, 2 = Lua, 3 = Venus)
CenarioAtual: .word 0

# Estado do jogo (0 = tela de abertura, 1 = jogando, 2 = game over, 3 = vitória)
EstadoJogo: .word 0

# Sistema de vidas
VidasRestantes: .word 5

# Contador de frames para controlar invencibilidade
FramesInvencivel: .word 0
INVENCIBILIDADE_DURACAO: .word 30  # 30 frames de invencibilidade (menos piscar)

# Distância para ataque (pixels)
DISTANCIA_ATAQUE: .word 40

########################################################
# Dados dos Inimigos
########################################################
# Cada inimigo tem: X, Y, DirecaoY (1=baixo, -1=cima), YMin, YMax

# Inimigo 1
Inimigo1X: .word 100
Inimigo1Y: .word 50
Inimigo1DirecaoY: .word 1      # 1 = descendo
Inimigo1YMin: .word 20         # Limite superior
Inimigo1YMax: .word 180        # Limite inferior
Inimigo1Ativo: .word 1         # 1 = ativo, 0 = inativo

# Inimigo 2
Inimigo2X: .word 200
Inimigo2Y: .word 150
Inimigo2DirecaoY: .word -1     # -1 = subindo
Inimigo2YMin: .word 60
Inimigo2YMax: .word 200
Inimigo2Ativo: .word 1

# Dimensões dos inimigos (assumindo que são 16x16 ou 30x30 como o Link)
InimigoLargura: .word 30
InimigoAltura: .word 30

# Contador de inimigos mortos por cenário (4 cenários, 2 inimigos cada)
InimigosMortosCenario0: .word 0
InimigosMortosCenario1: .word 0
InimigosMortosCenario2: .word 0
InimigosMortosCenario3: .word 0

########################################################
# Música - Dados (DURAÇÕES REDUZIDAS)
########################################################
NUM_NOTAS: .word 16

# Durações reduzidas para não travar o jogo
NOTAS: .word 60,100, 62,50, 64,50, 65,50, 67,50, 69,25, 67,25, 65,50
       .word 60,100, 62,50, 64,50, 65,50, 67,50, 69,25, 71,25, 72,50

ContadorMusica: .word NOTAS, 0
FramesParaProximaNota: .word 0


.text
.globl _start

_start:

########################################################
# Seleciona framebuffer
########################################################
    li x1, 1
    li x2, 0xFF200604
    sw x1, 0(x2)

########################################################
# Mostra tela de abertura
########################################################
    jal TelaAbertura

########################################################
# LOOP PRINCIPAL
########################################################
main_loop:
    # Verifica estado do jogo
    la   t0, EstadoJogo
    lw   t1, 0(t0)
    
    # Se ainda está na abertura, aguarda tecla P
    beqz t1, aguarda_inicio
    
    # Se game over, aguarda tecla R para reiniciar
    li   t2, 2
    beq  t1, t2, aguarda_restart
    
    # Se vitória, aguarda tecla R para reiniciar
    li   t2, 3
    beq  t1, t2, aguarda_restart
    
    # Jogo em andamento
    jal LeTeclado
    beq a0, x0, NO_MOVE

    # Verifica se pressionou T para atacar
    li   t2, 't'
    beq  a0, t2, VERIFICA_ATAQUE
    li   t2, 'T'
    beq  a0, t2, VERIFICA_ATAQUE

    jal ProcessaMovimento
    j NO_MOVE

VERIFICA_ATAQUE:
    jal TentaAtacarInimigo

NO_MOVE:
    # Reseta o controle da tecla T se não estiver pressionada
    jal ResetaTeclaT
    
    # Atualiza posição dos inimigos
    jal AtualizaInimigos
    
    # Verifica se precisa fazer transição
    jal VerificaTransicao
    
    # Atualiza contador de invencibilidade
    jal AtualizaInvencibilidade
    
    # Verifica colisão com inimigos (só se não estiver invencível)
    jal VerificaColisaoInimigos
    
    # Música não-bloqueante
    jal TocaMusicaNaoBloqueante
    
    jal DesenhaCenario # Redesenha o fundo
    jal DesenhaInimigos # Desenha os inimigos
    jal RedesenhaLink  # Redesenha o personagem
    jal DesenhaVidas   # Desenha o contador de vidas
    
    # Pequeno delay para controlar FPS (opcional)
    li   a0, 16        # ~60 FPS
    li   a7, 32
    ecall
    
    j main_loop

aguarda_inicio:
    # Aguarda a tecla P para iniciar
    jal LeTeclado
    li  t2, 'p'
    beq a0, t2, inicia_jogo
    li  t2, 'P'
    beq a0, t2, inicia_jogo
    
    # Ainda não pressionou P, continua esperando
    j main_loop

aguarda_restart:
    # Aguarda a tecla R para reiniciar após game over
    jal LeTeclado
    li  t2, 'r'
    beq a0, t2, reinicia_jogo
    li  t2, 'R'
    beq a0, t2, reinicia_jogo
    
    # Ainda não pressionou R, continua na tela de game over
    j main_loop

reinicia_jogo:
    # Reseta todas as variáveis do jogo
    la  t0, VidasRestantes
    li  t1, 5
    sw  t1, 0(t0)
    
    la  t0, LinkX
    li  t1, 0
    sw  t1, 0(t0)
    
    la  t0, LinkY
    li  t1, 105
    sw  t1, 0(t0)
    
    la  t0, CenarioAtual
    li  t1, 0
    sw  t1, 0(t0)
    
    la  t0, FramesInvencivel
    li  t1, 0
    sw  t1, 0(t0)
    
    # Reativa inimigos
    jal ReposicionaInicioJogo
    
    # Reseta contadores de inimigos mortos
    la  t0, InimigosMortosCenario0
    sw  zero, 0(t0)
    la  t0, InimigosMortosCenario1
    sw  zero, 0(t0)
    la  t0, InimigosMortosCenario2
    sw  zero, 0(t0)
    la  t0, InimigosMortosCenario3
    sw  zero, 0(t0)
    
    # Volta para estado "jogando"
    la  t0, EstadoJogo
    li  t1, 1
    sw  t1, 0(t0)
    
    # Transição
    jal TelaPreta
    li  a0, 500
    li  a7, 32
    ecall
    
    jal DesenhaCenario
    jal DesenhaInimigos
    jal RedesenhaLink
    jal DesenhaVidas
    
    j main_loop

inicia_jogo:
    # Transição da abertura para o jogo
    jal TelaPreta
    
    li  a0, 500
    li  a7, 32
    ecall
    
    # Muda estado para "jogando"
    la  t0, EstadoJogo
    li  t1, 1
    sw  t1, 0(t0)
    
    # Desenha o primeiro cenário
    jal DesenhaCenario
    jal DesenhaInimigos
    jal RedesenhaLink
    jal DesenhaVidas
    
    j main_loop


########################################################
# Tela de Abertura
########################################################
TelaAbertura:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Desenha a imagem de abertura com PLAY
    la   a0, abertura
    jal  DesenhaImagem
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Tela de Game Over
########################################################
TelaGameOver:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  TelaPreta
    
    li   a0, 300
    li   a7, 32
    ecall
    
    # Desenha a imagem de game over
    la   a0, gameover
    jal  DesenhaImagem
    
    # Muda estado para "game over"
    la   t0, EstadoJogo
    li   t1, 2
    sw   t1, 0(t0)
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Tela de Vitória
########################################################
TelaVitoria:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  TelaPreta
    
    li   a0, 300
    li   a7, 32
    ecall
    
    # Desenha a imagem de vitória
    la   a0, win
    jal  DesenhaImagem
    
    # Muda estado para "vitória"
    la   t0, EstadoJogo
    li   t1, 3
    sw   t1, 0(t0)
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Verifica se todos os inimigos foram derrotados
########################################################
VerificaVitoria:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Soma todos os contadores de inimigos mortos
    la   t0, InimigosMortosCenario0
    lw   t1, 0(t0)
    la   t0, InimigosMortosCenario1
    lw   t2, 0(t0)
    add  t1, t1, t2
    la   t0, InimigosMortosCenario2
    lw   t2, 0(t0)
    add  t1, t1, t2
    la   t0, InimigosMortosCenario3
    lw   t2, 0(t0)
    add  t1, t1, t2
    
    # Se matou 8 inimigos (2 por cenário × 4 cenários), vitória!
    li   t2, 8
    bne  t1, t2, FIM_VERIFICA_VITORIA
    
    # VITÓRIA!
    jal  TelaVitoria

FIM_VERIFICA_VITORIA:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Desenha contador de vidas no topo da tela
########################################################
DesenhaVidas:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Carrega número de vidas
    la   t0, VidasRestantes
    lw   t1, 0(t0)
    
    # Posição no topo da tela (X=305, Y=5) - canto direito
    li   t2, 0xFF100000
    li   t3, 320
    li   t4, 5              # Y
    mul  t4, t4, t3
    li   t5, 305            # X (mudado de 10 para 305)
    add  t4, t4, t5
    add  t2, t2, t4
    
    # Desenha o número (dígito simples de 0-5)
    # Usa cor branca (0xFF para RGB 332)
    li   t6, 0xFF
    
    # Desenha um número simples 5x7 pixels
    mv   a0, t1             # Número a desenhar
    mv   a1, t2             # Endereço no framebuffer
    jal  DesenhaDigito
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Desenha um dígito 5x7 no framebuffer
# a0 = dígito (0-5)
# a1 = endereço no framebuffer
########################################################
DesenhaDigito:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    
    mv   s0, a0             # Dígito
    mv   s1, a1             # Endereço
    li   s2, 0xFF           # Cor branca
    
    # Padrões para cada dígito (simplificado)
    beqz s0, DIGITO_0
    li   t0, 1
    beq  s0, t0, DIGITO_1
    li   t0, 2
    beq  s0, t0, DIGITO_2
    li   t0, 3
    beq  s0, t0, DIGITO_3
    li   t0, 4
    beq  s0, t0, DIGITO_4
    li   t0, 5
    beq  s0, t0, DIGITO_5
    j    FIM_DIGITO

DIGITO_0:
    # Desenha 0
    li   t0, 7              # Altura
LINHA_0:
    beqz t0, FIM_DIGITO
    li   t1, 5              # Largura
    mv   t2, s1
COLUNA_0:
    beqz t1, PROX_LINHA_0
    # Desenha bordas
    li   t3, 7
    beq  t0, t3, PINTA_0    # Linha superior
    li   t3, 1
    beq  t0, t3, PINTA_0    # Linha inferior
    li   t3, 5
    beq  t1, t3, PINTA_0    # Coluna esquerda
    li   t3, 1
    beq  t1, t3, PINTA_0    # Coluna direita
    j    PULA_0
PINTA_0:
    sb   s2, 0(t2)
PULA_0:
    addi t2, t2, 1
    addi t1, t1, -1
    j    COLUNA_0
PROX_LINHA_0:
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_0

DIGITO_1:
    # Desenha 1 (linha vertical no meio)
    li   t0, 7
LINHA_1:
    beqz t0, FIM_DIGITO
    mv   t2, s1
    addi t2, t2, 2          # Centraliza
    sb   s2, 0(t2)
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_1

DIGITO_2:
    # Desenha 2
    li   t0, 7
LINHA_2:
    beqz t0, FIM_DIGITO
    li   t1, 5
    mv   t2, s1
COLUNA_2:
    beqz t1, PROX_LINHA_2
    li   t3, 7
    beq  t0, t3, PINTA_2    # Linha superior
    li   t3, 4
    beq  t0, t3, PINTA_2    # Linha meio
    li   t3, 1
    beq  t0, t3, PINTA_2    # Linha inferior
    li   t3, 7
    bgt  t0, t3, PULA_2_A
    li   t3, 4
    bgt  t0, t3, VERIFICA_DIR_2
    j    VERIFICA_ESQ_2
VERIFICA_DIR_2:
    li   t3, 1
    beq  t1, t3, PINTA_2
    j    PULA_2_A
VERIFICA_ESQ_2:
    li   t3, 5
    beq  t1, t3, PINTA_2
    j    PULA_2_A
PINTA_2:
    sb   s2, 0(t2)
PULA_2_A:
    addi t2, t2, 1
    addi t1, t1, -1
    j    COLUNA_2
PROX_LINHA_2:
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_2

DIGITO_3:
    # Desenha 3 (similar ao 2 mas com lado direito)
    li   t0, 7
LINHA_3:
    beqz t0, FIM_DIGITO
    li   t1, 5
    mv   t2, s1
COLUNA_3:
    beqz t1, PROX_LINHA_3
    li   t3, 7
    beq  t0, t3, PINTA_3
    li   t3, 4
    beq  t0, t3, PINTA_3
    li   t3, 1
    beq  t0, t3, PINTA_3
    li   t3, 1
    beq  t1, t3, PINTA_3
    j    PULA_3
PINTA_3:
    sb   s2, 0(t2)
PULA_3:
    addi t2, t2, 1
    addi t1, t1, -1
    j    COLUNA_3
PROX_LINHA_3:
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_3

DIGITO_4:
    # Desenha 4
    li   t0, 7
LINHA_4:
    beqz t0, FIM_DIGITO
    li   t1, 5
    mv   t2, s1
COLUNA_4:
    beqz t1, PROX_LINHA_4
    li   t3, 4
    beq  t0, t3, PINTA_4    # Linha meio
    li   t3, 7
    bgt  t0, t3, PULA_4_A
    li   t3, 4
    bgt  t0, t3, VERIFICA_ESQ_4
    j    VERIFICA_DIR_4
VERIFICA_ESQ_4:
    li   t3, 5
    beq  t1, t3, PINTA_4
    j    PULA_4_A
VERIFICA_DIR_4:
    li   t3, 1
    beq  t1, t3, PINTA_4
    j    PULA_4_A
PINTA_4:
    sb   s2, 0(t2)
PULA_4_A:
    addi t2, t2, 1
    addi t1, t1, -1
    j    COLUNA_4
PROX_LINHA_4:
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_4

DIGITO_5:
    # Desenha 5 (invertido do 2)
    li   t0, 7
LINHA_5:
    beqz t0, FIM_DIGITO
    li   t1, 5
    mv   t2, s1
COLUNA_5:
    beqz t1, PROX_LINHA_5
    li   t3, 7
    beq  t0, t3, PINTA_5
    li   t3, 4
    beq  t0, t3, PINTA_5
    li   t3, 1
    beq  t0, t3, PINTA_5
    li   t3, 7
    bgt  t0, t3, PULA_5_A
    li   t3, 4
    bgt  t0, t3, VERIFICA_ESQ_5
    j    VERIFICA_DIR_5
VERIFICA_ESQ_5:
    li   t3, 5
    beq  t1, t3, PINTA_5
    j    PULA_5_A
VERIFICA_DIR_5:
    li   t3, 1
    beq  t1, t3, PINTA_5
    j    PULA_5_A
PINTA_5:
    sb   s2, 0(t2)
PULA_5_A:
    addi t2, t2, 1
    addi t1, t1, -1
    j    COLUNA_5
PROX_LINHA_5:
    addi s1, s1, 320
    addi t0, t0, -1
    j    LINHA_5

FIM_DIGITO:
    lw   ra, 0(sp)
    lw   s0, 4(sp)
    lw   s1, 8(sp)
    lw   s2, 12(sp)
    lw   s3, 16(sp)
    addi sp, sp, 20
    ret


########################################################
# Tenta atacar inimigo próximo
########################################################
TentaAtacarInimigo:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # TOCA SOM DE ATAQUE
    li   a0, 70              # Nota mais alta (som mais seco)
    li   a1, 30              # Duração bem curta (30ms)
    li   a2, 0               # Instrumento piano
    li   a3, 127             # Volume máximo
    li   a7, 31              # MIDI out
    ecall
    
    # Carrega posição do Link
    la   t0, LinkX
    lw   t1, 0(t0)              # LinkX
    la   t0, LinkY
    lw   t2, 0(t0)              # LinkY
    
    # Carrega distância de ataque
    la   t0, DISTANCIA_ATAQUE
    lw   t6, 0(t0)
    
    # Verifica proximidade com Inimigo 1
    la   t0, Inimigo1Ativo
    lw   t3, 0(t0)
    beqz t3, ATAQUE_INIMIGO2    # Se inativo, pula
    
    la   t0, Inimigo1X
    lw   a0, 0(t0)              # Inimigo1X
    la   t0, Inimigo1Y
    lw   a1, 0(t0)              # Inimigo1Y
    
    # Calcula distância (aproximada usando Manhattan distance)
    sub  t3, a0, t1             # DeltaX
    blt  t3, zero, NEG_X1
    j    CONT_X1
NEG_X1:
    neg  t3, t3
CONT_X1:
    sub  t4, a1, t2             # DeltaY
    blt  t4, zero, NEG_Y1
    j    CONT_Y1
NEG_Y1:
    neg  t4, t4
CONT_Y1:
    add  t5, t3, t4             # Distância Manhattan
    
    # Se distância <= DISTANCIA_ATAQUE, mata o inimigo
    ble  t5, t6, MATA_INIMIGO1

ATAQUE_INIMIGO2:
    # Verifica proximidade com Inimigo 2
    la   t0, Inimigo2Ativo
    lw   t3, 0(t0)
    beqz t3, FIM_ATAQUE         # Se inativo, pula
    
    la   t0, Inimigo2X
    lw   a0, 0(t0)              # Inimigo2X
    la   t0, Inimigo2Y
    lw   a1, 0(t0)              # Inimigo2Y
    
    # Calcula distância
    sub  t3, a0, t1
    blt  t3, zero, NEG_X2
    j    CONT_X2
NEG_X2:
    neg  t3, t3
CONT_X2:
    sub  t4, a1, t2
    blt  t4, zero, NEG_Y2
    j    CONT_Y2
NEG_Y2:
    neg  t4, t4
CONT_Y2:
    add  t5, t3, t4
    
    # Se distância <= DISTANCIA_ATAQUE, mata o inimigo
    ble  t5, t6, MATA_INIMIGO2
    
    j    FIM_ATAQUE

MATA_INIMIGO1:
    # Desativa Inimigo 1
    la   t0, Inimigo1Ativo
    li   t1, 0
    sw   t1, 0(t0)
    
    # Incrementa contador do cenário atual
    jal  IncrementaInimigosMortos
    
    # Verifica se ganhou
    jal  VerificaVitoria
    
    j    FIM_ATAQUE

MATA_INIMIGO2:
    # Desativa Inimigo 2
    la   t0, Inimigo2Ativo
    li   t1, 0
    sw   t1, 0(t0)
    
    # Incrementa contador do cenário atual
    jal  IncrementaInimigosMortos
    
    # Verifica se ganhou
    jal  VerificaVitoria

FIM_ATAQUE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
    ########################################################
# Reseta controle da tecla T
########################################################
ResetaTeclaT:
    la   t0, TeclaT_Pressionada
    sw   zero, 0(t0)
    ret

########################################################
# Incrementa contador de inimigos mortos do cenário atual
########################################################
IncrementaInimigosMortos:
    # Carrega cenário atual
    la   t0, CenarioAtual
    lw   t1, 0(t0)
    
    # Seleciona o contador correto
    beqz t1, INCR_CENARIO0
    li   t2, 1
    beq  t1, t2, INCR_CENARIO1
    li   t2, 2
    beq  t1, t2, INCR_CENARIO2
    li   t2, 3
    beq  t1, t2, INCR_CENARIO3
    ret

INCR_CENARIO0:
    la   t0, InimigosMortosCenario0
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)
    ret

INCR_CENARIO1:
    la   t0, InimigosMortosCenario1
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)
    ret

INCR_CENARIO2:
    la   t0, InimigosMortosCenario2
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)
    ret

INCR_CENARIO3:
    la   t0, InimigosMortosCenario3
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)
    ret


########################################################
# Atualiza invencibilidade
########################################################
AtualizaInvencibilidade:
    la   t0, FramesInvencivel
    lw   t1, 0(t0)
    beqz t1, FIM_ATUALIZA_INVENC  # Já está zero
    
    addi t1, t1, -1
    sw   t1, 0(t0)
    
FIM_ATUALIZA_INVENC:
    ret


########################################################
# Atualiza posição dos inimigos
########################################################
AtualizaInimigos:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Atualiza Inimigo 1
    la   t0, Inimigo1Ativo
    lw   t1, 0(t0)
    beqz t1, ATUALIZA_INIMIGO2  # Se inativo, pula
    
    # Carrega posição Y e direção
    la   t0, Inimigo1Y
    lw   t1, 0(t0)              # Y atual
    la   t2, Inimigo1DirecaoY
    lw   t3, 0(t2)              # Direção
    
    # Move na direção
    add  t1, t1, t3
    
    # Verifica limites
    la   t4, Inimigo1YMin
    lw   t5, 0(t4)
    ble  t1, t5, INVERTE_INIMIGO1  # Se <= YMin, inverte
    
    la   t4, Inimigo1YMax
    lw   t5, 0(t4)
    bge  t1, t5, INVERTE_INIMIGO1  # Se >= YMax, inverte
    
    # Salva nova posição
    sw   t1, 0(t0)
    j    ATUALIZA_INIMIGO2

INVERTE_INIMIGO1:
    # Inverte direção
    neg  t3, t3
    sw   t3, 0(t2)
    # Ajusta posição para dentro dos limites
    add  t1, t1, t3
    add  t1, t1, t3
    sw   t1, 0(t0)

ATUALIZA_INIMIGO2:
    # Atualiza Inimigo 2
    la   t0, Inimigo2Ativo
    lw   t1, 0(t0)
    beqz t1, FIM_ATUALIZA_INIMIGOS
    
    la   t0, Inimigo2Y
    lw   t1, 0(t0)
    la   t2, Inimigo2DirecaoY
    lw   t3, 0(t2)
    
    add  t1, t1, t3
    
    la   t4, Inimigo2YMin
    lw   t5, 0(t4)
    ble  t1, t5, INVERTE_INIMIGO2
    
    la   t4, Inimigo2YMax
    lw   t5, 0(t4)
    bge  t1, t5, INVERTE_INIMIGO2
    
    sw   t1, 0(t0)
    j    FIM_ATUALIZA_INIMIGOS

INVERTE_INIMIGO2:
    neg  t3, t3
    sw   t3, 0(t2)
    add  t1, t1, t3
    add  t1, t1, t3
    sw   t1, 0(t0)

FIM_ATUALIZA_INIMIGOS:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Desenha os inimigos
########################################################
DesenhaInimigos:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Desenha Inimigo 1
    la   t0, Inimigo1Ativo
    lw   t1, 0(t0)
    beqz t1, DESENHA_INIMIGO2_CHECK
    
    la   a1, Inimigo1X
    lw   a1, 0(a1)              # X
    la   a2, Inimigo1Y
    lw   a2, 0(a2)              # Y
    la   a0, inimigo1           # Sprite
    jal  DesenhaSpriteXY
    
DESENHA_INIMIGO2_CHECK:
    # Desenha Inimigo 2
    la   t0, Inimigo2Ativo
    lw   t1, 0(t0)
    beqz t1, FIM_DESENHA_INIMIGOS
    
    la   a1, Inimigo2X
    lw   a1, 0(a1)
    la   a2, Inimigo2Y
    lw   a2, 0(a2)
    la   a0, inimigo2
    jal  DesenhaSpriteXY

FIM_DESENHA_INIMIGOS:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Desenha sprite em posição específica (X, Y)
# a0 = endereço do sprite
# a1 = X
# a2 = Y
########################################################
DesenhaSpriteXY:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    
    # Verifica se sprite é válido
    beqz a0, SPRITE_FIM
    
    mv   s0, a0                 # Endereço do sprite
    mv   s1, a1                 # X
    mv   s2, a2                 # Y
    
    # Carrega dimensões do sprite
    lw   s3, 0(s0)              # Largura
    lw   t0, 4(s0)              # Altura
    
    # Verifica dimensões válidas
    beqz s3, SPRITE_FIM
    beqz t0, SPRITE_FIM
    
    addi s0, s0, 8              # Pula header
    
    # Calcula endereço base no framebuffer
    li   t1, 0xFF100000
    li   t2, 320
    mul  t3, s2, t2             # Y * 320
    add  t3, t3, s1             # + X
    add  t1, t1, t3             # Endereço inicial
    
    mv   t4, t0                 # Contador de linhas (altura)
    
SPRITE_LINHA:
    beqz t4, SPRITE_FIM
    
    mv   t5, s3                 # Contador de colunas (largura)
    mv   t6, t1                 # Endereço da linha atual
    
SPRITE_COLUNA:
    beqz t5, SPRITE_PROXIMA_LINHA
    
    lb   t3, 0(s0)              # Lê pixel do sprite
    
    # Se for transparente (255) ou preto (0), pula
    li   t2, 255
    beq  t3, t2, SPRITE_PULA_PIXEL
    beqz t3, SPRITE_PULA_PIXEL      # Pula se for preto (0)
    
    sb   t3, 0(t6)              # Desenha pixel
    
SPRITE_PULA_PIXEL:
    addi s0, s0, 1              # Próximo pixel do sprite
    addi t6, t6, 1              # Próximo pixel no framebuffer
    addi t5, t5, -1
    j    SPRITE_COLUNA

SPRITE_PROXIMA_LINHA:
    addi t1, t1, 320            # Próxima linha no framebuffer
    addi t4, t4, -1
    j    SPRITE_LINHA

SPRITE_FIM:
    lw   ra, 0(sp)
    lw   s0, 4(sp)
    lw   s1, 8(sp)
    lw   s2, 12(sp)
    lw   s3, 16(sp)
    addi sp, sp, 20
    ret


########################################################
# Verifica colisão entre Link e inimigos
########################################################
VerificaColisaoInimigos:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # Verifica se está invencível
    la   t0, FramesInvencivel
    lw   t1, 0(t0)
    bnez t1, FIM_COLISAO        # Se invencível, não verifica colisão
    
    # Carrega posição do Link
    la   t0, LinkX
    lw   t1, 0(t0)              # LinkX
    la   t0, LinkY
    lw   t2, 0(t0)              # LinkY
    
    # Dimensões do Link (30x30)
    li   t3, 30
    li   t4, 30
    
    # Verifica colisão com Inimigo 1
    la   t0, Inimigo1Ativo
    lw   t5, 0(t0)
    beqz t5, COLISAO_INIMIGO2
    
    la   t0, Inimigo1X
    lw   a0, 0(t0)              # Inimigo1X
    la   t0, Inimigo1Y
    lw   a1, 0(t0)              # Inimigo1Y
    
    mv   a2, t1                 # LinkX
    mv   a3, t2                 # LinkY
    jal  TestaCaixasColisao
    
    bnez a0, COLISAO_DETECTADA

COLISAO_INIMIGO2:
    # Verifica colisão com Inimigo 2
    la   t0, Inimigo2Ativo
    lw   t5, 0(t0)
    beqz t5, FIM_COLISAO
    
    la   t0, Inimigo2X
    lw   a0, 0(t0)
    la   t0, Inimigo2Y
    lw   a1, 0(t0)
    
    la   t0, LinkX
    lw   a2, 0(t0)
    la   t0, LinkY
    lw   a3, 0(t0)
    
    jal  TestaCaixasColisao
    
    bnez a0, COLISAO_DETECTADA

FIM_COLISAO:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

COLISAO_DETECTADA:
    # Diminui uma vida
    la   t0, VidasRestantes
    lw   t1, 0(t0)
    addi t1, t1, -1
    sw   t1, 0(t0)
    
    # Verifica se zerou as vidas
    beqz t1, GAME_OVER
    
    # Volta ao início do cenário
    la   t0, LinkX
    li   t1, 0
    sw   t1, 0(t0)
    la   t0, LinkY
    li   t1, 105
    sw   t1, 0(t0)
    
    # Ativa invencibilidade temporária
    la   t0, FramesInvencivel
    la   t1, INVENCIBILIDADE_DURACAO
    lw   t1, 0(t1)
    sw   t1, 0(t0)
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

GAME_OVER:
    # Chama tela de game over
    jal  TelaGameOver
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Testa colisão entre duas caixas (AABB)
# a0 = X1, a1 = Y1 (objeto 1)
# a2 = X2, a3 = Y2 (objeto 2)
# Retorna: a0 = 1 se colidiu, 0 se não
########################################################
TestaCaixasColisao:
    # Dimensões fixas 30x30
    li   t0, 30
    
    # Calcula bordas do objeto 1
    add  t1, a0, t0             # X1 + largura
    add  t2, a1, t0             # Y1 + altura
    
    # Calcula bordas do objeto 2
    add  t3, a2, t0             # X2 + largura
    add  t4, a3, t0             # Y2 + altura
    
    # Verifica se NÃO há colisão (retorna 0)
    # Se X1 >= X2+w OU X1+w <= X2 OU Y1 >= Y2+h OU Y1+h <= Y2
    bge  a0, t3, SEM_COLISAO    # X1 >= X2+w
    ble  t1, a2, SEM_COLISAO    # X1+w <= X2
    bge  a1, t4, SEM_COLISAO    # Y1 >= Y2+h
    ble  t2, a3, SEM_COLISAO    # Y1+h <= Y2
    
    # Se chegou aqui, há colisão
    li   a0, 1
    ret

SEM_COLISAO:
    li   a0, 0
    ret


########################################################
# Verifica se chegou no final do mapa para transição
########################################################
VerificaTransicao:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    la   t0, LinkX
    lw   t1, 0(t0)
    
    li   t2, 290                # Ajustado para 290 (mais fácil de atingir)
    blt  t1, t2, FIM_VERIFICACAO
    
    jal  TransicaoCenario
    
FIM_VERIFICACAO:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Transição de Cenário - Tela preta + novo mapa
########################################################
TransicaoCenario:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  TelaPreta
    
    li   a0, 800
    li   a7, 32
    ecall
    
    la   t0, CenarioAtual
    lw   t1, 0(t0)
    addi t1, t1, 1
    
    li   t2, 4                  # Agora são 4 cenários (0-3)
    blt  t1, t2, SALVA_CENARIO
    
    li   t1, 0                  # Volta para o primeiro cenário
    
SALVA_CENARIO:
    sw   t1, 0(t0)
    
    la   t0, LinkX
    li   t1, 0
    sw   t1, 0(t0)
    
    la   t0, LinkY
    li   t1, 105
    sw   t1, 0(t0)
    
    # Reposiciona inimigos para o novo cenário
    jal  ReposicionaInimigos
    
    jal  DesenhaCenario
    
    li   a0, 500
    li   a7, 32
    ecall
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Reposiciona inimigos ao trocar de cenário
########################################################
ReposicionaInimigos:
    # Carrega o cenário atual
    la   t0, CenarioAtual
    lw   t1, 0(t0)
    
    # Verifica se os inimigos do cenário atual já foram mortos
    # Se foram, não reativa
    beqz t1, CHECK_CENARIO0
    li   t2, 1
    beq  t1, t2, CHECK_CENARIO1
    li   t2, 2
    beq  t1, t2, CHECK_CENARIO2
    j    CHECK_CENARIO3

CHECK_CENARIO0:
    la   t0, InimigosMortosCenario0
    lw   t2, 0(t0)
    li   t3, 2
    beq  t2, t3, INIMIGOS_JA_MORTOS  # Se matou 2, não reativa
    j    REATIVA_INIMIGOS

CHECK_CENARIO1:
    la   t0, InimigosMortosCenario1
    lw   t2, 0(t0)
    li   t3, 2
    beq  t2, t3, INIMIGOS_JA_MORTOS
    j    REATIVA_INIMIGOS

CHECK_CENARIO2:
    la   t0, InimigosMortosCenario2
    lw   t2, 0(t0)
    li   t3, 2
    beq  t2, t3, INIMIGOS_JA_MORTOS
    j    REATIVA_INIMIGOS

CHECK_CENARIO3:
    la   t0, InimigosMortosCenario3
    lw   t2, 0(t0)
    li   t3, 2
    beq  t2, t3, INIMIGOS_JA_MORTOS
    j    REATIVA_INIMIGOS

INIMIGOS_JA_MORTOS:
    # Mantém inimigos desativados
    la   t0, Inimigo1Ativo
    sw   zero, 0(t0)
    la   t0, Inimigo2Ativo
    sw   zero, 0(t0)
    
    # Pula o reposicionamento
    j    FIM_REPOS

REATIVA_INIMIGOS:
    # Reativa todos os inimigos ao mudar de cenário
    la   t0, Inimigo1Ativo
    li   t2, 1
    sw   t2, 0(t0)
    la   t0, Inimigo2Ativo
    sw   t2, 0(t0)
    
    # Carrega novamente o cenário para posicionamento
    la   t0, CenarioAtual
    lw   t1, 0(t0)
    
    # Diferentes posições para cada cenário
    beqz t1, REPOS_ESPACO
    li   t2, 1
    beq  t1, t2, REPOS_MARTE
    li   t2, 2
    beq  t1, t2, REPOS_LUA
    j    REPOS_VENUS

REPOS_ESPACO:
    # Inimigo 1
    la   t0, Inimigo1X
    li   t1, 100
    sw   t1, 0(t0)
    la   t0, Inimigo1Y
    li   t1, 50
    sw   t1, 0(t0)
    
    # Inimigo 2
    la   t0, Inimigo2X
    li   t1, 200
    sw   t1, 0(t0)
    la   t0, Inimigo2Y
    li   t1, 150
    sw   t1, 0(t0)
    j    FIM_REPOS

REPOS_MARTE:
    # Inimigo 1
    la   t0, Inimigo1X
    li   t1, 150
    sw   t1, 0(t0)
    la   t0, Inimigo1Y
    li   t1, 80
    sw   t1, 0(t0)
    
    # Inimigo 2
    la   t0, Inimigo2X
    li   t1, 250
    sw   t1, 0(t0)
    la   t0, Inimigo2Y
    li   t1, 120
    sw   t1, 0(t0)
    j    FIM_REPOS

REPOS_LUA:
    # Inimigo 1
    la   t0, Inimigo1X
    li   t1, 80
    sw   t1, 0(t0)
    la   t0, Inimigo1Y
    li   t1, 40
    sw   t1, 0(t0)
    
    # Inimigo 2
    la   t0, Inimigo2X
    li   t1, 220
    sw   t1, 0(t0)
    la   t0, Inimigo2Y
    li   t1, 160
    sw   t1, 0(t0)
    j    FIM_REPOS

REPOS_VENUS:
    # Inimigo 1
    la   t0, Inimigo1X
    li   t1, 120
    sw   t1, 0(t0)
    la   t0, Inimigo1Y
    li   t1, 60
    sw   t1, 0(t0)
    
    # Inimigo 2
    la   t0, Inimigo2X
    li   t1, 230
    sw   t1, 0(t0)
    la   t0, Inimigo2Y
    li   t1, 140
    sw   t1, 0(t0)

FIM_REPOS:
    ret


########################################################
# Reposiciona inimigos no início do jogo (reset completo)
########################################################
ReposicionaInicioJogo:
    # Reativa todos os inimigos
    la   t0, Inimigo1Ativo
    li   t1, 1
    sw   t1, 0(t0)
    la   t0, Inimigo2Ativo
    sw   t1, 0(t0)
    
    # Posiciona no cenário 0 (Espaço)
    la   t0, Inimigo1X
    li   t1, 100
    sw   t1, 0(t0)
    la   t0, Inimigo1Y
    li   t1, 50
    sw   t1, 0(t0)
    
    la   t0, Inimigo2X
    li   t1, 200
    sw   t1, 0(t0)
    la   t0, Inimigo2Y
    li   t1, 150
    sw   t1, 0(t0)
    
    ret


########################################################
# Preenche a tela de preto
########################################################
TelaPreta:
    li   t0, 0xFF100000
    li   t1, 0x00
    li   t2, 76800
    
LOOP_PRETO:
    sb   t1, 0(t0)
    addi t0, t0, 1
    addi t2, t2, -1
    bnez t2, LOOP_PRETO
    
    ret


########################################################
# Desenhar cenário
########################################################
DesenhaCenario:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    la   t0, CenarioAtual
    lw   t1, 0(t0)
    
    beqz t1, DESENHA_ESPACO
    
    li   t2, 1
    beq  t1, t2, DESENHA_MARTE
    
    li   t2, 2
    beq  t1, t2, DESENHA_LUA
    
    li   t2, 3
    beq  t1, t2, DESENHA_VENUS
    
    j    DESENHA_ESPACO
    
DESENHA_ESPACO:
    la   a0, EspacoSideral
    jal  DesenhaImagem
    j    FIM_DESENHA
    
DESENHA_MARTE:
    la   a0, Marte
    jal  DesenhaImagem
    j    FIM_DESENHA
    
DESENHA_LUA:
    la   a0, Lua
    jal  DesenhaImagem
    j    FIM_DESENHA

DESENHA_VENUS:
    la   a0, Venus
    jal  DesenhaImagem
    
FIM_DESENHA:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


########################################################
# Desenha uma imagem genérica
########################################################
DesenhaImagem:
    li   x3, 0xFF100000
    mv   x4, a0
    lw   x5, 0(x4)
    lw   x6, 4(x4)
    addi x4, x4, 8
    mul  x7, x5, x6
    li   x8, 0

IMG_LOOP:
    beq  x8, x7, IMG_DONE
    lb   x9, 0(x4)
    sb   x9, 0(x3)
    addi x4, x4, 1
    addi x3, x3, 1
    addi x8, x8, 1
    j    IMG_LOOP

IMG_DONE:
    ret


########################################################
# Toca Música (Versão Não-Bloqueante)
########################################################
TocaMusicaNaoBloqueante:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   t0, 4(sp)
    sw   t1, 8(sp)
    sw   t2, 12(sp)

    # Verifica se ainda está esperando para tocar próxima nota
    la   t0, FramesParaProximaNota
    lw   t1, 0(t0)
    beqz t1, TOCA_NOTA          # Se zero, toca próxima nota
    
    # Decrementa contador e sai
    addi t1, t1, -1
    sw   t1, 0(t0)
    j    TOCA_END

TOCA_NOTA:
    la   t0, ContadorMusica
    lw   t1, 4(t0)
    la   t2, NUM_NOTAS
    lw   t2, 0(t2)
    bge  t1, t2, RESET_MUSIC

    lw   t3, 0(t0)
    slli t1, t1, 3
    add  t3, t3, t1
    lw   a0, 0(t3)              # Nota (pitch)
    lw   a1, 4(t3)              # Duração
    
    # Toca a nota usando MIDI out (syscall 31)
    # a0 = pitch (já carregado)
    # a1 = duração (já carregado)
    # a2 = instrumento (0 = piano)
    # a3 = volume (0-127)
    li   a2, 0                  # Piano
    li   a3, 100                # Volume
    li   a7, 31                 # MIDI out
    ecall

    # Calcula frames para esperar (duração / 16ms por frame)
    lw   t4, 4(t3)              # Recarrega duração
    srli t4, t4, 4              # Divide por 16 (aproximadamente)
    addi t4, t4, 1              # Garante pelo menos 1 frame
    la   t0, FramesParaProximaNota
    sw   t4, 0(t0)

    # Avança para próxima nota
    la   t0, ContadorMusica
    lw   t1, 4(t0)
    addi t1, t1, 1
    sw   t1, 4(t0)
    j    TOCA_END

RESET_MUSIC:
    li   t1, 0
    sw   t1, 4(t0)
    
TOCA_END:
    lw   ra, 0(sp)
    lw   t0, 4(sp)
    lw   t1, 8(sp)
    lw   t2, 12(sp)
    addi sp, sp, 16
    ret


########################################################
# Importa movimento e redesenho
########################################################
.include "movimento.s"
