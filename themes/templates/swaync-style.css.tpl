/* Gerado por theme-set.sh — NÃO editar à mão. */
@import url("colors.css");

/* === GLOBAL ==================================== */
* {
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 13px;
  border: none;
  min-height: 0;
  transition: all 0.2s ease;
}

/* === CONTROL CENTER ============================ */
.control-center {
  background-color: alpha(@quick_panel_background, {{ quick_panel_opacity }});
  border: 1px solid alpha(@accent, 0.22);
  border-radius: {{ quick_panel_radius }}px;
  padding: 10px;
  margin: 8px;
  color: @foreground;
  box-shadow: {{ quick_box_shadow }};
}

/* === LISTA DE NOTIFICAÇÕES ===================== */
.notification-row {
  margin: 4px 0;
}

.notification {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border: 1px solid alpha(@accent, 0.18);
  border-radius: {{ quick_card_radius }}px;
  padding: 10px 12px;
  color: @foreground;
}

.notification:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
  border-color: alpha(@accent, 0.35);
}

/* === URGÊNCIA ================================== */
.notification.critical {
  border-left: 2px solid alpha(@error, 0.8);
}

.notification.normal {
  border-left: 2px solid alpha(@accent, 0.5);
}

.notification.low {
  border-left: 2px solid alpha(@accent, 0.35);
}

/* === CONTEÚDO DA NOTIFICAÇÃO =================== */
.notification-default-action {
  border-radius: {{ quick_card_radius }}px;
  padding: 0;
}

.notification-default-action:hover {
  background-color: transparent;
}

.notification-summary {
  font-weight: bold;
  font-size: 13px;
  color: @foreground;
}

.notification-body {
  font-size: 12px;
  color: @accent;
  margin-top: 2px;
}

.notification-time {
  font-size: 11px;
  color: alpha(@accent, 0.6);
}

/* === BOTÃO FECHAR ============================== */
.close-button {
  background-color: transparent;
  color: alpha(@accent, 0.5);
  border-radius: {{ quick_card_radius }}px;
  min-width: 18px;
  min-height: 18px;
  font-size: 12px;
}

.close-button:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
  color: @foreground;
}

/* === BOTÕES DE AÇÃO ============================ */
.notification-action-button {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border-radius: {{ quick_button_radius }}px;
  color: @foreground;
  padding: 4px 10px;
  margin: 4px 2px 0;
  font-size: 12px;
}

.notification-action-button:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
  color: @foreground;
}

/* === CABEÇALHO DO CONTROL CENTER =============== */
.widget-title {
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid alpha(@accent, 0.18);
}

.widget-title > label {
  font-weight: bold;
  font-size: 13px;
  color: @foreground;
}

.widget-title > button {
  background-color: transparent;
  color: @accent;
  border-radius: {{ quick_card_radius }}px;
  padding: 2px 8px;
  font-size: 12px;
}

.widget-title > button:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
  color: @foreground;
}

/* === WIDGET DND ================================ */
.widget-dnd {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border: 1px solid alpha(@accent, 0.16);
  border-radius: {{ quick_card_radius }}px;
  padding: 8px 12px;
  margin-bottom: 6px;
  color: @foreground;
}

.widget-dnd > switch {
  border-radius: {{ quick_switch_radius }}px;
  background-color: alpha(@quick_hover_background, 0.72);
}

.widget-dnd > switch:checked {
  background-color: alpha(@accent, 0.85);
}

.widget-dnd > switch slider {
  background-color: @foreground;
  border-radius: {{ quick_switch_radius }}px;
}

/* === WIDGET LABEL ============================== */
.widget-label {
  padding: 4px 2px;
}

.widget-label > label {
  font-weight: bold;
  color: @foreground;
  font-size: 13px;
}


/* === WIDGET VOLUME ============================= */
.widget-volume {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border: 1px solid alpha(@accent, 0.16);
  border-radius: {{ quick_card_radius }}px;
  padding: 8px 12px;
  margin-bottom: 6px;
  color: @foreground;
}

.widget-volume > box > button {
  background-color: transparent;
  color: @accent;
  border-radius: {{ quick_card_radius }}px;
  padding: 2px 6px;
}

.widget-volume > box > button:hover {
  color: @foreground;
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
}

scale trough {
  background-color: alpha(@quick_hover_background, 0.72);
  border-radius: {{ quick_button_radius }}px;
  min-height: 4px;
}

scale highlight {
  background-color: @foreground;
  border-radius: {{ quick_card_radius }}px;
}

scale slider {
  background-color: @foreground;
  border-radius: {{ quick_card_radius }}px;
  min-width: 12px;
  min-height: 12px;
}

/* === POPUP (notificação flutuante) ============= */
.floating-notifications {
  background-color: transparent;
}

.blank-window {
  background-color: transparent;
}

.notification-window {
  background-color: transparent;
  border-radius: {{ quick_card_radius }}px;
  margin: 4px;
}

/* === BUTTONS GRID ============================== */
.widget-buttons-grid {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border: 1px solid alpha(@accent, 0.16);
  border-radius: {{ quick_card_radius }}px;
  padding: 8px;
  margin-bottom: 6px;
}

.widget-buttons-grid > flowbox > flowboxchild > button {
  background-color: alpha(@quick_card_background, {{ quick_card_opacity }});
  border-radius: {{ quick_card_radius }}px;
  color: @foreground;
  font-size: 18px;
  min-width: 48px;
  min-height: 48px;
  margin: 3px;
}

.widget-buttons-grid > flowbox > flowboxchild > button:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
  color: @foreground;
}

/* === EMPTY STATE / LIST BACKGROUNDS ============= */
.control-center-list,
.notification-group,
.notification-group-headers,
.notification-group-header,
.notification-group-collapse-button,
.widget-notifications,
.widget-inhibitors {
  background-color: transparent;
  border-radius: {{ quick_card_radius }}px;
}

.notification-group-collapse-button:hover,
.notification-group-close-all-button:hover {
  background-color: alpha(@quick_hover_background, {{ quick_hover_opacity }});
}

.control-center image,
.control-center label {
  color: @foreground;
}

.widget-notifications image,
.widget-notifications label {
  color: alpha(@foreground, 0.65);
}
