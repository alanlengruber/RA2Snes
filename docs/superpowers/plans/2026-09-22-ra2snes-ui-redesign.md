# RA2Snes UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir os dois layouts paralelos do RA2Snes por uma única tela responsiva com visual de dashboard de console, e adicionar notificações de conquista desbloqueada que sobem no canto da janela principal e da janela banner.

**Architecture:** A lógica pura (matemática de colunas, resolução de token de tema, sequenciamento da fila de toasts) é extraída para unidades testáveis — um arquivo JS de biblioteca e dois componentes QML pequenos — para que o TDD seja real e não teatral. O resto é composição visual, verificada manualmente. No C++ há uma única mudança: um sinal novo em `AchievementModel` que carrega o payload da conquista, emitido ao lado do sinal existente que toca o som.

**Tech Stack:** Qt 6.9, C++17, QML (Qt Quick, Qt Quick Controls 2 Material, Qt5Compat.GraphicalEffects), CMake 3.16+, QTest, Qt Quick Test.

**Spec:** [`docs/superpowers/specs/2026-09-22-ra2snes-ui-redesign-design.md`](../specs/2026-09-22-ra2snes-ui-redesign-design.md)

## ⚠️ Aviso sobre verificação

**Nenhum comando deste plano foi executado.** O ambiente onde ele foi escrito não tem Qt6
instalado — sem `qmake6`, sem `Qt6Config.cmake`, sem `Qt6Core.pc`. Todo bloco "Run:" foi
escrito para ser executado por quem implementar, num ambiente com Qt 6.9. Trate cada saída
esperada como previsão a confirmar, não como fato observado.

## Global Constraints

- Qt 6.9; C++17 (`CMAKE_CXX_STANDARD 17`).
- **Não alterar a assinatura de `AchievementModel::unlockedChanged()`.** O
  `Connections { function onUnlockedChanged() }` em `ui/mainwindow.qml:234-240` toca o som e
  quebra se ela mudar.
- **Não fazer `setUnlockedState()` emitir `unlockedChanged()`.** A separação entre
  `setUnlockedState` (carga inicial, `raclient.cpp:548`) e `unlockAchievement` (desbloqueio
  ao vivo) é o que impede o toast de disparar em massa no login.
- Todo token de tema novo é lido via fallback. Um tema de terceiro sem o token precisa
  carregar sem `TypeError`.
- O cálculo de colunas usa largura **não escalada**. `mainGroup.scale` (`ui/mainwindow.qml:274-278`)
  é o zoom `Ctrl +/-`; usar a largura escalada faz o grid refluir durante o zoom.
- Arquivos QML novos precisam ser adicionados a **`ra2snes.qrc`** (lista explícita) e
  cobertos pelo `file(GLOB ...)` do `CMakeLists.txt`. `ui/components/*` **não** é coberto
  pelo glob atual `${CMAKE_SOURCE_DIR}/ui/*`.
- `AchievementModel`, `GameInfoModel` e `UserInfoModel` são singletons com construtor
  privado. Testes usam `instance()` e isolam estado com `clearAchievements()` /
  `setAchievements()` no `init()`/`cleanup()`.
- Mensagens de commit em inglês, seguindo o histórico do repositório.

## Desvios deliberados da spec

Dois pontos onde este plano se afasta do documento de design. Ambos servem à mesma coisa —
tornar o TDD real em vez de teatral — e nenhum muda o comportamento acordado.

1. **`themeColor` virou o componente `ThemeResolver`.** A spec descreve uma função em
   `ui/mainwindow.qml` com assinatura `themeColor(name, fallback)`. Uma função presa ao
   `mainwindow` só pode ser testada abrindo a janela inteira. Como componente separado ela
   é testável com temas falsos (Task 4). A assinatura também ganhou um terceiro argumento,
   `hardFallback`, para o caso em que o token de fallback do contrato antigo também não
   existe — sem ele, um tema muito antigo ainda devolveria `undefined`.
2. **A matemática de colunas virou `ui/LayoutMath.js`.** A spec mostra o cálculo inline no
   layout. Inline, os breakpoints só se verificam redimensionando a janela à mão. Como
   biblioteca JS, viram seis asserções (Task 3).

---

## File Structure

| Arquivo | Responsabilidade | Task |
|---|---|---|
| `tests/CMakeLists.txt` | Alvos de teste | 1 |
| `tests/tst_achievementmodel.cpp` | Testes C++ do model | 1, 2 |
| `tests/tst_qml.cpp` | Runner do Qt Quick Test | 1 |
| `tests/qml/tst_layoutmath.qml` | Testes da matemática de colunas | 3 |
| `tests/qml/tst_themeresolver.qml` | Testes do fallback de tema | 4 |
| `tests/qml/tst_toaststack.qml` | Testes da fila de toasts | 10 |
| `achievementmodel.{h,cpp}` | + `toVariantMap`, + sinal com payload | 2 |
| `ui/LayoutMath.js` | Matemática pura de colunas | 3 |
| `ui/components/ThemeResolver.qml` | Resolução de token com fallback | 4 |
| `ui/themes/{Dark,Black,Light}.qml` | + 14 tokens novos | 4 |
| `ui/components/AchievementCard.qml` | Delegate do grid, reusado no toast | 5 |
| `ui/components/UserHeader.qml` | Bloco de usuário | 6 |
| `ui/components/GameHeader.qml` | Jogo, progresso, rich presence | 6 |
| `ui/GameDashboard.qml` | Layout responsivo único | 7 |
| `ui/mainwindow.qml` | Troca de loader, HUD, fila | 8, 11 |
| `ui/components/AchievementToast.qml` | A notificação | 9 |
| `ui/components/ToastStack.qml` | Fila e posicionamento | 10 |
| `ui/banner.qml` | + instância de ToastStack | 11 |
| `ra2snes.cpp` | `compact` vira densidade | 12 |

**Deletados na Task 8:** `ui/compact.qml`, `ui/noncompact.qml`, `ui/listview.qml`, `ui/progressbar.qml`.

---

## Task 1: Infraestrutura de teste

O projeto não tem nenhum teste hoje. Sem esta task, todas as seguintes são verificadas só
a olho.

**Files:**
- Create: `tests/CMakeLists.txt`
- Create: `tests/tst_achievementmodel.cpp`
- Create: `tests/tst_qml.cpp`
- Create: `tests/qml/tst_smoke.qml`
- Modify: `CMakeLists.txt`

**Interfaces:**
- Consumes: nada.
- Produces: alvos `tst_achievementmodel` e `tst_qml`; `ctest` roda os dois. Tasks
  seguintes adicionam arquivos a `tests/` e a `tests/qml/`.

- [ ] **Step 1: Escrever o teste C++ que falha**

`tests/tst_achievementmodel.cpp`:

```cpp
#include <QtTest>
#include "achievementmodel.h"
#include "rastructs.h"

class TestAchievementModel : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();
    void modelStartsEmpty();
};

void TestAchievementModel::init()
{
    AchievementModel::instance()->clearAchievements();
}

void TestAchievementModel::cleanup()
{
    AchievementModel::instance()->clearAchievements();
}

void TestAchievementModel::modelStartsEmpty()
{
    QCOMPARE(AchievementModel::instance()->rowCount(), 0);
}

QTEST_MAIN(TestAchievementModel)
#include "tst_achievementmodel.moc"
```

- [ ] **Step 2: Escrever o smoke test QML que falha**

`tests/qml/tst_smoke.qml`:

```qml
import QtQuick
import QtTest

TestCase {
    name: "Smoke"

    function test_harness_runs() {
        compare(1 + 1, 2);
    }
}
```

`tests/tst_qml.cpp`:

```cpp
#include <QtQuickTest>

QUICK_TEST_MAIN(ra2snes_qml)
```

- [ ] **Step 3: Escrever `tests/CMakeLists.txt`**

```cmake
find_package(Qt6 REQUIRED COMPONENTS Test QuickTest)

qt_add_executable(tst_achievementmodel
    tst_achievementmodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementmodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementmodel.h
    ${CMAKE_SOURCE_DIR}/rastructs.h
)
target_include_directories(tst_achievementmodel PRIVATE ${CMAKE_SOURCE_DIR})
target_link_libraries(tst_achievementmodel PRIVATE Qt6::Core Qt6::Test)
add_test(NAME achievementmodel COMMAND tst_achievementmodel)

qt_add_executable(tst_qml tst_qml.cpp)
target_link_libraries(tst_qml PRIVATE Qt6::QuickTest Qt6::Qml Qt6::Quick)
add_test(NAME qml COMMAND tst_qml -input ${CMAKE_CURRENT_SOURCE_DIR}/qml)
```

