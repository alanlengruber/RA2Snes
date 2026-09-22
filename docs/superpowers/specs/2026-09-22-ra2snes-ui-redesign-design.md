# Redesign da interface do RA2Snes

**Data:** 2026-09-22
**Status:** aprovado, pronto para plano de implementação

## Objetivo

Modernizar a camada visual do RA2Snes, fazer a janela aproveitar a largura disponível, e
adicionar uma notificação de conquista desbloqueada no estilo dos consoles — uma caixa que
sobe no canto e se anuncia, em vez de apenas um som.

Três problemas concretos motivam o trabalho:

1. O conteúdo para de crescer em 900px. Maximizar a janela produz uma coluna estreita
   cercada de fundo vazio.
2. `compact.qml` (547 linhas) e `noncompact.qml` (642 linhas) mantêm dois layouts em
   paralelo, e já **divergiram em funcionalidade** — não são mais duplicatas, são dois
   produtos incompletos diferentes.
3. Um desbloqueio só produz som. Nada na tela identifica *qual* conquista caiu, porque o
   sinal que dispara o som não carrega dado nenhum.

## Decisões

| Decisão | Escolha | Razão |
|---|---|---|
| Escopo | Reestruturação completa | É o único caminho que resolve o aproveitamento de tela |
| Direção visual | Console Dashboard | Superfícies translúcidas, cantos arredondados, profundidade por sombra e glow |
| Estrutura | Cabeçalho full-width + grid fluido | Degrada melhor no estreito que sidebar; não exige conceitos novos como sidebar ou painel de detalhe |
| Movimento do toast | Slide-up com overshoot + pop no badge | Gesto de conquista reconhecível, sem a complexidade de animar largura |
| Beaten / Mastered | Nesta entrega | Os sinais já existem e já têm som; é variante do mesmo componente |
| Destino do toast | Janela principal **e** janela banner | A banner é a capturada no OBS — é onde o público vê |

## Divergência funcional a resolver

Os dois layouts atuais não têm o mesmo conjunto de recursos. A unificação precisa ser
**união**, não interseção:

| Recurso | `compact.qml` | `noncompact.qml` | Tela nova |
|---|---|---|---|
| Barra de progresso | sim (`progressLoader`, l.450) | não | sim |
| Rich presence | não | sim (l.352) | sim |
| `completionHeader` | não | existe com `visible: false` | removido (código morto) |

Hoje o usuário escolhe entre ver progresso ou ver rich presence. A tela nova tem os dois.

## Arquitetura de arquivos

```
ui/
├── mainwindow.qml            janela, HUD, fila de toast, acessor de tema
├── GameDashboard.qml         novo — o layout responsivo único
├── components/
│   ├── UserHeader.qml        pfp, nome, pontos, modo hardcore/softcore
│   ├── GameHeader.qml        ícone, título, console, progresso, rich presence
│   ├── AchievementCard.qml   delegate do grid
│   ├── AchievementToast.qml  novo — a notificação
│   └── ToastStack.qml        novo — fila e posicionamento
├── sorting.qml               mantido
├── banner.qml                recebe uma instância de ToastStack
└── themes/                   Dark, Black, Light atualizados
```

**Removidos:** `compact.qml`, `noncompact.qml`, `listview.qml`, `progressbar.qml`.
O conteúdo de `listview.qml` vira `AchievementCard.qml` mais um `GridView` dentro de
`GameDashboard.qml`; `progressbar.qml` é absorvido por `GameHeader.qml`.

Adicionar os novos arquivos a `ra2snes.qrc`.

A quebra em componentes não é organização pela organização: hoje o mesmo `Image` de badge
está copiado em quatro arquivos. Com `AchievementCard` isolado, o toast reusa o card do
grid — é isso que faz a notificação parecer parte do app em vez de um enxerto.

## Layout responsivo

Remover a trava em `mainwindow.qml`:

```qml
// antes
width: Math.min(mainWindow.width, 900)
// depois
width: mainWindow.width
```

Colunas derivam da largura, não de um botão:

```qml
readonly property int minCardWidth: dense ? 240 : 300
readonly property int columns: Math.max(1, Math.floor(availableWidth / minCardWidth))
readonly property real cellWidth: availableWidth / columns
```

