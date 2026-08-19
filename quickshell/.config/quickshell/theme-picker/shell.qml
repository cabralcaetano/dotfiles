import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool pickerVisible: false
    property var themes: []
    property var visibleThemes: []
    property int selectedVisibleIndex: 0
    property string filterText: ""
    property string statusText: ""
    property var chromeTheme: ({
        background: "#0f0f10",
        surface: "#18181b",
        surfaceHover: "#252529",
        foreground: "#f0f0f0",
        accent: "#8a8a8d",
        error: "#9c5b5f"
    })


    readonly property int cardWidth: 210
    readonly property int cardSpacing: 12

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: home + "/.local/state/theme-picker"

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function fallbackColor(value, fallback) {
        return value && String(value).length > 0 ? value : fallback;
    }
    function colorWithAlpha(value, alpha) {
        const raw = String(value || "#000000").replace("#", "");
        if (raw.length < 6) return Qt.rgba(0, 0, 0, alpha);

        const r = parseInt(raw.slice(0, 2), 16) / 255;
        const g = parseInt(raw.slice(2, 4), 16) / 255;
        const b = parseInt(raw.slice(4, 6), 16) / 255;
        return Qt.rgba(r, g, b, alpha);
    }


    function titleFor(name) {
        return String(name || "").replace(/[-_]+/g, " ").replace(/\b\w/g, function(match) { return match.toUpperCase(); });
    }

    function parseThemes(raw) {
        const rows = String(raw || "").trim().split("\n").filter(Boolean);
        const parsed = [];

        for (let i = 0; i < rows.length; i++) {
            const c = rows[i].split("\t");
            if (c.length < 8 || !c[0]) continue;

            parsed.push({
                name: c[0],
                dir: c[1],
                background: fallbackColor(c[2], "#1d1d20"),
                surface: fallbackColor(c[3], "#2a2a2e"),
                surfaceHover: fallbackColor(c[4], "#323236"),
                foreground: fallbackColor(c[5], "#ffffff"),
                accent: fallbackColor(c[6], "#a0a0a0"),
                error: fallbackColor(c[7], "#ff6464"),
                palette: [
                    fallbackColor(c[8], c[6] || "#a0a0a0"),
                    fallbackColor(c[9], c[6] || "#a0a0a0"),
                    fallbackColor(c[10], c[6] || "#a0a0a0"),
                    fallbackColor(c[11], c[6] || "#a0a0a0"),
                    fallbackColor(c[12], c[6] || "#a0a0a0"),
                    fallbackColor(c[13], c[6] || "#a0a0a0")
                ],
                preview: c[14] || "",
                current: c[15] === "1"
            });
        }

        themes = parsed;
        updateVisibleThemes();

        let currentIndex = visibleThemes.findIndex(theme => theme.current);
        selectedVisibleIndex = currentIndex >= 0 ? currentIndex : 0;
        chromeTheme = visibleThemes[selectedVisibleIndex] || chromeTheme;
        statusText = parsed.length === 0 ? "Nenhum tema encontrado em ~/Projects/dotfiles/themes" : "";
        focusFilter();
        syncCarousel();
    }

    function updateVisibleThemes() {
        const needle = filterText.toLowerCase();
        visibleThemes = themes.filter(theme => !needle || theme.name.toLowerCase().indexOf(needle) >= 0 || titleFor(theme.name).toLowerCase().indexOf(needle) >= 0);
        if (selectedVisibleIndex >= visibleThemes.length) selectedVisibleIndex = Math.max(0, visibleThemes.length - 1);
        syncCarousel();
    }

    function selectedTheme() {
        if (visibleThemes.length === 0) return null;
        return visibleThemes[Math.max(0, Math.min(selectedVisibleIndex, visibleThemes.length - 1))];
    }

    function selectDelta(delta) {
        if (visibleThemes.length === 0) return;
        selectedVisibleIndex = (selectedVisibleIndex + delta + visibleThemes.length) % visibleThemes.length;
        syncCarousel();
    }

    function syncCarousel() {
        Qt.callLater(function() {
            if (!pickerVisible || visibleThemes.length === 0) return;

            const step = cardWidth + cardSpacing;
            const itemX = selectedVisibleIndex * step;
            const maxX = Math.max(0, carousel.contentWidth - carousel.width);
            const centeredX = itemX - Math.max(0, (carousel.width - cardWidth) / 2);
            carousel.contentX = Math.max(0, Math.min(maxX, centeredX));
        });
    }

    function openPicker() {
        pickerVisible = true;
        filterText = "";
        statusText = "";
        loadProc.exec(loadProc.command);
        focusFilter();
    }

    function closePicker() {
        pickerVisible = false;
        filterText = "";
        updateVisibleThemes();
    }

    function focusFilter() {
        Qt.callLater(function() {
            if (pickerVisible) filterInput.forceActiveFocus();
        });
    }

    function applySelected() {
        const theme = selectedTheme();
        if (!theme) return;

        pickerVisible = false;
        statusText = "Aplicando " + titleFor(theme.name) + "…";
        const quoted = shellQuote(theme.name);
        applyProc.command = ["bash", "-lc", "~/.local/bin/theme-set.sh " + quoted + " && mkdir -p ~/.local/state/theme-picker && printf '%s\\n' " + quoted + " > ~/.local/state/theme-picker/current-theme"];
        applyProc.exec(applyProc.command);
    }

    Process {
        id: loadProc
        command: [root.home + "/.local/bin/theme-picker-list.sh"]
        stdout: StdioCollector { onStreamFinished: root.parseThemes(text) }
    }

    Process {
        id: applyProc
        stdout: StdioCollector { onStreamFinished: if (String(text).trim().length > 0) root.statusText = String(text).trim() }
    }

    IpcHandler {
        target: "themePicker"

        function open(): void {
            root.openPicker();
        }

        function close(): void {
            root.closePicker();
        }

        function toggle(): void {
            if (root.pickerVisible) root.closePicker();
            else root.openPicker();
        }
    }

    PanelWindow {
        id: window
        visible: root.pickerVisible
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: root.colorWithAlpha(root.chromeTheme.background, 0.28)

            MouseArea {
                anchors.fill: parent
                onClicked: root.closePicker()
            }

            Rectangle {
                id: panel
                width: Math.min(parent.width - 320, 720)
                height: Math.min(parent.height - 260, 430)
                anchors.centerIn: parent
                radius:  0
                color: root.colorWithAlpha(root.chromeTheme.background,  0.72)
                border.color: root.colorWithAlpha(root.chromeTheme.accent, 0.55)
                border.width: 1

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 10

                        Text {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.chromeTheme.foreground
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            font.bold: true
                            text: "󰔎 temas"
                        }

                        Rectangle {
                            width: parent.width - 190
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter
                            radius:  0
                            color: root.colorWithAlpha(root.chromeTheme.surfaceHover,  0.56)
                            border.color: filterInput.activeFocus ? root.colorWithAlpha(root.chromeTheme.foreground, 0.55) : root.colorWithAlpha(root.chromeTheme.accent, 0.35)
                            border.width: 1

                            TextInput {
                                id: filterInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.chromeTheme.foreground
                                selectionColor: root.colorWithAlpha(root.chromeTheme.accent, 0.45)
                                selectedTextColor: root.chromeTheme.foreground
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                text: root.filterText
                                clip: true

                                onTextChanged: {
                                    root.filterText = text;
                                    root.updateVisibleThemes();
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.closePicker();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.applySelected();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                        root.selectDelta(1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                        root.selectDelta(-1);
                                        event.accepted = true;
                                    }
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: filterInput.text.length === 0
                                color: root.colorWithAlpha(root.chromeTheme.foreground, 0.45)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                text: "filtrar tema…"
                            }
                        }
                    }

                    Flickable {
                        id: carousel
                        width: parent.width
                        height: parent.height - 84
                        contentWidth: cards.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: cards
                            height: parent.height
                            spacing: root.cardSpacing

                            Repeater {
                                model: root.visibleThemes

                                Rectangle {
                                    required property var modelData
                                    required property int index

                                    property bool selected: index === root.selectedVisibleIndex
                                    property var theme: modelData

                                    width: root.cardWidth
                                    height: carousel.height - 6
                                    radius:  0
                                    color: root.colorWithAlpha(selected ? theme.surfaceHover : theme.surface,  0.56)
                                    border.color: selected ? root.chromeTheme.foreground : root.colorWithAlpha(root.chromeTheme.accent, 0.24)
                                    border.width: selected ? 2 : 1
                                    scale: 1.0

                                    Behavior on scale { NumberAnimation { duration: 120 } }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.selectedVisibleIndex = index; root.syncCarousel(); }
                                        onDoubleClicked: root.applySelected()
                                    }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        Rectangle {
                                            width: parent.width
                                            height: 132
                                            radius:  0
                                            clip: true
                                            color: theme.background
                                            border.color: "#22000000"
                                            border.width: 1

                                            Image {
                                                anchors.fill: parent
                                                source: theme.preview.length > 0 ? "file://" + theme.preview : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: theme.preview.length > 0
                                            }

                                            Item {
                                                anchors.fill: parent
                                                visible: theme.preview.length === 0

                                                Rectangle {
                                                    width: parent.width * 0.72
                                                    height: 58
                                                    x: 14
                                                    y: 14
                                                    radius:  0
                                                    color: theme.surface
                                                    border.color: theme.accent
                                                    border.width: 1

                                                    Column {
                                                        anchors.fill: parent
                                                        anchors.margins: 10
                                                        spacing: 7
                                                        Repeater {
                                                            model: [theme.accent, theme.foreground, theme.palette[3], theme.palette[1]]
                                                            Rectangle {
                                                                width: 105 + index * 12
                                                                height: 5
                                                                radius:  0
                                                                color: modelData
                                                                opacity: index === 1 ? 0.55 : 0.9
                                                            }
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width * 0.58
                                                    height: 54
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 14
                                                    anchors.bottom: parent.bottom
                                                    anchors.bottomMargin: 14
                                                    radius:  0
                                                    color: theme.surfaceHover
                                                    border.color: theme.palette[4]
                                                    border.width: 1

                                                    Grid {
                                                        anchors.centerIn: parent
                                                        columns: 3
                                                        spacing: 8
                                                        Repeater {
                                                            model: theme.palette
                                                            Rectangle {
                                                                width: 17
                                                                height: 17
                                                                radius:  0
                                                                color: modelData
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            color: theme.foreground
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 15
                                            font.bold: true
                                            elide: Text.ElideRight
                                            text: root.titleFor(theme.name)
                                        }

                                        Text {
                                            width: parent.width
                                            color: theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            text: theme.current ? "tema atual" : "Enter · duplo clique"
                                        }

                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: [theme.background, theme.surface, theme.foreground, theme.accent, theme.error]
                                                Rectangle {
                                                    width: 26
                                                    height: 16
                                                    radius:  0
                                                    color: modelData
                                                    border.color: root.colorWithAlpha(root.chromeTheme.background, 0.35)
                                                    border.width: 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 20

                        Text {
                            width: parent.width * 0.65
                            color: root.chromeTheme.foreground
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            text: root.visibleThemes.length === 0 ? "sem resultados" : "←/→ navega · digite filtra · Enter aplica · Esc fecha"
                        }

                        Text {
                            width: parent.width * 0.35
                            horizontalAlignment: Text.AlignRight
                            color: root.chromeTheme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            text: root.statusText
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.closePicker()
        }
    }
}
