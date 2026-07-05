# Cabal ARPG — Sessão 1: Fundação + Gladiador

ARPG 3D em Godot 4.x (Forward+) inspirado no combate do Cabal Online.
Sessão 1: fundação, movimento, câmera e a classe Gladiador (GL) completa
contra training dummies.

## Arquitetura: Simulação ≠ Apresentação

- `scripts/sim/` — **simulação**: HP/MP, dano, cooldowns, movimento lógico.
  Recebe **comandos** (`cmd_move`, `cmd_use_skill`, `cmd_basic_attack`,
  `cmd_set_target`, `cmd_cycle_target`, `cmd_toggle_combo_mode`,
  `cmd_toggle_auto_face`) — nunca lê Input. Bots/rede usarão a mesma interface.
- `scripts/input/` — **input**: `player_controller.gd` é o único arquivo do
  projeto que lê `Input`/eventos (inclusive órbita/zoom da câmera, que são
  repassados por métodos ao rig).
- `scripts/view/` + `scripts/ui/` — **apresentação**: reagem a signals/estado
  da simulação (flash, hit stop, shake, números de dano, HUD). Nunca alteram
  gameplay.
- `data/skills/` — skills como Resources (`SkillData`), nada hardcoded.

## Como rodar (Windows, um clique)

1. Baixe o ZIP desta branch e extraia em qualquer pasta.
2. Dê dois cliques em **`play.bat`** — na primeira vez ele baixa o Godot 4.3
   portátil (release oficial, ~55 MB) para a pasta `godot/` do projeto e abre
   o editor. Nada é instalado no sistema.
3. No editor, aperte **F5** para jogar.

Se preferir manualmente: instale o Godot 4.3+ Standard de
[godotengine.org](https://godotengine.org/download/windows), importe o
`project.godot` e aperte F5.

## Controles

| Tecla | Ação |
|---|---|
| WASD | Movimento (relativo à câmera) |
| Botão direito + mouse | Rotação da câmera; scroll = zoom |
| Tab / clique esquerdo | Selecionar target |
| Espaço | Ataque básico (cadeia de 3: 50/55/70) |
| 1–5 | Skills (Rising Shot, Whirlwind, Charge, Earthquake, Berserk) |
| R | Modo combo (barra de timing; movimento trava) |
| Shift | Travar/destravar auto-face no target |

## O que testar

1. Andar com WASD, orbitar câmera com botão direito, zoom com scroll.
2. Tab alterna entre os 5 dummies; clique esquerdo também seleciona.
3. Espaço perto do dummy: cadeia de 3 golpes se apertar no ritmo. Dentro do
   alcance, o personagem vira e fecha a distância sozinho (estilo Cabal).
4. Skills 1–5: custo de MP, cooldown no quickslot, efeitos (launcher,
   AoE de 3 hits, dash com stun, AoE frontal pesado, buff Berserk).
5. R ativa o combo: usar a skill com o marcador na zona amarela encadeia
   (sem cast, +5% de dano por elo, máx +25%); errar quebra o combo.
6. Hit feedback: hit stop, flash branco, números de dano (crítico amarelo),
   screen shake em Charge/Earthquake, HP bar flutuante nos dummies.
7. O dummy `DummyRespawn` (à esquerda) respawna 5s depois de morrer.

## Integração futura de assets (Mixamo)

`player.tscn > View > AnimationPlayer` está esqueletado: se existir animação
com nome `attack_1..3` ou `skill_1..5`, a view toca ela em vez do placeholder
procedural. Troque o `Mesh` (cápsula) pelo modelo rigado e adicione as
animações com esses nomes.