`availableWidth` é a largura **não escalada**. O zoom `Ctrl +/-` aplica `mainGroup.scale`
(`mainwindow.qml:274-278`); usar a largura escalada faria o grid refluir durante o zoom e a
tela dançaria.

Breakpoints do cabeçalho:

| Largura | Cabeçalho | Grid |
|---|---|---|
| < 520px | usuário e jogo empilhados | 1 coluna |
| 520–860px | usuário e jogo lado a lado | 2 colunas |
| 860–1200px | + progresso inline | 3 colunas |
| > 1200px | idem | 4+ colunas |

`GridView` substitui `ListView` — a reciclagem de delegate passa a importar com 200+
conquistas em quatro colunas simultâneas.

### Setting `compact`

A chave `compact` já existe no `settings.ini` de usuários atuais. Ela continua sendo lida e
gravada por `ra2snes::saveUISettings`, com a assinatura intacta, mas muda de significado:
deixa de escolher layout e passa a escolher **densidade** do card (`dense` acima — 240px vs
300px de largura mínima). A intenção do usuário sobrevive sem custar dois arquivos.

## Camada C++

Uma única mudança, em `AchievementModel`.

```cpp
// achievementmodel.h
QVariantMap toVariantMap(const AchievementInfo &a) const;   // extraído de get()

signals:
    void unlockedChanged();                                   // inalterado
    void achievementUnlocked(const QVariantMap &achievement); // novo
```

`get(int row)` passa a ser um wrapper de `toVariantMap`, eliminando a duplicação do mapa de
campos.

`achievementUnlocked` é emitido em `unlockAchievement()`, imediatamente após o
`unlockedChanged()` existente.

**A assinatura de `unlockedChanged()` não muda.** Alterá-la quebraria o
`Connections { function onUnlockedChanged() }` que toca o som (`mainwindow.qml:234-240`).
Dois sinais emitidos do mesmo ponto ficam em lockstep sem acoplar som e toast.

### Propriedade de segurança já existente

`setUnlockedState()` — usada ao carregar as conquistas já obtidas no login
(`raclient.cpp:548`) — **não** emite `unlockedChanged()`. Apenas `unlockAchievement()`
emite. Logo o toast não dispara em massa ao logar num jogo já masterizado. Essa separação
já está no código; o design apenas se apoia nela e não deve ser desfeita.

O guard `mainWindow.setupFinished`, hoje aplicado ao som, vale igualmente para o toast.

## Sistema de temas

A direção visual precisa de tokens que o contrato atual não tem. Temas são extensíveis: o
app varre `<appdir>/themes/*.qml` em runtime (`mainwindow.qml:96-125`), então existem temas
de terceiros que não terão esses tokens.

Acessor com fallback em `mainwindow.qml`:

```qml
function themeColor(name, fallback) {
    const v = themeLoader.item ? themeLoader.item[name] : undefined;
    return (v === undefined || v === null) ? fallback : v;
}
```

`themeLoader.item` é dependência da binding, então trocar de tema reavalia normalmente.

Tokens novos e seus fallbacks, todos derivados de tokens que já existem no contrato:

| Token novo | Fallback |
|---|---|
| `cardBackgroundColor` | `mainWindowLightAccentColor` |
| `cardBorderColor` | `mainWindowBorderColor` |
| `cardHoverBackgroundColor` | `highlightedButtonBackgroundColor` |
| `surfaceElevatedColor` | `mainWindowDarkAccentColor` |
| `shadowColor` | `"#000000"` |
| `heroGradientStart` | `progressBarColor` |
| `heroGradientEnd` | `mainWindowLightAccentColor` |
| `toastBackgroundColor` | `popupBackgroundColor` |
| `toastBorderColor` | `progressBarColor` |
| `toastLabelColor` | `nonErrorMessageTextColor` |
| `toastTitleColor` | `basicTextColor` |
| `toastPointsColor` | `progressBarColor` |
| `beatenToastBorderColor` | `statusBeatenIconBackgroundColor` |
| `masteredToastBorderColor` | `statusMasteredIconBackgroundColor` |

Dark, Black e Light recebem os tokens completos. Sem o acessor, um tema de terceiro
produziria `TypeError` silencioso e cores transparentes — falha feia e difícil de
diagnosticar para quem não escreveu o tema.

## AchievementToast.qml