`Qt6::Quick` é necessário porque a partir da Task 10 os testes instanciam `ToastStack`, que
cria um `AchievementToast` — e este importa `Qt5Compat.GraphicalEffects`. Esse é um módulo
QML resolvido em runtime, não um alvo de link: se `ctest` falhar na Task 10 com
`module "Qt5Compat.GraphicalEffects" is not installed`, instalar o pacote Qt5Compat da sua
distribuição de Qt. O app principal já depende dele hoje (`ui/compact.qml:5`), então quem
consegue compilar o RA2Snes já o tem.

- [ ] **Step 4: Ligar no `CMakeLists.txt` raiz**

Adicionar ao final do arquivo, depois do `qt_finalize_executable(ra2snes)`:

```cmake
option(RA2SNES_BUILD_TESTS "Build the test suite" ON)
if(RA2SNES_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
```

- [ ] **Step 5: Configurar e rodar — deve falhar na configuração**

Run:
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
```
Expected: se `Qt6::Test` ou `Qt6::QuickTest` não estiverem instalados, o CMake falha com
`Could not find a package configuration file provided by "Qt6Test"`. Instalar o módulo de
testes do Qt e repetir até configurar.

- [ ] **Step 6: Compilar e rodar os testes**

Run:
```bash
cmake --build build --target tst_achievementmodel tst_qml -j
ctest --test-dir build --output-on-failure
```
Expected: PASS nos dois — `modelStartsEmpty` e `test_harness_runs`.

Se `tst_achievementmodel` falhar no link com erro de `vtable`/`moc`, confirmar que
`CMAKE_AUTOMOC` está `ON` (está, na linha 6 do CMakeLists raiz) e que o
`#include "tst_achievementmodel.moc"` está na última linha do arquivo.

- [ ] **Step 7: Commit**

```bash
git add tests CMakeLists.txt
git commit -m "test: add QTest and Qt Quick Test harness"
```

---

## Task 2: Sinal de desbloqueio com payload

**Files:**
- Modify: `achievementmodel.h`
- Modify: `achievementmodel.cpp`
- Test: `tests/tst_achievementmodel.cpp`

**Interfaces:**
- Consumes: harness da Task 1.
- Produces: `AchievementModel::achievementUnlocked(const QVariantMap &achievement)`. As
  chaves do mapa são exatamente as de `get(int)`: `badgeLockedUrl`, `badgeName`, `badgeUrl`,
  `description`, `flags`, `id`, `memAddr`, `points`, `title`, `type`, `timeUnlocked`,
  `timeUnlockedString`, `unlocked`, `achievementLink`, `primed`, `value`, `percent`,
  `target`. Consumido pelas Tasks 9, 10 e 11.
- Produces: `QVariantMap AchievementModel::toVariantMap(const AchievementInfo &a) const`.

- [ ] **Step 1: Escrever os testes que falham**

Adicionar em `tests/tst_achievementmodel.cpp`, na lista de `private slots`:

```cpp
    void emitsPayloadOnLiveUnlock();
    void doesNotEmitOnSetUnlockedState();
    void getMatchesToVariantMap();
```

E os corpos, antes de `QTEST_MAIN`:

```cpp
static AchievementInfo makeAchievement()
{
    AchievementInfo a;
    a.id = 42;
    a.title = "KONGQuest";
    a.description = "Clear Gangplank Galley";
    a.points = 7;
    a.badge_url = QUrl("https://media.retroachievements.org/Badge/12345.png");
    a.badge_locked_url = QUrl("https://media.retroachievements.org/Badge/12345_lock.png");
    a.target = 3;
    return a;
}

void TestAchievementModel::emitsPayloadOnLiveUnlock()
{
    AchievementModel *model = AchievementModel::instance();
    model->setAchievements({ makeAchievement() });

    QSignalSpy spy(model, &AchievementModel::achievementUnlocked);
    model->unlockAchievement(42, QDateTime::currentDateTime());

    QCOMPARE(spy.count(), 1);
    const QVariantMap payload = spy.takeFirst().at(0).toMap();
    QCOMPARE(payload.value("title").toString(), QStringLiteral("KONGQuest"));
    QCOMPARE(payload.value("points").toUInt(), 7u);
    QCOMPARE(payload.value("id").toUInt(), 42u);
    QVERIFY(payload.value("unlocked").toBool());
    QVERIFY(!payload.value("badgeUrl").toUrl().isEmpty());
}

void TestAchievementModel::doesNotEmitOnSetUnlockedState()
{
    AchievementModel *model = AchievementModel::instance();
    model->setAchievements({ makeAchievement() });

    QSignalSpy payloadSpy(model, &AchievementModel::achievementUnlocked);
    QSignalSpy soundSpy(model, &AchievementModel::unlockedChanged);

    model->setUnlockedState(0, true, QDateTime::currentDateTime());

    QCOMPARE(payloadSpy.count(), 0);
    QCOMPARE(soundSpy.count(), 0);
}

void TestAchievementModel::getMatchesToVariantMap()
{
    AchievementModel *model = AchievementModel::instance();
    const AchievementInfo a = makeAchievement();
    model->setAchievements({ a });

    QCOMPARE(model->get(0), model->toVariantMap(a));
}
```

`doesNotEmitOnSetUnlockedState` é o teste de regressão do Global Constraint mais fácil de
quebrar sem perceber: ele trava a separação entre carga inicial e desbloqueio ao vivo.

- [ ] **Step 2: Rodar para ver falhar**

Run: `cmake --build build --target tst_achievementmodel -j && ctest --test-dir build -R achievementmodel --output-on-failure`
Expected: FAIL na compilação — `'achievementUnlocked' is not a member of 'AchievementModel'`
e `'toVariantMap' was not declared`.

- [ ] **Step 3: Declarar no header**

Em `achievementmodel.h`, dentro de `public:`, logo abaixo de `Q_INVOKABLE QVariantMap get(int row) const;`:

```cpp
    QVariantMap toVariantMap(const AchievementInfo &a) const;
```

E em `signals:`, abaixo de `void unlockedChanged();`:

```cpp
    void achievementUnlocked(const QVariantMap &achievement);
```

- [ ] **Step 4: Implementar**

Em `achievementmodel.cpp`, substituir o corpo inteiro de `get` por:

```cpp
QVariantMap AchievementModel::toVariantMap(const AchievementInfo &a) const {
    QVariantMap map;

    map["badgeLockedUrl"] = a.badge_locked_url;
    map["badgeName"] = a.badge_name;
    map["badgeUrl"] = a.badge_url;
    map["description"] = a.description;
    map["flags"] = a.flags;
    map["id"] = a.id;
    map["memAddr"] = a.mem_addr;
    map["points"] = a.points;
    map["title"] = a.title;
    map["type"] = a.type;
    map["timeUnlocked"] = a.time_unlocked;
    map["timeUnlockedString"] = a.time_unlocked_string;
    map["unlocked"] = a.unlocked;
    map["achievementLink"] = a.achievement_link;
    map["primed"] = a.primed;
    map["value"] = a.value;
    map["percent"] = a.percent;
    map["target"] = a.target;

    return map;
}

QVariantMap AchievementModel::get(int row) const {
    if (row < 0 || row >= m_achievements.size())
        return QVariantMap();

    return toVariantMap(m_achievements.at(row));
}
```

Em `unlockAchievement`, logo após `emit unlockedChanged();` e antes de `return &a;`:

```cpp
    emit achievementUnlocked(toVariantMap(a));
```

- [ ] **Step 5: Rodar para ver passar**

Run: `cmake --build build --target tst_achievementmodel -j && ctest --test-dir build -R achievementmodel --output-on-failure`
Expected: PASS nos quatro testes.

- [ ] **Step 6: Commit**

```bash
git add achievementmodel.h achievementmodel.cpp tests/tst_achievementmodel.cpp
git commit -m "feat: emit achievement payload on live unlock"
```

---

## Task 3: Matemática de colunas

