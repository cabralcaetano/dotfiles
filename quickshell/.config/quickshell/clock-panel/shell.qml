import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool panelVisible: false
    property date now: new Date()
    property string mediaState: "Stopped"
    property string mediaTitle: "Nada tocando agora"
    property string mediaArtist: ""
    property string mediaAlbum: ""
    property string mediaArtUrl: ""
    property string weatherText: "Carregando tempo…"
    property string statusText: "Carregando status…"

    function refreshAll(): void {
        now = new Date();
        mediaProc.exec(mediaProc.command);
        weatherProc.exec(weatherProc.command);
        statusProc.exec(statusProc.command);
    }

    function updateMedia(raw) {
        const text = raw.trim();
        if (!text || text.indexOf("No players") >= 0 || text.indexOf("No player") >= 0) {
            mediaState = "Stopped";
            mediaTitle = "Nada tocando agora";
            mediaArtist = "";
            mediaAlbum = "";
            mediaArtUrl = "";
            return;
        }

        const parts = text.split("|");
        mediaState = parts[0] || "Mídia";
        mediaTitle = parts[1] || "Sem título";
        mediaArtist = parts[2] || "Artista desconhecido";
        mediaAlbum = parts[3] || "";
        mediaArtUrl = parts[4] || "";
    }

    function mediaStateIcon() {
        return mediaState === "Playing" ? "󰐊" : mediaState === "Paused" ? "󰏤" : "󰓛";
    }

    function weatherLabel(raw) {
        const text = raw.trim();
        if (!text) return "󰖐 Tempo indisponível";

        const parts = text.split("|");
        if (parts.length < 5) return text;
        const temp = parts[0].replace("°C", "°");
        const wind = parts[3].replace(/^↓/, "");
        return `󰖐 ${parts[4]}\n ${temp} · 󰖎 ${parts[2]} · 󰖝 ${wind}`;
    }

    function statusLabel(raw) {
        const text = raw.trim();
        return text || "Status indisponível";
    }

    function titleDate() {
        return Qt.formatDate(now, "dddd, dd 'de' MMMM");
    }

    function monthTitle() {
        return "󰃭 " + Qt.formatDate(now, "MMMM yyyy");
    }

    function calendarCells() {
        const year = now.getFullYear();
        const month = now.getMonth();
        const today = now.getDate();
        const first = new Date(year, month, 1);
        const days = new Date(year, month + 1, 0).getDate();
        const offset = (first.getDay() + 6) % 7;
        const cells = ["seg", "ter", "qua", "qui", "sex", "sáb", "dom"].map(day => ({
            text: day,
            header: true,
            today: false
        }));

        for (let i = 0; i < offset; i++) {
            cells.push({ text: "", header: false, today: false });
        }

        for (let day = 1; day <= days; day++) {
            cells.push({
                text: String(day),
                header: false,
                today: day === today
            });
        }

        return cells;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    Process {
        id: mediaProc
        command: ["bash", "-lc", "playerctl metadata --format '{{status}}|{{xesam:title}}|{{xesam:artist}}|{{xesam:album}}|{{mpris:artUrl}}' 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: root.updateMedia(text) }
    }

    Process {
        id: weatherProc
        command: ["bash", "-lc", "$HOME/.local/bin/clock-panel-weather.sh"]
        stdout: StdioCollector { onStreamFinished: root.weatherText = root.weatherLabel(text) }
    }

    Process {
        id: statusProc
        command: ["bash", "-lc", "$HOME/.local/bin/clock-panel-status.sh"]
        stdout: StdioCollector { onStreamFinished: root.statusText = root.statusLabel(text) }
    }

    IpcHandler {
        target: "clockPanel"

        function toggle(): void {
            root.panelVisible = !root.panelVisible;
            if (root.panelVisible) root.refreshAll();
        }

        function show(): void {
            root.panelVisible = true;
            root.refreshAll();
        }

        function hide(): void {
            root.panelVisible = false;
        }

        function refresh(): void {
            root.refreshAll();
        }
    }

    PanelWindow {
        id: backdrop
        visible: root.panelVisible
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
            id: overlay
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: root.panelVisible = false
            }

            Rectangle {
                id: panel
                width: 520
                height: 430
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 0
                radius: 12
                color: "#e61d1d20"
                border.color: "#33a0a0a0"
                border.width: 1

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        width: parent.width
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.bold: true
                        text: "󰥔 " + Qt.formatTime(root.now, "HH:mm:ss") + "  ·  󰃭 " + root.titleDate()
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Column {
                            width: 252
                            spacing: 10

                            MediaBox {
                                width: parent.width
                                stateIcon: root.mediaStateIcon()
                                stateText: root.mediaState
                                titleText: root.mediaTitle
                                artistText: root.mediaArtist
                                albumText: root.mediaAlbum
                                artUrl: root.mediaArtUrl
                            }

                            CalendarBox {
                                width: parent.width
                                title: root.monthTitle()
                                cells: root.calendarCells()
                            }
                        }

                        CombinedStatusBox {
                            width: 230
                            weatherText: root.weatherText
                            systemText: root.statusText
                        }
                    }


                }
            }
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.panelVisible = false
        }
    }

    component MediaBox: Rectangle {
        required property string stateIcon
        required property string stateText
        required property string titleText
        required property string artistText
        required property string albumText
        required property string artUrl

        height: 180
        radius: 10
        color: "#cc2a2a2e"
        border.color: "#26a0a0a0"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                width: parent.width
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                text: "󰎈 tocando agora"
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    width: 72
                    height: 72
                    radius: 8
                    clip: true
                    color: "#991d1d20"
                    border.color: "#26a0a0a0"
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        source: artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: artUrl.length > 0
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: artUrl.length === 0
                        color: "#a0a0a0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 28
                        text: "󰝚"
                    }
                }

                Column {
                    width: parent.width - 82
                    spacing: 4

                    Text {
                        width: parent.width
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        text: `${stateIcon} ${titleText}`
                    }

                    Text {
                        width: parent.width
                        color: "#deddda"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        text: artistText ? `󰠃 ${artistText}` : "󰠃 —"
                    }

                    Text {
                        width: parent.width
                        color: "#a0a0a0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        text: albumText ? `󰀥 ${albumText}` : stateText
                    }
                }
            }

            Row {
                spacing: 8

                ControlButton { minWidth: 58; label: "󰒮"; command: ["playerctl", "previous"] }
                ControlButton {
                    minWidth: 96
                    label: stateText === "Playing" ? "󰏤 pause" : "󰐊 play"
                    command: ["playerctl", "play-pause"]
                }
                ControlButton { minWidth: 58; label: "󰒭"; command: ["playerctl", "next"] }
            }
        }
    }

    component CalendarBox: Rectangle {
        required property string title
        required property var cells

        height: 180
        radius: 10
        color: "#cc2a2a2e"
        border.color: "#26a0a0a0"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                width: parent.width
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                text: title
                elide: Text.ElideRight
            }

            Grid {
                id: calendarGrid
                width: parent.width
                columns: 7
                columnSpacing: 3
                rowSpacing: 5

                Repeater {
                    model: cells

                    Text {
                        required property var modelData

                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        color: modelData.header ? "#deddda" : "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: modelData.header || modelData.today
                        text: modelData.text
                    }
                }
            }
        }
    }

    component CombinedStatusBox: Rectangle {
        required property string weatherText
        required property string systemText

        height: 370
        radius: 10
        color: "#cc2a2a2e"
        border.color: "#26a0a0a0"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Text {
                width: parent.width
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                text: "󰖐 tempo"
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                lineHeight: 1.15
                wrapMode: Text.Wrap
                text: weatherText
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#26a0a0a0"
            }

            Text {
                width: parent.width
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                text: "󰍛 sistema"
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                lineHeight: 1.2
                wrapMode: Text.NoWrap
                text: systemText
            }
        }
    }


    component ControlButton: Rectangle {
        property string label
        property var command: []
        property int minWidth: 104
        signal clicked

        width: Math.max(minWidth, buttonText.implicitWidth + 24)
        height: 34
        radius: 8
        color: clickArea.containsMouse ? "#33a0a0a0" : "#cc2a2a2e"
        border.color: "#26a0a0a0"
        border.width: 1

        Text {
            id: buttonText
            anchors.centerIn: parent
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            text: label
        }

        MouseArea {
            id: clickArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (command.length > 0) actionProc.exec(command);
                parent.clicked();
            }
        }

        Process { id: actionProc }
    }

    Component.onCompleted: root.refreshAll()
}