Componente puramente apresentacional. Não conhece a fila, não conhece o model.

```
Propriedades:  badgeUrl, title, points, variant
Variantes:     "achievement" | "beaten" | "mastered"
Sinal:         finished()
```

Movimento (variante `achievement`):

| Fase | Propriedade | Curva | Duração |
|---|---|---|---|
| Entrada | `y` +30→0, `opacity` 0→1, `scale` 0.94→1 | `Easing.OutBack` | 420ms |
| Pop do badge | `scale` 1→1.34→1, `rotation` 0→−7→0 | `Easing.OutQuad` | 500ms, início em 340ms |
| Brilho | `Glow` sobre o badge | — | junto ao pop |
| Espera | — | — | 3900ms |
| Saída | `y` 0→+22, `opacity` 1→0 | `Easing.InQuad` | 280ms |

`Qt5Compat.GraphicalEffects` já é importado em `compact.qml:5`, então `Glow` não adiciona
dependência nova ao projeto.

`beaten` e `mastered` usam o mesmo movimento com caixa maior, cor de borda própria
(tokens acima) e espera de 6000ms.

## ToastStack.qml

Não desenha nada. Mantém a fila e instancia um toast por vez.

```
Função:      push(data)
Comportamento: um toast por vez; ao receber finished(), espera 400ms e puxa o próximo
```

Nunca empilha toasts simultâneos. No RA é comum três desbloqueios caírem juntos ao terminar
uma fase, e três caixas sobrepostas seriam ilegíveis.

Esse é o mesmo padrão que o app já usa para os sons (`unlockSounds.soundQueue`,
`mainwindow.qml:221-230`), então som e toast permanecem em sincronia sem código extra.

### Posicionamento

Uma instância dentro do `hud` de `mainwindow.qml`, ancorada no canto inferior direito,
**acima** da `Row` de `challenges`. Os ícones de challenge indicam conquistas *primed* — a
conquista prestes a completar. Nascer por cima deles esconderia o indicador exatamente no
momento em que ele importa mais.

Uma segunda instância dentro de `banner.qml`. As duas leem os mesmos singletons, então não
há estado compartilhado a coordenar.

Conexões em ambas as janelas:

```qml
AchievementModel.onAchievementUnlocked  -> push(variant: "achievement")
GameInfoModel.onBeatenGame              -> push(variant: "beaten")
GameInfoModel.onMasteredGame            -> push(variant: "mastered")
```

## O que não muda

`usb2snes.cpp`, `memoryreader.cpp` e a lógica de rede de `raclient.cpp` ficam intocados. O
trabalho é a camada QML mais um sinal novo no model. `icons.qml` e o restante de
`banner.qml` seguem como estão. `settings.ini` existente continua válido.

## Riscos

| Risco | Mitigação |
|---|---|
| Tema de terceiro quebra | Acessor `themeColor` com fallback para todo token novo |
| Recurso perdido na unificação | Tabela de paridade acima é checklist de verificação |
| Grid reflui durante zoom | Cálculo de colunas usa largura não escalada |
| Toast dispara em massa no login | Apoiar-se na separação `setUnlockedState` / `unlockAchievement`, que já existe |
| Toast cobre ícones de challenge | Ancorar acima da `Row` de challenges |
| Regressão no áudio | Assinatura de `unlockedChanged()` preservada |

## Critérios de sucesso

Verificáveis, na ordem em que devem ser checados:

1. Compila com Qt 6.9 sem warnings novos.
2. Janela em 1400px: grid com 4 ou mais colunas, sem faixa vazia à direita.
3. Janela em 380px: 1 coluna, nada cortado, sem scroll horizontal.
4. Barra de progresso **e** rich presence visíveis na mesma tela.
5. Zoom `Ctrl +/-` não altera a contagem de colunas.
6. Login num jogo com conquistas já obtidas: nenhum toast dispara.
7. Desbloqueio ao vivo: um toast, com o badge e o título corretos.
8. Três desbloqueios simultâneos: três toasts em sequência, nenhum sobreposto.
9. Toast aparece também na janela banner.
10. `masteredGame()` produz o toast dourado maior.
11. Tema de terceiro (um `Dark.qml` com os tokens novos removidos) carrega sem `TypeError`
    no console e com cores coerentes.
12. `settings.ini` de versão anterior carrega sem erro.