**Files:**
- Create: `ui/LayoutMath.js`
- Create: `tests/qml/tst_layoutmath.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: harness da Task 1.
- Produces: `LayoutMath.columnsFor(availableWidth, minCardWidth)` → `int` (mínimo 1);
  `LayoutMath.cellWidthFor(availableWidth, minCardWidth)` → `real`;
  `LayoutMath.headerMode(availableWidth)` → `"stacked" | "side" | "inline"`.
  Consumido pela Task 7.

- [ ] **Step 1: Escrever o teste que falha**

`tests/qml/tst_layoutmath.qml`:

```qml
import QtQuick
import QtTest
import "../../ui/LayoutMath.js" as LayoutMath

TestCase {
    name: "LayoutMath"

    function test_never_returns_zero_columns() {
        compare(LayoutMath.columnsFor(0, 300), 1);
        compare(LayoutMath.columnsFor(120, 300), 1);
        compare(LayoutMath.columnsFor(-50, 300), 1);
    }

    function test_columns_scale_with_width() {
        compare(LayoutMath.columnsFor(380, 300), 1);
        compare(LayoutMath.columnsFor(620, 300), 2);
        compare(LayoutMath.columnsFor(950, 300), 3);
        compare(LayoutMath.columnsFor(1400, 300), 4);
    }

    function test_dense_fits_more_columns() {
        compare(LayoutMath.columnsFor(1000, 240), 4);
        compare(LayoutMath.columnsFor(1000, 300), 3);
    }

    function test_cell_width_fills_available_width() {
        compare(LayoutMath.cellWidthFor(1200, 300), 300);
        compare(LayoutMath.cellWidthFor(1000, 300), 1000 / 3);
    }

    function test_header_mode_breakpoints() {
        compare(LayoutMath.headerMode(400), "stacked");
        compare(LayoutMath.headerMode(519), "stacked");
        compare(LayoutMath.headerMode(520), "side");
        compare(LayoutMath.headerMode(859), "side");
        compare(LayoutMath.headerMode(860), "inline");
        compare(LayoutMath.headerMode(1600), "inline");
    }

    function test_guards_against_bad_card_width() {
        compare(LayoutMath.columnsFor(1200, 0), 1);
        compare(LayoutMath.columnsFor(1200, -10), 1);
    }
}
```

- [ ] **Step 2: Rodar para ver falhar**

Run: `cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: FAIL — o arquivo `ui/LayoutMath.js` não existe, erro de import.

- [ ] **Step 3: Implementar**

`ui/LayoutMath.js`:

```javascript
.pragma library

function columnsFor(availableWidth, minCardWidth) {
    if (!(minCardWidth > 0))
        return 1;
    if (!(availableWidth > 0))
        return 1;

    return Math.max(1, Math.floor(availableWidth / minCardWidth));
}

function cellWidthFor(availableWidth, minCardWidth) {
    return availableWidth / columnsFor(availableWidth, minCardWidth);
}

function headerMode(availableWidth) {
    if (availableWidth < 520)
        return "stacked";
    if (availableWidth < 860)
        return "side";
    return "inline";
}
```

- [ ] **Step 4: Registrar no qrc**

Em `ra2snes.qrc`, dentro de `<qresource prefix="/">`:

```xml
        <file>ui/LayoutMath.js</file>
```

- [ ] **Step 5: Rodar para ver passar**

Run: `cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: PASS nos seis testes de `LayoutMath` mais o smoke.

- [ ] **Step 6: Commit**

```bash
git add ui/LayoutMath.js tests/qml/tst_layoutmath.qml ra2snes.qrc
git commit -m "feat: add responsive column math"
```

---

## Task 4: Tokens de tema com fallback

**Files:**
- Create: `ui/components/ThemeResolver.qml`
- Create: `tests/qml/tst_themeresolver.qml`
- Modify: `ui/themes/Dark.qml`, `ui/themes/Black.qml`, `ui/themes/Light.qml`
- Modify: `ra2snes.qrc`, `CMakeLists.txt`

**Interfaces:**
- Consumes: nada.
- Produces: `ThemeResolver` com `property var theme` e
  `function color(name, fallbackName, hardFallback)` → `color`. Consumido pelas Tasks 5, 6,
  7, 9.

- [ ] **Step 1: Escrever o teste que falha**

`tests/qml/tst_themeresolver.qml`:

```qml
import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "ThemeResolver"

    // Tema "de terceiro": só os tokens antigos, nenhum dos novos.
    QtObject {
        id: legacyTheme
        property color progressBarColor: "#eab308"
        property color popupBackgroundColor: "#2a2a2a"
        property color mainWindowLightAccentColor: "#282828"
    }

    QtObject {
        id: modernTheme
        property color progressBarColor: "#eab308"
        property color popupBackgroundColor: "#2a2a2a"
        property color mainWindowLightAccentColor: "#282828"
        property color toastBorderColor: "#6ee7a8"
    }

    ThemeResolver {
        id: resolver
    }

    function test_uses_token_when_present() {
        resolver.theme = modernTheme;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#ff00ff"),
                Qt.color("#6ee7a8"));
    }

    function test_falls_back_to_legacy_token() {
        resolver.theme = legacyTheme;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#ff00ff"),
                Qt.color("#eab308"));
    }

    function test_falls_back_to_hard_default_when_both_missing() {
        resolver.theme = legacyTheme;
        compare(resolver.color("shadowColor", "alsoMissing", "#000000"),
                Qt.color("#000000"));
    }

    function test_null_theme_does_not_throw() {
        resolver.theme = null;
        compare(resolver.color("toastBorderColor", "progressBarColor", "#123456"),
                Qt.color("#123456"));
    }
}
```

- [ ] **Step 2: Rodar para ver falhar**

Run: `cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: FAIL — `ThemeResolver is not a type`.

- [ ] **Step 3: Implementar**

`ui/components/ThemeResolver.qml`:

```qml
import QtQuick

QtObject {
    id: resolver

    // O Item carregado pelo themeLoader. Pode ser null enquanto o tema carrega.
    property var theme: null

    // Lê um token do tema. Se o tema não tiver esse token — caso dos temas de
    // terceiro, que foram escritos antes destes nomes existirem — cai para um
    // token do contrato antigo, e só então para uma cor literal.
    function color(name, fallbackName, hardFallback) {
        var value = _read(name);
        if (value !== undefined)
            return value;

        value = _read(fallbackName);
        if (value !== undefined)
            return value;

        return hardFallback;
    }

    function _read(name) {
        if (!theme || !name)
            return undefined;

        var value = theme[name];
        if (value === undefined || value === null)
            return undefined;

        return value;
    }
}
```

- [ ] **Step 4: Adicionar os tokens aos três temas embutidos**

Em `ui/themes/Dark.qml`, antes da chave final `}`:

```qml
	//Cards
	property color cardBackgroundColor: "#242428"
	property color cardBorderColor: "#32323a"
	property color cardHoverBackgroundColor: "#2e2e36"
	property color surfaceElevatedColor: "#1b1b1f"
	property color shadowColor: "#000000"
	property color heroGradientStart: "#2b3a33"
	property color heroGradientEnd: "#1d1d22"

	//Toast
	property color toastBackgroundColor: "#16201c"
	property color toastBorderColor: "#6ee7a8"
	property color toastLabelColor: "#6ee7a8"
	property color toastTitleColor: "#ffffff"
	property color toastPointsColor: "#6ee7a8"
	property color beatenToastBorderColor: "#d4d4d4"
	property color masteredToastBorderColor: "#ffd700"
```

Em `ui/themes/Black.qml`, antes da chave final `}`:

```qml
	//Cards
	property color cardBackgroundColor: "#121212"
	property color cardBorderColor: "#242424"
	property color cardHoverBackgroundColor: "#1c1c1c"
	property color surfaceElevatedColor: "#0a0a0a"
	property color shadowColor: "#000000"
	property color heroGradientStart: "#1a241f"
	property color heroGradientEnd: "#0a0a0a"

	//Toast
	property color toastBackgroundColor: "#0d1411"
	property color toastBorderColor: "#6ee7a8"
	property color toastLabelColor: "#6ee7a8"
	property color toastTitleColor: "#ffffff"
	property color toastPointsColor: "#6ee7a8"
	property color beatenToastBorderColor: "#d4d4d4"
	property color masteredToastBorderColor: "#ffd700"
```

Em `ui/themes/Light.qml`, antes da chave final `}`:

```qml
	//Cards
	property color cardBackgroundColor: "#ffffff"
	property color cardBorderColor: "#d8d8de"
	property color cardHoverBackgroundColor: "#f1f1f5"
	property color surfaceElevatedColor: "#f7f7fa"
	property color shadowColor: "#40000000"
	property color heroGradientStart: "#dcf0e5"
	property color heroGradientEnd: "#f7f7fa"

	//Toast
	property color toastBackgroundColor: "#ffffff"
	property color toastBorderColor: "#1f9d5a"
	property color toastLabelColor: "#1f9d5a"
	property color toastTitleColor: "#1a1a1a"
	property color toastPointsColor: "#1f9d5a"
	property color beatenToastBorderColor: "#6b6b6b"
	property color masteredToastBorderColor: "#b8860b"
```

Não tocar em `ui/themes/Test.qml` — ele fica de propósito sem os tokens novos e serve como
tema de terceiro para o critério de sucesso 11.

- [ ] **Step 5: Registrar no qrc e no glob do CMake**

Em `ra2snes.qrc`:

```xml
        <file>ui/components/ThemeResolver.qml</file>
```

Em `CMakeLists.txt`, logo abaixo de `file(GLOB UI_IMAGES ...)`:

```cmake
file(GLOB UI_COMPONENTS ${CMAKE_SOURCE_DIR}/ui/components/*)
```

E em `set(PROJECT_SOURCES ...)`, abaixo de `${UI_IMAGES}`:

```cmake
    ${UI_COMPONENTS}
```

- [ ] **Step 6: Rodar para ver passar**

Run: `cmake -S . -B build && cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: PASS nos quatro testes de `ThemeResolver`.

- [ ] **Step 7: Commit**

```bash
git add ui/components/ThemeResolver.qml ui/themes tests/qml/tst_themeresolver.qml ra2snes.qrc CMakeLists.txt
git commit -m "feat: add theme token resolver with legacy fallback"
```

---

## Task 5: AchievementCard.qml

**Files:**
- Create: `ui/components/AchievementCard.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `ThemeResolver` (Task 4).
- Produces: `AchievementCard` com as propriedades `badgeUrl`, `lockedBadgeUrl`, `title`,
  `description`, `points`, `unlocked`, `primed`, `achievementType`, `value`, `target`,
  `percent`, `timeUnlockedString`, `achievementLink`, `resolver`, `dense`; e o sinal
  `linkActivated(url)`. Consumido pelas Tasks 7 e 9.

- [ ] **Step 1: Ler o delegate atual antes de reescrever**

Run: `sed -n '1,140p' ui/listview.qml`
O delegate existente carrega comportamento que não pode se perder: badge alterna entre
`badgeUrl` e `badgeLockedUrl` conforme `unlocked`; título é link clicável com transição de
cor no hover; barra de progresso para conquistas com `target > 0`; selo de *primed*; selo de
tipo (`missable`, `progression`, `win_condition`) com os SVGs de `ui/images/`.

- [ ] **Step 2: Implementar o componente**

`ui/components/AchievementCard.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: card

    property url badgeUrl
    property url lockedBadgeUrl
    property string title: ""
    property string description: ""
    property int points: 0
    property bool unlocked: false
    property bool primed: false
    property string achievementType: ""
    property int value: 0
    property int target: 0
    property int percent: 0
    property string timeUnlockedString: ""
    property url achievementLink
    property var resolver: null
    property bool dense: false

    signal linkActivated(url link)

    readonly property int pad: dense ? 8 : 12
    readonly property int badgeSize: dense ? 40 : 52
    readonly property bool hasProgress: target > 0 && !unlocked

    implicitHeight: layout.implicitHeight + pad * 2
    radius: dense ? 8 : 10
    border.width: 1
    // O GridView exige célula de tamanho fixo, então o card preenche a célula e
    // ignora o próprio implicitHeight. O clip impede que um título ou descrição
    // longa vaze para a célula vizinha.
    clip: true

    color: hover.hovered
           ? _c("cardHoverBackgroundColor", "highlightedButtonBackgroundColor", "#2e2e36")
           : _c("cardBackgroundColor", "mainWindowLightAccentColor", "#242428")
    border.color: _c("cardBorderColor", "mainWindowBorderColor", "#32323a")
    opacity: unlocked ? 1.0 : 0.82

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on opacity { NumberAnimation { duration: 140 } }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    HoverHandler { id: hover }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: card.pad

        Image {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: card.badgeSize
            Layout.preferredHeight: card.badgeSize
            source: card.unlocked ? card.badgeUrl : card.lockedBadgeUrl
            sourceSize.width: card.badgeSize * 2
            sourceSize.height: card.badgeSize * 2
            asynchronous: true
            cache: true
            smooth: true

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: "transparent"
                border.width: card.primed ? 2 : 0
                border.color: card._c("toastBorderColor", "progressBarColor", "#6ee7a8")
                visible: card.primed
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: card.title
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: card.dense ? 12 : 14
                    color: titleHover.hovered
                           ? card._c("selectedLink", "basicTextColor", "#c8c8c8")
                           : card._c("toastTitleColor", "linkColor", "#ffffff")

                    Behavior on color { ColorAnimation { duration: 180 } }

                    HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: card.linkActivated(card.achievementLink)
                    }
                }

                Text {
                    text: card.points
                    font.bold: true
                    font.pixelSize: card.dense ? 12 : 14
                    color: card._c("toastPointsColor", "progressBarColor", "#6ee7a8")
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.description
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: card.dense ? 10 : 11
                color: card._c("disabledTextColor", "basicTextColor", "#9a9aa6")
            }

            Text {
                Layout.fillWidth: true
                visible: card.unlocked && card.timeUnlockedString !== ""
                text: card.timeUnlockedString
                elide: Text.ElideRight
                font.pixelSize: 9
                color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                visible: card.hasProgress
                height: 5
                radius: 3
                color: card._c("progressBarBackgroundColor", "mainWindowDarkAccentColor", "#2a2a2a")

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, card.percent / 100))
                    color: card._c("progressBarColor", "basicTextColor", "#eab308")

                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                visible: card.hasProgress
                text: card.value + " / " + card.target
                font.pixelSize: 9
                color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
            }

            Row {
                spacing: 4
                visible: card.achievementType !== ""

                Image {
                    width: 12
                    height: 12
                    source: {
                        if (card.achievementType === "missable")
                            return "../images/missable.svg";
                        if (card.achievementType === "progression")
                            return "../images/progression.svg";
                        if (card.achievementType === "win_condition")
                            return "../images/win_condition.svg";
                        return "";
                    }
                    visible: source != ""
                    sourceSize.width: 24
                    sourceSize.height: 24
                }

                Text {
                    text: card.achievementType
                    font.pixelSize: 9
                    color: card._c("timeStampColor", "disabledTextColor", "#7e7e7e")
                }
            }
        }
    }
}
```

- [ ] **Step 3: Registrar no qrc**

```xml
        <file>ui/components/AchievementCard.qml</file>
```

- [ ] **Step 4: Verificar que compila**

Run:
```bash
cmake --build build --target ra2snes -j
```
Expected: compila sem erro. O componente ainda não é usado por ninguém — este passo só
garante que o QML entrou no recurso e não tem erro de sintaxe.

Verificação adicional de sintaxe, se `qmllint` estiver disponível:
```bash
qmllint ui/components/AchievementCard.qml
```
Expected: sem erro. Avisos sobre tipos não resolvidos de `CustomModels` são esperados
porque o componente não importa os singletons — ele é puramente apresentacional, por
desenho.

- [ ] **Step 5: Commit**

```bash
git add ui/components/AchievementCard.qml ra2snes.qrc
git commit -m "feat: add reusable achievement card component"
```

---

## Task 6: UserHeader.qml e GameHeader.qml

**Files:**
- Create: `ui/components/UserHeader.qml`
- Create: `ui/components/GameHeader.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `ThemeResolver` (Task 4).
- Produces: `UserHeader` (props: `resolver`, `dense`; sinal `linkActivated(url)`) e
  `GameHeader` (props: `resolver`, `dense`, `showRichPresence`; sinal `linkActivated(url)`).
  Ambos leem `UserInfoModel`, `GameInfoModel` e `Ra2snes` diretamente. Consumido pela Task 7.

- [ ] **Step 1: Implementar `UserHeader.qml`**

```qml
import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

