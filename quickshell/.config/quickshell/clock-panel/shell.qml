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
    property int spotifyVolume: 0
    property bool spotifyMuted: false
    property bool spotifyVolumeAvailable: false
    readonly property string spotifyVolumeScript: "/home/caetano/.local/bin/media-volume-spotify.sh"

    function colorWithAlpha(value, alpha) {
        const raw = String(value || "#000000").replace("#", "");
        if (raw.length < 6) return Qt.rgba(0, 0, 0, alpha);

        const r = parseInt(raw.slice(0, 2), 16) / 255;
        const g = parseInt(raw.slice(2, 4), 16) / 255;
        const b = parseInt(raw.slice(4, 6), 16) / 255;
        return Qt.rgba(r, g, b, alpha);
    }

    function refreshAll(): void {
        now = new Date();
        refreshMedia();
        refreshSpotifyVolume();
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

    function refreshSpotifyVolume(): void {
        spotifyVolumeProc.exec([root.spotifyVolumeScript, "get"]);
    }

    function updateSpotifyVolume(raw) {
        const parts = raw.trim().split("|");
        const vol = parseInt(parts[0], 10);
        if (isNaN(vol) || vol < 0) {
            spotifyVolumeAvailable = false;
            spotifyVolume = 0;
            spotifyMuted = false;
            return;
        }
        spotifyVolumeAvailable = true;
        spotifyVolume = vol;
        spotifyMuted = parts[1] === "1";
    }

    function setSpotifyVolume(pct): void {
        const clamped = Math.max(0, Math.min(100, Math.round(pct)));
        spotifyVolume = clamped;
        spotifyVolumeAvailable = true;
        spotifyVolumeProc.exec([root.spotifyVolumeScript, "set", String(clamped)]);
    }

    function toggleSpotifyMute(): void {
        spotifyVolumeProc.exec([root.spotifyVolumeScript, "mute"]);
    }

    function increaseSpotifyVolume(): void {
        spotifyVolumeProc.exec([root.spotifyVolumeScript, "up"]);
    }

    function decreaseSpotifyVolume(): void {
        spotifyVolumeProc.exec([root.spotifyVolumeScript, "down"]);
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

    Process {
        id: spotifyVolumeProc
        command: [root.spotifyVolumeScript, "get"]
        stdout: StdioCollector { onStreamFinished: root.updateSpotifyVolume(text) }
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
                width:  600
                height:  380
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                transform: Scale {
                    origin.x: panel.width / 2
                    origin.y: 0
                    xScale:  0.75
                    yScale:  0.75
                }
                anchors.topMargin: 0
                radius:  0
                color: root.colorWithAlpha("#0f0f10",  0.72)
                border.color: root.colorWithAlpha("#8a8a8d", 0.2)
                border.width: 1

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins:  12
                    spacing:  8


                    Row {
                        width: parent.width
                        spacing:  8

                        Column {
                            width:  288
                            spacing:  8

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
                            width:  280
                            spacing:  8

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

        Shortcut {
            sequence: "Ctrl+Up"
            onActivated: root.increaseSpotifyVolume()
        }

        Shortcut {
            sequence: "Ctrl+Down"
            onActivated: root.decreaseSpotifyVolume()
        }
    }

    component MediaBox: Rectangle {
        required property string stateIcon
        required property string stateText
        required property string titleText
        required property string artistText
        required property string albumText
        required property string artUrl

        height:  180
        radius:  0
        color: root.colorWithAlpha("#0f0f10",  0.56)
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
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
                    width:  80
                    height:  80
                    radius:  0
                    clip: true
                    color: root.colorWithAlpha("#0f0f10",  0.56)
                    border.color: root.colorWithAlpha("#8a8a8d", 0.28)
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
                    width: parent.width -  80 - 10
                    height:  80
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
                    buttonHeight:  26
                    label: "󰒮"
                    command: ["playerctl", "previous"]
                    onClicked: root.scheduleMediaRefresh()
                }
                ControlButton {
                    fixedWidth: parent.playButtonWidth
                    buttonHeight:  26
                    label: stateText === "Playing" ? "󰏤 pause" : "󰐊 play"
                    command: ["playerctl", "play-pause"]
                    onClicked: root.scheduleMediaRefresh()
                }
                ControlButton {
                    fixedWidth: parent.sideButtonWidth
                    buttonHeight:  26
                    label: "󰒭"
                    command: ["playerctl", "next"]
                    onClicked: root.scheduleMediaRefresh()
                }
            }

            VolumeSlider {
                width: parent.width
                value: root.spotifyVolume
                muted: root.spotifyMuted
                available: root.spotifyVolumeAvailable
                onChanged: (pct) => root.setSpotifyVolume(pct)
                onMuteToggled: root.toggleSpotifyMute()
            }
        }
    }

    component VolumeSlider: Item {
        id: volumeSlider
        required property int value
        required property bool muted
        required property bool available
        signal changed(real pct)
        signal muteToggled

        height: 20

        Row {
            anchors.fill: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                horizontalAlignment: Text.AlignHCenter
                color: "#deddda"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                opacity: volumeSlider.available ? 1 : 0.4
                text: volumeSlider.muted || !volumeSlider.available ? "󰝟" : volumeSlider.value > 60 ? "󰕾" : volumeSlider.value > 0 ? "󰖀" : "󰕿"

                MouseArea {
                    anchors.fill: parent
                    enabled: volumeSlider.available
                    cursorShape: Qt.PointingHandCursor
                    onClicked: volumeSlider.muteToggled()
                }
            }

            Rectangle {
                id: track
                width: parent.width - 16 - 34 - parent.spacing * 2
                height: 3
                anchors.verticalCenter: parent.verticalCenter
                radius:  0
                color: root.colorWithAlpha("#0f0f10",  0.56)
                border.color: root.colorWithAlpha("#8a8a8d", 0.28)
                border.width: 1
                opacity: volumeSlider.available ? 1 : 0.4

                Rectangle {
                    width: Math.max(0, track.width * Math.max(0, Math.min(100, volumeSlider.muted ? 0 : volumeSlider.value)) / 100 - 2)
                    height: parent.height - 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 1
                    radius: 0
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: volumeSlider.available
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => volumeSlider.changed(mouse.x / track.width * 100)
                    onPositionChanged: (mouse) => { if (pressed) volumeSlider.changed(mouse.x / track.width * 100); }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignRight
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                text: !volumeSlider.available ? "n/d" : volumeSlider.muted ? "mudo" : volumeSlider.value + "%"
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

        height:  160
        radius:  0
        color: root.colorWithAlpha("#0f0f10",  0.56)
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Row {
                width: parent.width
                height: Math.max(16,  26 - 10)
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
                        height:  0 === 0 ? 15 : 18
                        color: "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width:  0 === 0 ? 16 : 18
                            height:  0 === 0 ? 15 : 18
                            radius:  0
                            color: modelData.today ? root.colorWithAlpha("#8a8a8d", 0.28) : "transparent"
                            border.color: root.colorWithAlpha("#8a8a8d", 0.28)
                            border.width: modelData.today ? 1 : 0
                        }

                        Text {
                            anchors.centerIn: parent
                            color: modelData.header ? "#deddda" : "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize:  0 === 0 ? 11 : 12
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
        height:  0 === 0 ? 16 : 18
        radius:  0
        color: navArea.containsMouse ? root.colorWithAlpha("#18181b",  0.72) : "transparent"
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
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

        height:  180
        radius:  0
        color: root.colorWithAlpha("#0f0f10",  0.56)
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
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

        height:  160
        radius:  0
        color: root.colorWithAlpha("#0f0f10",  0.56)
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
        border.width: 1

        Column {
            id: systemColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4
            property var lines: systemText.length > 0 ? systemText.split("\n") : []

            Text {
                width: parent.width
                color: "#a0a0a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                text: "󰍛 sistema"
                elide: Text.ElideRight
            }

            Repeater {
                model: systemColumn.lines.slice(0, Math.max(0, systemColumn.lines.length - 1))

                Row {
                    id: systemRow
                    width: parent.width
                    height: 16
                    spacing: 1
                    property var fields: modelData.split("|")

                    Text {
                        id: labelText
                        width: 40
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        text: (systemRow.fields[0] || "") + " " + (systemRow.fields[1] || "")
                    }

                    Text {
                        id: barText
                        width: systemRow.width - labelText.width - pctText.width - systemRow.spacing * 2
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        clip: true
                        text: systemRow.fields[2] || ""
                    }

                    Text {
                        id: pctText
                        width: 34
                        color: "#ffffff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                        text: systemRow.fields[3] || ""
                    }
                }
            }

            Text {
                width: parent.width
                color: "#e5c07b"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                text: {
                    const fields = systemColumn.lines.length > 0 ? systemColumn.lines[systemColumn.lines.length - 1].split("|") : [];
                    return fields.length >= 4 ? fields[0] + " " + fields.slice(1).join("  ") : "";
                }
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
        radius:  0
        color: root.colorWithAlpha(clickArea.containsMouse ? "#18181b" : "#0f0f10", clickArea.containsMouse ?  0.72 :  0.56)
        border.color: root.colorWithAlpha("#8a8a8d", 0.28)
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
