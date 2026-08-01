import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool panelVisible: false
    property date now: new Date()
    property int calendarMonthOffset: 0
    property string mediaState: "Stopped"
    property string mediaTitle: "Nada tocando agora"
    property string mediaArtist: ""
    property string mediaAlbum: ""
    property string mediaArtUrl: ""
    property string weatherText: "Carregando tempo…"
    property string statusText: "Carregando status…"

    function refreshAll(): void {
        now = new Date();
        refreshMedia();
        weatherProc.exec(weatherProc.command);
        statusProc.exec(statusProc.command);
    }

    function refreshMedia(): void {
        mediaProc.exec(mediaProc.command);
    }

    function scheduleMediaRefresh(): void {
        mediaRefreshTimer.stop();
        mediaRefreshRepeats = 3;
        mediaRefreshTimer.start();
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
        return now.toLocaleDateString(Qt.locale("pt_BR"), "dddd, dd 'de' MMMM");
    }

    function calendarDate() {
        return new Date(now.getFullYear(), now.getMonth() + calendarMonthOffset, 1);
    }

    function resetCalendarMonth(): void {
        calendarMonthOffset = 0;
    }

    function previousCalendarMonth(): void {
        calendarMonthOffset--;
    }

    function nextCalendarMonth(): void {
        calendarMonthOffset++;
    }

    function openCalendar(): void {
        calendarProc.exec(calendarProc.command);
        panelVisible = false;
    }

    function openSpotify(): void {
        spotifyProc.exec(spotifyProc.command);
        panelVisible = false;
    }

    function monthTitle() {
        const date = calendarDate();
        return "󰃭 " + date.toLocaleDateString(Qt.locale("pt_BR"), "MMMM yyyy");
    }

    function calendarCells() {
        const date = calendarDate();
        const year = date.getFullYear();
        const month = date.getMonth();
        const today = now.getDate();
        const isCurrentMonth = year === now.getFullYear() && month === now.getMonth();
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
                today: isCurrentMonth && day === today
            });
        }

        return cells;
    }

    property int mediaRefreshRepeats: 0

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

    Timer {
        id: mediaRefreshTimer
        interval: 250
        repeat: true
        running: false
        onTriggered: {
            root.refreshMedia();
            root.mediaRefreshRepeats--;
            if (root.mediaRefreshRepeats <= 0) mediaRefreshTimer.stop();
        }
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

    Process {
        id: calendarProc
        command: ["/home/caetano/.local/bin/waybar-calendar.sh"]
    }

    Process {
        id: spotifyProc
        command: ["/home/caetano/.local/bin/media-open-spotify.sh"]
    }

    IpcHandler {
        target: "clockPanel"

        function toggle(): void {
            root.panelVisible = !root.panelVisible;
            if (root.panelVisible) {
                root.resetCalendarMonth();
                root.refreshAll();
            }
        }

        function show(): void {
            root.panelVisible = true;
            root.resetCalendarMonth();
            root.refreshAll();
        }

        function hide(): void {
            root.panelVisible = false;
        }

        function refresh(): void {
            root.refreshAll();
        }

        function previousMonth(): void {
            root.previousCalendarMonth();
        }

        function nextMonth(): void {
            root.nextCalendarMonth();
        }

        function resetMonth(): void {
            root.resetCalendarMonth();
        }

        function openCalendar(): void {
            root.openCalendar();
        }

        function openSpotify(): void {
            root.openSpotify();
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
                                onPreviousClicked: root.previousCalendarMonth()
                                onNextClicked: root.nextCalendarMonth()
                                onOpenClicked: root.openCalendar()
                            }
                        }

                        Column {
                            width: 230
                            spacing: 10

                            WeatherBox {
                                width: parent.width
                                weatherText: root.weatherText
                            }

                            SystemBox {
                                width: parent.width
                                systemText: root.statusText
                            }
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
                    width: 88
                    height: 88
                    radius: 9
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
                        font.pixelSize: 32
                        text: "󰝚"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openSpotify()
                    }
                }

                Column {
                    width: parent.width - 98
                    height: 88
                    spacing: 5

                    Text {
                        width: parent.width
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        lineHeight: 1.05
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
                width: parent.width
                spacing: 7
                property int sideButtonWidth: 58
                property int playButtonWidth: width - sideButtonWidth * 2 - spacing * 2
                anchors.horizontalCenter: parent.horizontalCenter

                ControlButton {
                    fixedWidth: parent.sideButtonWidth
                    buttonHeight: 28
                    label: "󰒮"
                    command: ["playerctl", "previous"]
                    onClicked: root.scheduleMediaRefresh()
                }
                ControlButton {
                    fixedWidth: parent.playButtonWidth
                    buttonHeight: 28
                    label: stateText === "Playing" ? "󰏤 pause" : "󰐊 play"
                    command: ["playerctl", "play-pause"]
                    onClicked: root.scheduleMediaRefresh()
                }
                ControlButton {
                    fixedWidth: parent.sideButtonWidth
                    buttonHeight: 28
                    label: "󰒭"
                    command: ["playerctl", "next"]
                    onClicked: root.scheduleMediaRefresh()
                }
            }
        }
    }

    component CalendarBox: Rectangle {
        id: calendarBox
        required property string title
        required property var cells
        signal previousClicked
        signal nextClicked
        signal openClicked

        height: 180
        radius: 10
        color: "#cc2a2a2e"
        border.color: "#26a0a0a0"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Row {
                width: parent.width
                height: 18
                spacing: 4

                Text {
                    width: parent.width - 44
                    color: "#a0a0a0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    text: title
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarBox.openClicked()
                    }
                }

                CalendarNavButton {
                    label: "‹"
                    onClicked: calendarBox.previousClicked()
                }

                CalendarNavButton {
                    label: "›"
                    onClicked: calendarBox.nextClicked()
                }
            }

            Grid {
                id: calendarGrid
                width: parent.width
                columns: 7
                columnSpacing: 3
                rowSpacing: 2

                Repeater {
                    model: cells

                    Rectangle {
                        required property var modelData

                        width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                        height: 18
                        color: "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 5
                            color: modelData.today ? "#22a0a0a0" : "transparent"
                            border.color: "#26a0a0a0"
                            border.width: modelData.today ? 1 : 0
                        }

                        Text {
                            anchors.centerIn: parent
                            color: modelData.header ? "#deddda" : "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: modelData.header
                            text: modelData.text
                        }
                    }
                }
            }
        }
    }

    component CalendarNavButton: Rectangle {
        property string label
        signal clicked

        width: 18
        height: 18
        radius: 5
        color: navArea.containsMouse ? "#33a0a0a0" : "transparent"
        border.color: "#26a0a0a0"
        border.width: 1

        Text {
            anchors.centerIn: parent
            color: "#deddda"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
            text: label
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component WeatherBox: Rectangle {
        required property string weatherText

        height: 220
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
        }
    }

    component SystemBox: Rectangle {
        required property string systemText

        height: 140
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
        property int fixedWidth: 0
        property int buttonHeight: 34
        signal clicked

        width: fixedWidth > 0 ? fixedWidth : Math.max(minWidth, buttonText.implicitWidth + 24)
        height: buttonHeight
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