RowLayout {
    id: header

    property var resolver: null
    property bool dense: false

    signal linkActivated(url link)

    spacing: dense ? 8 : 10

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    Image {
        Layout.preferredWidth: header.dense ? 30 : 38
        Layout.preferredHeight: header.dense ? 30 : 38
        source: UserInfoModel.pfp
        sourceSize.width: 76
        sourceSize.height: 76
        asynchronous: true
        cache: true
        smooth: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: header.dense ? 30 : 38
                height: header.dense ? 30 : 38
                radius: width / 2
            }
        }
    }

    ColumnLayout {
        spacing: 1

        Text {
            text: UserInfoModel.username
            font.bold: true
            font.pixelSize: header.dense ? 14 : 16
            color: nameHover.hovered
                   ? header._c("selectedLink", "basicTextColor", "#c8c8c8")
                   : header._c("toastTitleColor", "linkColor", "#ffffff")

            Behavior on color { ColorAnimation { duration: 180 } }

            HoverHandler { id: nameHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: header.linkActivated(UserInfoModel.link) }
        }

        Text {
            text: (UserInfoModel.hardcore
                   ? UserInfoModel.hardcore_score
                   : UserInfoModel.softcore_score) + qsTr(" pontos")
            font.pixelSize: header.dense ? 10 : 11
            color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
        }
    }

    Item { Layout.fillWidth: true }

    Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: modeLabel.implicitWidth + 16
        radius: 10
        color: UserInfoModel.hardcore
               ? header._c("hardcoreTextColor", "errorMessageTextColor", "#ff0000")
               : header._c("softcoreTextColor", "nonErrorMessageTextColor", "#00ff00")

        Text {
            id: modeLabel
            anchors.centerIn: parent
            text: UserInfoModel.hardcore ? qsTr("Hardcore") : qsTr("Softcore")
            font.bold: true
            font.pixelSize: 9
            color: header._c("surfaceElevatedColor", "mainWindowDarkAccentColor", "#161616")
        }
    }
}
```

`OpacityMask` vem de `Qt5Compat.GraphicalEffects`, que precisa estar importado. Adicionar
`import Qt5Compat.GraphicalEffects` no topo junto aos outros imports.

- [ ] **Step 2: Implementar `GameHeader.qml`**

Este componente é o que resolve a divergência funcional registrada na spec: ele tem **a
barra de progresso e o rich presence juntos**, o que nenhum dos dois layouts atuais tem.

```qml
import QtQuick
import QtQuick.Layouts
import CustomModels 1.0

Rectangle {
    id: header

    property var resolver: null
    property bool dense: false
    property bool showRichPresence: true

    signal linkActivated(url link)

    readonly property int pad: dense ? 9 : 13
    readonly property real progress: GameInfoModel.point_total > 0
                                     ? GameInfoModel.point_count / GameInfoModel.point_total
                                     : 0

    implicitHeight: layout.implicitHeight + pad * 2
    radius: 10
    border.width: 1
    border.color: header._c("cardBorderColor", "mainWindowBorderColor", "#32323a")

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: header._c("heroGradientStart", "mainWindowLightAccentColor", "#2b3a33")
        }
        GradientStop {
            position: 1.0
            color: header._c("heroGradientEnd", "mainWindowDarkAccentColor", "#1d1d22")
        }
    }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: header.pad
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Image {
                Layout.preferredWidth: header.dense ? 30 : 40
                Layout.preferredHeight: header.dense ? 30 : 40
                source: GameInfoModel.image_icon_url
                sourceSize.width: 80
                sourceSize.height: 80
                asynchronous: true
                cache: true
                smooth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: GameInfoModel.title
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: header.dense ? 12 : 14
                    color: gameHover.hovered
                           ? header._c("selectedLink", "basicTextColor", "#c8c8c8")
                           : header._c("toastTitleColor", "linkColor", "#ffffff")

                    Behavior on color { ColorAnimation { duration: 180 } }

                    HoverHandler { id: gameHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: header.linkActivated(GameInfoModel.game_link) }
                }

                RowLayout {
                    spacing: 5

                    Image {
                        Layout.preferredWidth: 13
                        Layout.preferredHeight: 13
                        source: GameInfoModel.console_icon
                        sourceSize.width: 26
                        sourceSize.height: 26
                        asynchronous: true
                        cache: true
                    }

                    Text {
                        text: GameInfoModel.console
                        font.pixelSize: 10
                        color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
                    }

                    Text {
                        text: "· " + GameInfoModel.completion_count + " / "
                              + GameInfoModel.achievement_count
                        font.pixelSize: 10
                        color: header._c("disabledTextColor", "basicTextColor", "#8fa39a")
                    }

                    Row {
                        spacing: 3
                        visible: GameInfoModel.missable_count > 0

                        Image {
                            width: 11
                            height: 11
                            source: "../images/missable.svg"
                            sourceSize.width: 22
                            sourceSize.height: 22
                        }

                        Text {
                            text: GameInfoModel.missable_count
                            font.pixelSize: 10
                            color: header._c("missableIconColor", "basicTextColor", "#ffffff")
                        }
                    }
                }
            }

            Text {
                text: Math.round(header.progress * 100) + "%"
                font.bold: true
                font.pixelSize: header.dense ? 12 : 14
                color: header._c("toastPointsColor", "progressBarColor", "#6ee7a8")
            }
        }

        // Barra de progresso — vinha só do compact.qml
        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: header._c("progressBarBackgroundColor", "mainWindowDarkAccentColor", "#2a2a2a")

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, header.progress))
                color: header._c("progressBarColor", "basicTextColor", "#eab308")

                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.fillWidth: true
            text: GameInfoModel.point_count + " / " + GameInfoModel.point_total + qsTr(" pontos")
            font.pixelSize: 10
            color: header._c("timeStampColor", "disabledTextColor", "#7e7e7e")
        }

        // Rich presence — vinha só do noncompact.qml
        Text {
            Layout.fillWidth: true
            visible: header.showRichPresence && Ra2snes.richPresence !== ""
            text: Ra2snes.richPresence
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.italic: true
            font.pixelSize: 10
            color: header._c("timeStampColor", "disabledTextColor", "#7e7e7e")
        }
    }
}
```

- [ ] **Step 3: Registrar no qrc**

```xml
        <file>ui/components/UserHeader.qml</file>
        <file>ui/components/GameHeader.qml</file>
```

- [ ] **Step 4: Verificar que compila**

Run: `cmake --build build --target ra2snes -j`
Expected: compila sem erro.

- [ ] **Step 5: Commit**

```bash
git add ui/components/UserHeader.qml ui/components/GameHeader.qml ra2snes.qrc
git commit -m "feat: add user and game header components"
```

---

## Task 7: GameDashboard.qml

**Files:**
- Create: `ui/GameDashboard.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `LayoutMath` (Task 3), `ThemeResolver` (Task 4), `AchievementCard` (Task 5),
  `UserHeader` e `GameHeader` (Task 6).
- Produces: `GameDashboard` com `property var mainWindow` e `property bool dense`.
  Consumido pela Task 8.

- [ ] **Step 1: Implementar**

```qml
import QtQuick
import QtQuick.Layouts
import CustomModels 1.0
import "./LayoutMath.js" as LayoutMath
import "./components"

Item {
    id: dashboard

    property var mainWindow
    property bool dense: false

    // Largura NÃO escalada. Usar a largura escalada faria o grid refluir
    // durante o zoom Ctrl +/-, que aplica mainGroup.scale.
    readonly property real availableWidth: width
    readonly property int minCardWidth: dense ? 240 : 300
    readonly property int columns: LayoutMath.columnsFor(availableWidth - 24, minCardWidth)
    readonly property string headerMode: LayoutMath.headerMode(availableWidth)

    implicitHeight: column.implicitHeight

    ThemeResolver {
        id: resolver
        theme: themeLoader.item
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Cabeçalho: empilha abaixo de 520px, lado a lado acima.
        GridLayout {
            Layout.fillWidth: true
            columns: dashboard.headerMode === "stacked" ? 1 : 2
            columnSpacing: 10
            rowSpacing: 10

            UserHeader {
                Layout.fillWidth: dashboard.headerMode === "stacked"
                Layout.preferredWidth: dashboard.headerMode === "stacked"
                                       ? -1
                                       : Math.min(300, dashboard.availableWidth * 0.33)
                resolver: resolver
                dense: dashboard.dense
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }

            GameHeader {
                Layout.fillWidth: true
                resolver: resolver
                dense: dashboard.dense
                showRichPresence: true
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }

        Loader {
            Layout.fillWidth: true
            source: "./sorting.qml"
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.preferredHeight: Math.ceil(count / Math.max(1, dashboard.columns))
                                    * cellHeight
            interactive: false
            clip: false

            model: sortedAchievementModel

            cellWidth: LayoutMath.cellWidthFor(width, dashboard.minCardWidth)
            cellHeight: dashboard.dense ? 84 : 104

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                AchievementCard {
                    anchors.fill: parent
                    anchors.margins: 4

                    resolver: resolver
                    dense: dashboard.dense

                    badgeUrl: model.badgeUrl
                    lockedBadgeUrl: model.badgeLockedUrl
                    title: model.title
                    description: model.description
                    points: model.points
                    unlocked: model.unlocked
                    primed: model.primed
                    achievementType: model.type
                    value: model.value
                    target: model.target
                    percent: model.percent
                    timeUnlockedString: model.timeUnlockedString
                    achievementLink: model.achievementLink

                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }
            }
        }
    }
}
```

`interactive: false` e a altura calculada fazem o `GridView` crescer inteiro dentro do
`Flickable` que já existe no `mainwindow.qml`, em vez de rolar por dentro — que é como o
`ListView` atual se comporta.

- [ ] **Step 2: Registrar no qrc**

```xml
        <file>ui/GameDashboard.qml</file>
```

- [ ] **Step 3: Verificar que compila**

Run: `cmake --build build --target ra2snes -j`
Expected: compila sem erro.

- [ ] **Step 4: Commit**

```bash
git add ui/GameDashboard.qml ra2snes.qrc
git commit -m "feat: add responsive game dashboard layout"
```

---

## Task 8: Trocar o layout no mainwindow e remover os antigos

Esta é a task que muda o que o usuário vê. Até aqui nada estava ligado.

**Files:**
- Modify: `ui/mainwindow.qml`
- Delete: `ui/compact.qml`, `ui/noncompact.qml`, `ui/listview.qml`, `ui/progressbar.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `GameDashboard` (Task 7).
- Produces: `mainWindow.dense` (bool), lido pela Task 12.

- [ ] **Step 1: Remover a trava de 900px**

Em `ui/mainwindow.qml:281`, dentro de `Loader { id: mainLoader`:

```qml
// antes
                width: Math.min(mainWindow.width, 900)
// depois
                width: mainWindow.width
```

- [ ] **Step 2: Trocar `compact` por `dense`**

Substituir a propriedade na linha 79:

```qml
// antes
    property bool compact: UserInfoModel.compact
// depois
    property bool dense: UserInfoModel.compact
```

- [ ] **Step 3: Apontar o loader para o dashboard**

Em `Component.onCompleted` (linha ~492):

```qml
    Component.onCompleted: {
        mainLoader.setSource(
            "./GameDashboard.qml",
            { mainWindow: mainWindow, dense: mainWindow.dense }
        )
    }
```

Substituir o `onCompactChanged` inteiro por:

```qml
    onDenseChanged: {
        if (mainLoader.item)
            mainLoader.item.dense = mainWindow.dense;
        if (errorLoader.item)
            errorLoader.item.updateMessage();
    }
```

Trocar `dense` em vez de recarregar o loader evita recriar a tela inteira só para mudar
densidade.

- [ ] **Step 4: Corrigir as referências restantes a `compact`**

Buscar as que sobraram:

Run: `grep -n "mainWindow.compact\|compact:" ui/mainwindow.qml ui/popupmenu.qml`

Em `ui/mainwindow.qml`, nos âncoras do `errorLoader` (linhas ~309-310):

```qml
                anchors.leftMargin: mainWindow.dense ? 20 : 164
                anchors.topMargin: mainWindow.dense ? 100 : 128
```

Em `onClosing` (linha ~489), o terceiro argumento continua sendo o valor booleano — a
assinatura de `saveUISettings` não muda:

```qml
        Ra2snes.saveUISettings(windowWidth, windowHeight, dense, b, mainWindow.allowIcons, i, mainWindow.currentTheme);
```

Em `ui/popupmenu.qml`, qualquer binding que alternava layout passa a alternar densidade.
Trocar o rótulo do item de menu de "Compact" para "Densidade compacta" (ou equivalente em
inglês, seguindo o idioma dos outros itens do menu) e apontar para `mainWindow.dense`.

- [ ] **Step 5: Deletar os arquivos antigos**

```bash
git rm ui/compact.qml ui/noncompact.qml ui/listview.qml ui/progressbar.qml
```

E remover as quatro linhas correspondentes de `ra2snes.qrc`:

```xml
        <file>ui/noncompact.qml</file>
        <file>ui/compact.qml</file>
        <file>ui/progressbar.qml</file>
        <file>ui/listview.qml</file>
```

- [ ] **Step 6: Verificar que não sobrou referência**

Run: `grep -rn "compact.qml\|noncompact.qml\|listview.qml\|progressbar.qml" --include=*.qml --include=*.qrc --include=*.cpp .`
Expected: nenhuma saída.

- [ ] **Step 7: Compilar e rodar o app**

Run:
```bash
cmake --build build --target ra2snes -j && ./build/ra2snes
```

Verificação manual, com QUsb2Snes rodando e logado:
1. Maximizar a janela — o grid ganha 4+ colunas, sem faixa vazia à direita.
2. Arrastar a borda até ~380px — 1 coluna, nada cortado, sem scroll horizontal.
3. Barra de progresso **e** rich presence visíveis ao mesmo tempo.
4. `Ctrl +` e `Ctrl -` — a contagem de colunas não muda.
5. Console do Qt sem `TypeError` nem `Unable to assign`.
6. **Altura da célula:** procurar a conquista de título e descrição mais longos do set e
   confirmar que nada é cortado pelo `clip` do card. Se cortar, aumentar o `cellHeight`
   em `ui/GameDashboard.qml` (hoje 84 denso / 104 normal) até caber. Esse é o único número
   do layout que foi estimado e não derivado.

- [ ] **Step 8: Commit**

```bash
git add ui ra2snes.qrc
git commit -m "feat: replace dual layouts with responsive dashboard"
```

---

## Task 9: AchievementToast.qml

**Files:**
- Create: `ui/components/AchievementToast.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `ThemeResolver` (Task 4).
- Produces: `AchievementToast` com `property url badgeUrl`, `property string title`,
  `property int points`, `property string variant` (`"achievement" | "beaten" | "mastered"`),
  `property var resolver`, `function start()`, e `signal finished()`. Consumido pela Task 10.

- [ ] **Step 1: Implementar**

Os tempos abaixo vêm da spec e foram validados em protótipo animado. Não ajustar sem
revalidar.

```qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: toast

    property url badgeUrl
    property string title: ""
    property int points: 0
    property string variant: "achievement"
    property var resolver: null

    // O ToastStack ancora este item no canto. Âncoras sobrescrevem `y`, então
    // animar `y` diretamente não teria efeito — o deslocamento vai num
    // Translate, que convive com as âncoras.
    property real slideOffset: 30
    property real glowStrength: 0

    signal finished()

    readonly property bool isGameAward: variant === "beaten" || variant === "mastered"
    readonly property int badgeSize: isGameAward ? 52 : 40
    readonly property int holdMs: isGameAward ? 6000 : 3900

    readonly property string label: {
        if (variant === "mastered")
            return qsTr("JOGO MASTERIZADO");
        if (variant === "beaten")
            return qsTr("JOGO ZERADO");
        return qsTr("CONQUISTA DESBLOQUEADA");
    }

    function _c(name, fallbackName, hard) {
        return resolver ? resolver.color(name, fallbackName, hard) : hard;
    }

    implicitWidth: layout.implicitWidth + 24
    implicitHeight: layout.implicitHeight + 18
    radius: 12
    opacity: 0
    transformOrigin: Item.Center

    transform: Translate { y: toast.slideOffset }

    color: _c("toastBackgroundColor", "popupBackgroundColor", "#16201c")
    border.width: isGameAward ? 2 : 1
    border.color: {
        if (variant === "mastered")
            return _c("masteredToastBorderColor", "statusMasteredIconBackgroundColor", "#ffd700");
        if (variant === "beaten")
            return _c("beatenToastBorderColor", "statusBeatenIconBackgroundColor", "#d4d4d4");
        return _c("toastBorderColor", "progressBarColor", "#6ee7a8");
    }

    layer.enabled: true
    layer.effect: DropShadow {
        radius: 18
        samples: 25
        verticalOffset: 8
        color: toast._c("shadowColor", "mainWindowDarkAccentColor", "#000000")
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        // O wrapper existe para que escala e rotação apliquem ao badge E ao
        // brilho juntos. Aplicar no Image direto deixaria o glow parado.
        Item {
            id: badgeWrap
            Layout.preferredWidth: toast.badgeSize
            Layout.preferredHeight: toast.badgeSize
            transformOrigin: Item.Center

            Image {
                id: badge
                anchors.fill: parent
                source: toast.badgeUrl
                sourceSize.width: toast.badgeSize * 2
                sourceSize.height: toast.badgeSize * 2
                asynchronous: true
                cache: true
                smooth: true
            }

            Glow {
                anchors.fill: badge
                source: badge
                radius: 12
                samples: 17
                color: toast.border.color
                opacity: toast.glowStrength
                visible: opacity > 0
            }
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: toast.label
                font.bold: true
                font.pixelSize: toast.isGameAward ? 10 : 9
                font.letterSpacing: 1.2
                color: toast.isGameAward
                       ? toast.border.color
                       : toast._c("toastLabelColor", "nonErrorMessageTextColor", "#6ee7a8")
            }

            Text {
                text: toast.title
                font.bold: true
                font.pixelSize: toast.isGameAward ? 16 : 13
                color: toast._c("toastTitleColor", "basicTextColor", "#ffffff")
            }
        }

        Text {
            visible: toast.points > 0
            Layout.leftMargin: 6
            text: "+" + toast.points
            font.bold: true
            font.pixelSize: 18
            color: toast._c("toastPointsColor", "progressBarColor", "#6ee7a8")
        }
    }

    function start() {
        sequence.restart();
        badgePop.restart();
    }

    SequentialAnimation {
        id: sequence

        ParallelAnimation {
            NumberAnimation {
                target: toast; property: "slideOffset"
                from: 30; to: 0
                duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4
            }
            NumberAnimation {
                target: toast; property: "opacity"
                from: 0; to: 1; duration: 420
            }
            NumberAnimation {
                target: toast; property: "scale"
                from: 0.94; to: 1.0
                duration: 420; easing.type: Easing.OutBack
            }
        }

        PauseAnimation { duration: toast.holdMs }

        ParallelAnimation {
            NumberAnimation {
                target: toast; property: "slideOffset"
                to: 22; duration: 280; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: toast; property: "opacity"
                to: 0; duration: 280; easing.type: Easing.InQuad
            }
        }

        onFinished: toast.finished()
    }

    // O pop do badge começa em 340ms, enquanto a caixa ainda assenta.
    SequentialAnimation {
        id: badgePop

        PauseAnimation { duration: 340 }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: badgeWrap; property: "scale"
                    from: 1.0; to: 1.34
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: badgeWrap; property: "scale"
                    to: 1.0; duration: 325; easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: badgeWrap; property: "rotation"
                    from: 0; to: -7
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: badgeWrap; property: "rotation"
                    to: 0; duration: 325; easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: toast; property: "glowStrength"
                    from: 0.0; to: 1.0
                    duration: 175; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: toast; property: "glowStrength"
                    to: 0.0; duration: 325; easing.type: Easing.OutQuad
                }
            }
        }
    }
}
```

- [ ] **Step 2: Registrar no qrc**

```xml
        <file>ui/components/AchievementToast.qml</file>
```

- [ ] **Step 3: Verificar que compila**

Run: `cmake --build build --target ra2snes -j`
Expected: compila sem erro.

- [ ] **Step 4: Commit**

```bash
git add ui/components/AchievementToast.qml ra2snes.qrc
git commit -m "feat: add achievement toast component"
```

---

## Task 10: ToastStack.qml e a fila

**Files:**
- Create: `ui/components/ToastStack.qml`
- Create: `tests/qml/tst_toaststack.qml`
- Modify: `ra2snes.qrc`

**Interfaces:**
- Consumes: `AchievementToast` (Task 9).
- Produces: `ToastStack` com `function push(data)`, `property int gapMs` (default 400),
  `readonly property int pending`, `readonly property bool busy`, e `signal shown(var data)`.
  `data` é um objeto com `badgeUrl`, `title`, `points`, `variant`. Consumido pela Task 11.

- [ ] **Step 1: Escrever o teste que falha**

`tests/qml/tst_toaststack.qml`:

```qml
import QtQuick
import QtTest
import "../../ui/components"

TestCase {
    name: "ToastStack"
    when: windowShown
    width: 400
    height: 300

    ToastStack {
        id: stack
        anchors.fill: parent
        gapMs: 20
    }

    SignalSpy {
        id: shownSpy
        target: stack
        signalName: "shown"
    }

    function init() {
        stack.reset();
        shownSpy.clear();
    }

    function makeData(title) {
        return { badgeUrl: "", title: title, points: 7, variant: "achievement" };
    }

    function test_first_push_shows_immediately() {
        stack.push(makeData("KONGQuest"));
        compare(shownSpy.count, 1);
        compare(shownSpy.signalArguments[0][0].title, "KONGQuest");
    }

    function test_second_push_waits_for_first() {
        stack.push(makeData("A"));
        stack.push(makeData("B"));

        // O segundo não pode aparecer enquanto o primeiro está na tela.
        compare(shownSpy.count, 1);
        compare(stack.pending, 1);
        verify(stack.busy);
    }

    function test_queue_drains_in_order() {
        stack.push(makeData("A"));
        stack.push(makeData("B"));
        stack.push(makeData("C"));

        tryCompare(shownSpy, "count", 3, 30000);

        compare(shownSpy.signalArguments[0][0].title, "A");
        compare(shownSpy.signalArguments[1][0].title, "B");
        compare(shownSpy.signalArguments[2][0].title, "C");
        compare(stack.pending, 0);
    }

    function test_idle_after_drain() {
        stack.push(makeData("A"));
        tryCompare(stack, "busy", false, 30000);
        compare(stack.pending, 0);
    }
}
```

`tryCompare` com timeout de 30s porque cada toast leva ~4,6s do início ao `finished()`, e
três em sequência passam de 14s.

- [ ] **Step 2: Rodar para ver falhar**

Run: `cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: FAIL — `ToastStack is not a type`.

- [ ] **Step 3: Implementar**

```qml
import QtQuick

Item {
    id: stack

    // Intervalo entre o fim de um toast e o começo do próximo.
    property int gapMs: 400
    property var resolver: null

    // _queue é um array JS puro: mutá-lo não dispara notificação de binding.
    // Por isso `pending` é atualizado à mão em todo ponto que mexe na fila,
    // em vez de ser um readonly ligado a _queue.length.
    property var _queue: []
    property Item _current: null

    property int pending: 0
    readonly property bool busy: _current !== null || gapTimer.running

    signal shown(var data)

    function push(data) {
        _queue.push(data);
        pending = _queue.length;

        if (!busy)
            _showNext();
    }

    function reset() {
        gapTimer.stop();

        if (_current) {
            _current.destroy();
            _current = null;
        }

        _queue = [];
        pending = 0;
    }

    function _showNext() {
        if (_queue.length === 0)
            return;

        var data = _queue.shift();
        pending = _queue.length;

        var toast = toastComponent.createObject(stack, {
            badgeUrl: data.badgeUrl,
            title: data.title,
            points: data.points,
            variant: data.variant,
            resolver: stack.resolver
        });

        if (!toast)
            return;

        _current = toast;
        toast.finished.connect(_onToastFinished);
        toast.start();

        stack.shown(data);
    }

    function _onToastFinished() {
        if (_current) {
            _current.destroy();
            _current = null;
        }

        if (_queue.length > 0)
            gapTimer.restart();
    }

    Timer {
        id: gapTimer
        interval: stack.gapMs
        repeat: false
        onTriggered: stack._showNext()
    }

    Component {
        id: toastComponent

        // As âncoras ficam aqui, não em createObject: o parent passado ao
        // createObject é o stack, então parent.right/bottom resolvem sozinhos.
        AchievementToast {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }
}
```

- [ ] **Step 4: Registrar no qrc**

```xml
        <file>ui/components/ToastStack.qml</file>
```

- [ ] **Step 5: Rodar para ver passar**

Run: `cmake --build build --target tst_qml -j && ctest --test-dir build -R qml --output-on-failure`
Expected: PASS nos quatro testes de `ToastStack`. A suíte leva ~20s por causa do
`test_queue_drains_in_order`.

- [ ] **Step 6: Commit**

```bash
git add ui/components/ToastStack.qml tests/qml/tst_toaststack.qml ra2snes.qrc
git commit -m "feat: add sequential toast queue"
```

---

## Task 11: Ligar os toasts nas duas janelas

**Files:**
- Modify: `ui/mainwindow.qml`
- Modify: `ui/banner.qml`

**Interfaces:**
- Consumes: `ToastStack` (Task 10), `AchievementModel::achievementUnlocked` (Task 2),
  `GameInfoModel::beatenGame()` e `masteredGame()` (já existentes).
- Produces: comportamento final.

- [ ] **Step 1: Adicionar o stack ao HUD do mainwindow**

Em `ui/mainwindow.qml`, dentro de `Item { id: hud }`, **antes** do `Row { id: challenges }`,
adicionar:

```qml
        ToastStack {
            id: toastStack
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            // Acima dos ícones de challenge: eles indicam a conquista prestes a
            // completar, e cobri-los justo agora seria o pior momento possível.
            anchors.bottomMargin: challenges.height + 20
            width: 320
            height: 80
            z: 101
            resolver: hudResolver
        }

        ThemeResolver {
            id: hudResolver
            theme: themeLoader.item
        }
```

E adicionar o import no topo do arquivo:

```qml
import "./components"
```

- [ ] **Step 2: Conectar os três sinais**

Em `ui/mainwindow.qml`, junto dos outros blocos `Connections` (perto da linha 436):

```qml
    Connections {
        target: AchievementModel
        function onAchievementUnlocked(achievement) {
            if (!mainWindow.setupFinished)
                return;

            toastStack.push({
                badgeUrl: achievement.badgeUrl,
                title: achievement.title,
                points: achievement.points,
                variant: "achievement"
            });
        }
    }

    Connections {
        target: GameInfoModel
        function onBeatenGame() {
            if (!mainWindow.setupFinished)
                return;

            toastStack.push({
                badgeUrl: GameInfoModel.image_icon_url,
                title: GameInfoModel.title,
                points: 0,
                variant: "beaten"
            });
        }
    }

    Connections {
        target: GameInfoModel
        function onMasteredGame() {
            if (!mainWindow.setupFinished)
                return;

            toastStack.push({
                badgeUrl: GameInfoModel.image_icon_url,
                title: GameInfoModel.title,
                points: 0,
                variant: "mastered"
            });
        }
    }
```

O guard `setupFinished` espelha o que o som já faz em `playRandomSound`.

- [ ] **Step 3: Adicionar o stack ao banner**

Em `ui/banner.qml`, dentro do `ApplicationWindow`, depois do conteúdo existente:

```qml
    ThemeResolver {
        id: bannerResolver
        theme: themeLoader.item
    }

    ToastStack {
        id: bannerToastStack
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        width: Math.min(300, banner.width - 16)
        height: 70
        z: 200
        resolver: bannerResolver
    }

    Connections {
        target: AchievementModel
        function onAchievementUnlocked(achievement) {
            bannerToastStack.push({
                badgeUrl: achievement.badgeUrl,
                title: achievement.title,
                points: achievement.points,
                variant: "achievement"
            });
        }
    }

    Connections {
        target: GameInfoModel
        function onBeatenGame() {
            bannerToastStack.push({
                badgeUrl: GameInfoModel.image_icon_url,
                title: GameInfoModel.title,
                points: 0,
                variant: "beaten"
            });
        }
    }

    Connections {
        target: GameInfoModel
        function onMasteredGame() {
            bannerToastStack.push({
                badgeUrl: GameInfoModel.image_icon_url,
                title: GameInfoModel.title,
                points: 0,
                variant: "mastered"
            });
        }
    }
```

E o import `import "./components"` no topo.

Se `banner.qml` não tiver um `themeLoader` próprio, conferir antes com
`grep -n "themeLoader" ui/banner.qml` e usar a fonte de tema que ele já tem.

- [ ] **Step 4: Compilar**

Run: `cmake --build build --target ra2snes -j`
Expected: compila sem erro.

- [ ] **Step 5: Verificação manual**

Com QUsb2Snes rodando, logado, e a janela banner aberta:

1. **Login num jogo já masterizado** — nenhum toast dispara. Este é o teste mais importante:
   se disparar, a separação `setUnlockedState`/`unlockAchievement` foi quebrada.
2. **Desbloqueio ao vivo** — um toast sobe no canto inferior direito com o badge e o título
   certos, o badge dá o pop com brilho, e some depois de ~4,3s.
3. **O toast não cobre os ícones de challenge.**
4. **Três desbloqueios juntos** — três toasts em sequência, nunca sobrepostos, com o som
   de cada um acompanhando.
5. **O toast aparece também na janela banner.**
6. **Masterizar o jogo** — toast dourado, maior, com 6s de permanência.
7. Console do Qt sem `TypeError`.

- [ ] **Step 6: Commit**

```bash
git add ui/mainwindow.qml ui/banner.qml
git commit -m "feat: show achievement toasts in main and banner windows"
```

---

## Task 12: `compact` vira densidade

**Files:**
- Modify: `ra2snes.cpp:617-660` (`saveUISettings` e a leitura correspondente)
- Modify: `README.md`

**Interfaces:**
- Consumes: `mainWindow.dense` (Task 8).
- Produces: nada — task final.

- [ ] **Step 1: Confirmar que a assinatura não precisa mudar**

Run: `grep -n "saveUISettings\|compact" ra2snes.cpp ra2snes.h userinfomodel.cpp`

A chave `compact` continua sendo um `bool` gravado e lido no mesmo lugar do `settings.ini`.
O C++ **não muda de comportamento** — só o significado no QML mudou, na Task 8. Se a busca
confirmar isso, este passo não gera diff em `ra2snes.cpp`.

- [ ] **Step 2: Verificar compatibilidade com settings.ini antigo**

Run:
```bash
cp build/settings.ini /tmp/settings-backup.ini 2>/dev/null || true
printf '[UI]\ncompact=true\n' > build/settings.ini
./build/ra2snes
```
Expected: o app abre com cards densos, sem erro de parsing e sem resetar as outras chaves.

Restaurar depois: `cp /tmp/settings-backup.ini build/settings.ini 2>/dev/null || true`

- [ ] **Step 3: Atualizar o README**

Em `README.md`, na seção de configuração, adicionar após o parágrafo sobre `settings.ini`:

```markdown
### Densidade e layout

A janela se adapta à largura: arrastar a borda muda quantas colunas de conquistas cabem na
tela. A opção `compact` do menu controla a densidade dos cards, não mais o layout — em
versões anteriores ela alternava entre duas telas diferentes.
```

- [ ] **Step 4: Rodar a suíte inteira**

Run: `ctest --test-dir build --output-on-failure`
Expected: PASS em todos os alvos — `achievementmodel` e `qml`.

- [ ] **Step 5: Verificar o tema de terceiro**

`ui/themes/Test.qml` ficou sem os tokens novos de propósito.

Run:
```bash
mkdir -p build/themes && cp ui/themes/Test.qml build/themes/
./build/ra2snes
```
Trocar para o tema "Test" pelo menu. Expected: a tela carrega com cores coerentes vindas
dos fallbacks, e **nenhum `TypeError` no console**. Este é o critério de sucesso 11.

- [ ] **Step 6: Commit**

```bash
git add README.md ra2snes.cpp
git commit -m "docs: describe responsive layout and density setting"
```

---

## Checklist final contra a spec

Rodar antes de abrir PR. Cada item mapeia um critério de sucesso da spec.

- [ ] 1. Compila com Qt 6.9 sem warnings novos
- [ ] 2. 1400px → 4+ colunas, sem faixa vazia
- [ ] 3. 380px → 1 coluna, sem scroll horizontal
- [ ] 4. Barra de progresso **e** rich presence juntas
- [ ] 5. `Ctrl +/-` não muda a contagem de colunas
- [ ] 6. Login em jogo masterizado → nenhum toast
- [ ] 7. Desbloqueio ao vivo → um toast correto
- [ ] 8. Três simultâneos → três em sequência
- [ ] 9. Toast aparece na janela banner
- [ ] 10. `masteredGame()` → toast dourado maior
- [ ] 11. `Test.qml` (sem tokens novos) carrega sem `TypeError`
- [ ] 12. `settings.ini` de versão anterior carrega sem erro
