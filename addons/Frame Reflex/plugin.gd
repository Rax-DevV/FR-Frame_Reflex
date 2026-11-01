@tool
extends EditorPlugin

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  FR – FrameReflex  |  plugin.gd                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

const AUTOLOAD_NAME     := "FRManager"
const AUTOLOAD_PATH     := "res://addons/Frame Reflex/FRManager.gd"
const MODE_SETTING      := "fr/mode"
const CUSTOM_CFG_PATH   := "user://fr_custom_mode.cfg"

const MODE_LOD_THRESHOLD := { "Performance": 15.0, "Balanced": 10.0, "Quality": 5.0 }

const CUSTOM_DEFAULTS := {
	"name": "Custom", "scale_min": 0.65, "scale_max": 0.75, "shadow_min": 1024, "shadow_max": 2048,
	"shadow_filter_min": 0, "shadow_filter_max": 1, "fps_min": 60.0, "fps_max": 144.0,
	"tex_viewport": 1, "aa_mode": 1, "aa_min": 0, "aa_max": 1, "sdfgi_enabled": false,
	"sdfgi_rays": 0, "sdfgi_converge": 0, "sdfgi_lights": 3, "ssil_enabled": false,
	"ssil_quality": 0, "ssao_enabled": false, "ssao_quality": 0, "ssr_enabled": false,
	"ssr_quality": 0, "lod_min": 5.0, "lod_max": 15.0, "lod_threshold": 10.0,
	"smooth_time": 1.5, "compatibility_mode": false, "mobile_mode": false,
	"show_prints": true, "tex_filter": 1, "fsr_enabled": true, "fsr_scale_min": 0.50,
	"fsr_scale_max": 0.75, "vsync_mode": 0
}

var _root_panel : Control = null
var _custom : Dictionary = {}

# ── Ref Controls ──────────────────────────────────────────────────────────────
var _name_edit: LineEdit = null
var _current_mode_lbl: Label = null
var _res_min_spin: SpinBox = null; var _res_max_spin: SpinBox = null
var _shadow_min_opt: OptionButton = null; var _shadow_max_opt: OptionButton = null
var _sfilter_min_opt: OptionButton = null; var _sfilter_max_opt: OptionButton = null
var _fps_min_spin: SpinBox = null; var _fps_max_spin: SpinBox = null
var _tex_vp_opt: OptionButton = null
var _aa_min_opt: OptionButton = null; var _aa_max_opt: OptionButton = null
var _vsync_opt: OptionButton = null
var _fsr_check: CheckBox = null; var _fsr_scale_min_spin: SpinBox = null; var _fsr_scale_max_spin: SpinBox = null
var _sdfgi_check: CheckBox = null; var _sdfgi_rays_opt: OptionButton = null; var _sdfgi_conv_opt: OptionButton = null; var _sdfgi_light_opt: OptionButton = null
var _ssil_check: CheckBox = null; var _ssil_min_opt: OptionButton = null; var _ssil_max_opt: OptionButton = null
var _ssao_check: CheckBox = null; var _ssao_min_opt: OptionButton = null; var _ssao_max_opt: OptionButton = null
var _ssr_check: CheckBox = null; var _ssr_min_opt: OptionButton = null; var _ssr_max_opt: OptionButton = null
var _lod_min_spin: SpinBox = null; var _lod_max_spin: SpinBox = null
var _smooth_spin: SpinBox = null
var _compat_check: CheckBox = null; var _mobile_check: CheckBox = null; var _prints_check: CheckBox = null
var _quick_prints_check: CheckBox = null
var _export_text: TextEdit = null; var _import_text: TextEdit = null
var _import_status_lbl: Label = null

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _enter_tree() -> void:
	if _root_panel != null: return
	_load_custom_cfg()
	_build_root_panel()
	add_control_to_bottom_panel(_root_panel, "FrameReflex")
	_register_autoload()

func _exit_tree() -> void:
	if _root_panel != null:
		remove_control_from_bottom_panel(_root_panel)
		_root_panel.queue_free()
		_root_panel = null
	_unregister_autoload()

func _register_autoload() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _unregister_autoload() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

func _load_custom_cfg() -> void:
	_custom = CUSTOM_DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(CUSTOM_CFG_PATH) == OK:
		for k in CUSTOM_DEFAULTS:
			if cfg.has_section_key("custom", k): _custom[k] = cfg.get_value("custom", k)

func _save_custom_cfg() -> void:
	var cfg := ConfigFile.new()
	for k in _custom: cfg.set_value("custom", k, _custom[k])
	cfg.save(CUSTOM_CFG_PATH)
	ProjectSettings.set_setting("fr/custom_name", _custom.get("name", "Custom"))
	ProjectSettings.save()

# ══════════════════════════════════════════════════════════════════════════════
# UI BUILDERS (GDSYNC STYLE)
# ══════════════════════════════════════════════════════════════════════════════

func _build_root_panel() -> void:
	_root_panel = Control.new()
	_root_panel.name = "FR Modes"
	_root_panel.custom_minimum_size = Vector2(0, 300)

	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _get_bg_style())
	_root_panel.add_child(bg)

	var tabs := TabContainer.new()
	tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_root_panel.add_child(tabs)

	var quick_tab := _build_quick_tab()
	quick_tab.name = "Dashboard"
	tabs.add_child(quick_tab)

	var custom_tab := _build_custom_tab()
	custom_tab.name = "Custom Mode Config"
	tabs.add_child(custom_tab)

func _build_quick_tab() -> MarginContainer:
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 20)
	mc.add_theme_constant_override("margin_top", 20)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	mc.add_child(vbox)

	var header = Label.new()
	header.text = "FrameReflex Dashboard"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(header)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	_current_mode_lbl = Label.new()
	_refresh_mode_label()
	hbox.add_child(_current_mode_lbl)
	hbox.add_child(_vsep())

	var modes = [
		["Performance", Color(0.9, 0.45, 0.3)], ["Balanced", Color(0.9, 0.8, 0.3)], ["Quality", Color(0.3, 0.8, 0.5)]
	]
	for m in modes:
		var btn := Button.new()
		btn.text = "  " + m[0] + "  "
		btn.add_theme_color_override("font_color", m[1])
		btn.add_theme_stylebox_override("normal", _get_btn_style())
		btn.pressed.connect(_on_builtin_mode_pressed.bind(m[0]))
		hbox.add_child(btn)

	var custom_btn := Button.new()
	custom_btn.text = "  " + _custom.get("name", "Custom") + "  "
	custom_btn.add_theme_color_override("font_color", Color(0.6, 0.5, 1.0))
	custom_btn.add_theme_stylebox_override("normal", _get_btn_style())
	custom_btn.pressed.connect(_on_custom_mode_quick_pressed.bind(custom_btn))
	custom_btn.name = "CustomQuickBtn"
	hbox.add_child(custom_btn)

	hbox.add_child(_vsep())

	_quick_prints_check = _checkbox("Log Output", _custom.get("show_prints", true))
	_quick_prints_check.toggled.connect(_on_quick_prints_toggled)
	hbox.add_child(_quick_prints_check)

	return mc

func _build_custom_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 16)
	outer_margin.add_theme_constant_override("margin_right", 16)
	outer_margin.add_theme_constant_override("margin_top", 16)
	outer_margin.add_theme_constant_override("margin_bottom", 16)
	outer_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(outer_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	outer_margin.add_child(main_vbox)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(grid)

	# ── Card 1: Core ────────────────────────────────────────────────────────
	var c_core = _create_card("Core Settings", grid)
	var name_row = _hrow("Profile Name")
	_name_edit = LineEdit.new()
	_name_edit.text = _custom.get("name", "Custom")
	_name_edit.custom_minimum_size = Vector2(140, 0)
	_name_edit.text_submitted.connect(_on_name_changed)
	name_row.add_child(_name_edit)
	c_core.add_child(name_row)

	var fps_row = _hrow("Target FPS (Min/Max)")
	_fps_min_spin = _spinbox(10, 500, 1, int(_custom.get("fps_min", 60.0)))
	_fps_max_spin = _spinbox(10, 500, 1, int(_custom.get("fps_max", 144.0)))
	fps_row.add_child(_fps_min_spin); fps_row.add_child(Label.new()); fps_row.add_child(_fps_max_spin)
	c_core.add_child(fps_row)

	var st_row = _hrow("Smooth Time (s)")
	_smooth_spin = _spinboxf(0.1, 10.0, 0.1, _custom.get("smooth_time", 1.5))
	st_row.add_child(_smooth_spin)
	c_core.add_child(st_row)

	var vsync_row = _hrow("VSync Override")
	_vsync_opt = _option(["Off", "On", "Adaptive", "Mailbox"], clamp(_custom.get("vsync_mode", 0), 0, 3))
	vsync_row.add_child(_vsync_opt)
	c_core.add_child(vsync_row)

	# ── Card 2: Rendering & FSR ─────────────────────────────────────────────
	var c_res = _create_card("Resolution & Upscaling", grid)
	var res_row = _hrow("Base Scale % (Min/Max)")
	_res_min_spin = _spinbox(30, 100, 1, int(_custom.get("scale_min", 0.65) * 100.0))
	_res_max_spin = _spinbox(30, 100, 1, int(_custom.get("scale_max", 0.75) * 100.0))
	res_row.add_child(_res_min_spin); res_row.add_child(Label.new()); res_row.add_child(_res_max_spin)
	c_res.add_child(res_row)

	var fsr_row = _hrow("AMD FSR 1.0")
	_fsr_check = _checkbox("Enabled", _custom.get("fsr_enabled", true))
	_fsr_check.toggled.connect(_on_fsr_toggled)
	fsr_row.add_child(_fsr_check)
	c_res.add_child(fsr_row)

	var fsr_detail = _hrow("  ↳ FSR Limit (Min/Max)")
	_fsr_scale_min_spin = _spinbox(30, 100, 1, int(_custom.get("fsr_scale_min", 0.50) * 100.0))
	_fsr_scale_max_spin = _spinbox(30, 100, 1, int(_custom.get("fsr_scale_max", 0.75) * 100.0))
	fsr_detail.add_child(_fsr_scale_min_spin); fsr_detail.add_child(Label.new()); fsr_detail.add_child(_fsr_scale_max_spin)
	c_res.add_child(fsr_detail)
	
	var tvp_row = _hrow("Texture Viewport")
	_tex_vp_opt = _option(["Nearest", "Linear"], _custom.get("tex_viewport", 1))
	tvp_row.add_child(_tex_vp_opt)
	c_res.add_child(tvp_row)

	# ── Card 3: Details & Shadows ───────────────────────────────────────────
	var c_shadow = _create_card("Details & Shadows", grid)
	var sha_row = _hrow("Atlas Size (Min/Max)")
	_shadow_min_opt = _option(["512", "1024", "2048"], _shadow_to_idx(_custom.get("shadow_min", 1024)))
	_shadow_max_opt = _option(["512", "1024", "2048"], _shadow_to_idx(_custom.get("shadow_max", 2048)))
	sha_row.add_child(_shadow_min_opt); sha_row.add_child(Label.new()); sha_row.add_child(_shadow_max_opt)
	c_shadow.add_child(sha_row)

	var sf_row = _hrow("Shadow Filter")
	_sfilter_min_opt = _option(["Low", "Mid", "High"], _custom.get("shadow_filter_min", 0))
	_sfilter_max_opt = _option(["Low", "Mid", "High"], _custom.get("shadow_filter_max", 1))
	sf_row.add_child(_sfilter_min_opt); sf_row.add_child(Label.new()); sf_row.add_child(_sfilter_max_opt)
	c_shadow.add_child(sf_row)
	
	var lod_row = _hrow("LOD Pixels (Min/Max)")
	_lod_min_spin = _spinboxf(0.0, 50.0, 0.5, _custom.get("lod_min", 5.0))
	_lod_max_spin = _spinboxf(0.0, 50.0, 0.5, _custom.get("lod_max", 15.0))
	lod_row.add_child(_lod_min_spin); lod_row.add_child(Label.new()); lod_row.add_child(_lod_max_spin)
	c_shadow.add_child(lod_row)
	
	var aa_row = _hrow("Anti-Aliasing")
	_aa_min_opt = _option(["Off", "FXAA", "TAA"], _custom.get("aa_min", 0))
	_aa_max_opt = _option(["Off", "FXAA", "TAA"], _custom.get("aa_max", 1))
	aa_row.add_child(_aa_min_opt); aa_row.add_child(Label.new()); aa_row.add_child(_aa_max_opt)
	c_shadow.add_child(aa_row)

	# ── Card 4: Post-Processing ─────────────────────────────────────────────
	var c_fx = _create_card("Global Illumination & Effects", grid)
	var sdfgi_row = _hrow("SDFGI")
	_sdfgi_check = _checkbox("Enabled", _custom.get("sdfgi_enabled", false))
	_sdfgi_check.toggled.connect(_on_sdfgi_toggled)
	sdfgi_row.add_child(_sdfgi_check)
	var sdfgi_det = _hrow("  ↳ Rays/Conv/Lights")
	_sdfgi_rays_opt = _option(["8", "16", "32", "64"], _custom.get("sdfgi_rays", 0))
	_sdfgi_conv_opt = _option(["5f", "10f", "15f", "20f", "25f", "30f"], _custom.get("sdfgi_converge", 0))
	_sdfgi_light_opt = _option(["every 2", "every 4", "every 8"], _sdfgi_lights_to_idx(_custom.get("sdfgi_lights", 3)))
	sdfgi_det.add_child(_sdfgi_rays_opt); sdfgi_det.add_child(_sdfgi_conv_opt); sdfgi_det.add_child(_sdfgi_light_opt)
	c_fx.add_child(sdfgi_row); c_fx.add_child(sdfgi_det)

	var ssil_row = _hrow("SSIL"); _ssil_check = _checkbox("Enabled", _custom.get("ssil_enabled", false))
	_ssil_check.toggled.connect(_on_ssil_toggled); ssil_row.add_child(_ssil_check)
	var ssil_det = _hrow("  ↳ Min/Max"); _ssil_min_opt = _option(["Very Low", "Low", "Medium", "High"], 0)
	_ssil_max_opt = _option(["Very Low", "Low", "Medium", "High"], _custom.get("ssil_quality", 0))
	ssil_det.add_child(_ssil_min_opt); ssil_det.add_child(Label.new()); ssil_det.add_child(_ssil_max_opt)
	c_fx.add_child(ssil_row); c_fx.add_child(ssil_det)

	var ssao_row = _hrow("SSAO"); _ssao_check = _checkbox("Enabled", _custom.get("ssao_enabled", false))
	_ssao_check.toggled.connect(_on_ssao_toggled); ssao_row.add_child(_ssao_check)
	var ssao_det = _hrow("  ↳ Min/Max"); _ssao_min_opt = _option(["Very Low", "Low", "Medium", "High"], 0)
	_ssao_max_opt = _option(["Very Low", "Low", "Medium", "High"], _custom.get("ssao_quality", 0))
	ssao_det.add_child(_ssao_min_opt); ssao_det.add_child(Label.new()); ssao_det.add_child(_ssao_max_opt)
	c_fx.add_child(ssao_row); c_fx.add_child(ssao_det)

	var ssr_row = _hrow("SSR"); _ssr_check = _checkbox("Enabled", _custom.get("ssr_enabled", false))
	_ssr_check.toggled.connect(_on_ssr_toggled); ssr_row.add_child(_ssr_check)
	var ssr_det = _hrow("  ↳ Min/Max"); _ssr_min_opt = _option(["Disabled", "Low", "Medium", "High", "Ultra"], 0)
	_ssr_max_opt = _option(["Disabled", "Low", "Medium", "High", "Ultra"], _custom.get("ssr_quality", 0))
	ssr_det.add_child(_ssr_min_opt); ssr_det.add_child(Label.new()); ssr_det.add_child(_ssr_max_opt)
	c_fx.add_child(ssr_row); c_fx.add_child(ssr_det)

	# ── Card 5: Engine Flags ────────────────────────────────────────────────
	var c_flags = _create_card("Overrides & Logging", grid)
	_compat_check = _checkbox("Force Compatibility Mode", _custom.get("compatibility_mode", false))
	_mobile_check = _checkbox("Force Mobile Mode", _custom.get("mobile_mode", false))
	_prints_check = _checkbox("Print State Changes to Console", _custom.get("show_prints", true))
	_compat_check.toggled.connect(_on_compat_toggled)
	_mobile_check.toggled.connect(_on_mobile_toggled)
	_prints_check.toggled.connect(_on_custom_prints_toggled)
	c_flags.add_child(_compat_check); c_flags.add_child(_mobile_check); c_flags.add_child(_prints_check)

	# ── Card 6: Import/Export ───────────────────────────────────────────────
	var c_tool = _create_card("Management Tools", grid)
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	
	var apply_btn = Button.new(); apply_btn.text = "Apply Custom Settings"
	apply_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	apply_btn.pressed.connect(_on_apply_custom_pressed)
	btn_row.add_child(apply_btn)

	var reset_btn = Button.new(); reset_btn.text = "Reset to Defaults"
	reset_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	reset_btn.pressed.connect(_on_reset_custom_pressed)
	btn_row.add_child(reset_btn)
	c_tool.add_child(btn_row)
	c_tool.add_child(HSeparator.new())

	var ie_grid = GridContainer.new(); ie_grid.columns = 2; ie_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_tool.add_child(ie_grid)
	
	var exp_v = VBoxContainer.new(); exp_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var exp_btn = Button.new(); exp_btn.text = "Export (Copy Text)"; exp_btn.pressed.connect(_on_export_pressed)
	_export_text = TextEdit.new(); _export_text.custom_minimum_size = Vector2(0, 80); _export_text.editable = false
	exp_v.add_child(exp_btn); exp_v.add_child(_export_text)
	ie_grid.add_child(exp_v)

	var imp_v = VBoxContainer.new(); imp_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var imp_btn = Button.new(); imp_btn.text = "Import Config"; imp_btn.pressed.connect(_on_import_pressed)
	_import_text = TextEdit.new(); _import_text.custom_minimum_size = Vector2(0, 80); _import_text.placeholder_text = "Paste here..."
	imp_v.add_child(imp_btn); imp_v.add_child(_import_text)
	ie_grid.add_child(imp_v)
	
	_import_status_lbl = Label.new()
	c_tool.add_child(_import_status_lbl)

	_update_sdfgi_controls_state(); _update_ssil_controls_state(); _update_ssao_controls_state(); _update_ssr_controls_state(); _update_fsr_controls_state()
	return scroll

# ══════════════════════════════════════════════════════════════════════════════
# STYLING & HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _get_bg_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.14)
	return sb

func _get_btn_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.25)
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4; sb.corner_radius_bottom_right = 4
	sb.content_margin_top = 4; sb.content_margin_bottom = 4
	sb.content_margin_left = 8; sb.content_margin_right = 8
	return sb

func _get_card_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.16, 0.18)
	sb.border_width_bottom = 2; sb.border_color = Color(0.1, 0.1, 0.12)
	sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
	return sb

func _create_card(title: String, parent: Control) -> VBoxContainer:
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_FILL
	pc.add_theme_stylebox_override("panel", _get_card_style())
	parent.add_child(pc)
	
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top", 12)
	mc.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(mc)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	mc.add_child(vb)
	
	var lbl = Label.new()
	lbl.text = title.to_upper()
	lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 0.8))
	lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(lbl)
	vb.add_child(HSeparator.new())
	
	return vb

func _hrow(label_text: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(170, 0)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(lbl)
	return hbox

func _vsep() -> VSeparator:
	var s = VSeparator.new()
	s.modulate = Color(1, 1, 1, 0.3)
	return s

func _spinbox(minv: int, maxv: int, step: int, value: int) -> SpinBox:
	var sb := SpinBox.new(); sb.min_value = minv; sb.max_value = maxv; sb.step = step; sb.value = value
	sb.custom_minimum_size = Vector2(75, 0)
	return sb

func _spinboxf(minv: float, maxv: float, step: float, value: float) -> SpinBox:
	var sb := SpinBox.new(); sb.min_value = minv; sb.max_value = maxv; sb.step = step; sb.value = value
	sb.custom_minimum_size = Vector2(75, 0)
	return sb

func _option(items: Array, selected: int) -> OptionButton:
	var ob := OptionButton.new()
	for item in items: ob.add_item(item)
	ob.selected = clamp(selected, 0, items.size() - 1)
	ob.custom_minimum_size = Vector2(110, 0)
	return ob

func _checkbox(label_text: String, checked: bool) -> CheckBox:
	var cb := CheckBox.new(); cb.text = label_text; cb.button_pressed = checked
	return cb

func _shadow_to_idx(size: int) -> int:
	match size:
		512: return 0
		2048: return 2
		_: return 1

func _idx_to_shadow(idx: int) -> int:
	match idx:
		0: return 512
		2: return 2048
		_: return 1024

func _sdfgi_lights_to_idx(val: int) -> int:
	match val:
		1: return 0
		2: return 1
		_: return 2

func _idx_to_sdfgi_lights(idx: int) -> int:
	match idx:
		0: return 1
		1: return 2
		_: return 3

# ══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

func _on_builtin_mode_pressed(mode: String) -> void:
	ProjectSettings.set_setting(MODE_SETTING, mode); ProjectSettings.save()
	var cfg := ConfigFile.new(); cfg.set_value("fr", "mode", mode); cfg.save("user://fr_config.cfg")
	_refresh_mode_label()

func _on_custom_mode_quick_pressed(btn: Button) -> void:
	ProjectSettings.set_setting(MODE_SETTING, "Custom"); ProjectSettings.save()
	var cfg := ConfigFile.new(); cfg.set_value("fr", "mode", "Custom"); cfg.save("user://fr_config.cfg")
	_refresh_mode_label()

func _on_name_changed(new_name: String) -> void:
	_custom["name"] = new_name; _save_custom_cfg()
	if _root_panel:
		var btn = _root_panel.find_child("CustomQuickBtn", true, false)
		if btn: btn.text = "  " + new_name + "  "

func _on_sdfgi_toggled(_p: bool) -> void: _update_sdfgi_controls_state()
func _on_ssil_toggled(_p: bool) -> void: _update_ssil_controls_state()
func _on_ssao_toggled(_p: bool) -> void: _update_ssao_controls_state()
func _on_ssr_toggled(_p: bool) -> void: _update_ssr_controls_state()
func _on_fsr_toggled(_p: bool) -> void: _update_fsr_controls_state()

func _on_compat_toggled(pressed: bool) -> void: if pressed and _mobile_check: _mobile_check.button_pressed = false
func _on_mobile_toggled(pressed: bool) -> void: if pressed and _compat_check: _compat_check.button_pressed = false

func _on_quick_prints_toggled(pressed: bool) -> void: _set_show_prints(pressed)
func _on_custom_prints_toggled(pressed: bool) -> void: _set_show_prints(pressed)

func _set_show_prints(enabled: bool) -> void:
	_custom["show_prints"] = enabled; _save_custom_cfg()
	if _prints_check and _prints_check.button_pressed != enabled: _prints_check.button_pressed = enabled
	if _quick_prints_check and _quick_prints_check.button_pressed != enabled: _quick_prints_check.button_pressed = enabled

func _on_apply_custom_pressed() -> void:
	_collect_custom_from_ui(); _save_custom_cfg()
	ProjectSettings.set_setting(MODE_SETTING, "Custom"); ProjectSettings.save()
	var cfg := ConfigFile.new(); cfg.set_value("fr", "mode", "Custom"); cfg.save("user://fr_config.cfg")
	_refresh_mode_label()
	print("[FR Plugin] Custom mode applied: %s" % _custom.get("name", "Custom"))

func _on_reset_custom_pressed() -> void:
	_custom = CUSTOM_DEFAULTS.duplicate(); _save_custom_cfg(); _populate_ui_from_custom()
	print("[FR Plugin] Custom mode reset to defaults.")

func _on_export_pressed() -> void:
	_collect_custom_from_ui()
	var lines : Array[String] = ["# FR Custom Mode Export — " + _custom.get("name", "Custom"), "{"]
	for key in _custom:
		var val = _custom[key]
		if val is String: lines.append('\t"%s": "%s",' % [key, val])
		elif val is bool: lines.append('\t"%s": %s,' % [key, "true" if val else "false"])
		elif val is float: lines.append('\t"%s": %.4f,' % [key, val])
		else: lines.append('\t"%s": %s,' % [key, str(val)])
	lines.append("}")
	if _export_text: _export_text.text = "\n".join(lines)

func _on_import_pressed() -> void:
	if not _import_text: return
	var raw = _import_text.text.strip_edges()
	if raw.is_empty():
		_set_import_status("Nothing to import.", false); return
		
	var cleaned = "\n".join(Array(raw.split("\n")).filter(func(l): return not l.strip_edges().begins_with("#")))
	var expr = Expression.new()
	if expr.parse(cleaned) != OK:
		_set_import_status("Parse error.", false); return
	var result = expr.execute([], null, true)
	if expr.has_execute_failed() or typeof(result) != TYPE_DICTIONARY:
		_set_import_status("Invalid config format.", false); return

	var merged = 0
	for key in CUSTOM_DEFAULTS:
		if result.has(key):
			var expected = CUSTOM_DEFAULTS[key]; var incoming = result[key]
			if expected is float and incoming is int: incoming = float(incoming)
			elif expected is int and incoming is float: incoming = int(incoming)
			elif expected is bool and incoming is int: incoming = incoming != 0
			_custom[key] = incoming; merged += 1

	if merged == 0:
		_set_import_status("No recognisable keys found.", false); return

	_save_custom_cfg(); _populate_ui_from_custom()
	_set_import_status("✓ Imported (%d keys)" % merged, true)

func _set_import_status(msg: String, ok: bool) -> void:
	if _import_status_lbl:
		_import_status_lbl.text = msg
		_import_status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5) if ok else Color(1.0, 0.4, 0.4))

# ══════════════════════════════════════════════════════════════════════════════
# UI STATE BINDING
# ══════════════════════════════════════════════════════════════════════════════

func _update_sdfgi_controls_state() -> void:
	var on = _sdfgi_check and _sdfgi_check.button_pressed
	if _sdfgi_rays_opt: _sdfgi_rays_opt.disabled = not on
	if _sdfgi_conv_opt: _sdfgi_conv_opt.disabled = not on
	if _sdfgi_light_opt: _sdfgi_light_opt.disabled = not on

func _update_ssil_controls_state() -> void:
	var on = _ssil_check and _ssil_check.button_pressed
	if _ssil_min_opt: _ssil_min_opt.disabled = not on
	if _ssil_max_opt: _ssil_max_opt.disabled = not on

func _update_ssao_controls_state() -> void:
	var on = _ssao_check and _ssao_check.button_pressed
	if _ssao_min_opt: _ssao_min_opt.disabled = not on
	if _ssao_max_opt: _ssao_max_opt.disabled = not on

func _update_ssr_controls_state() -> void:
	var on = _ssr_check and _ssr_check.button_pressed
	if _ssr_min_opt: _ssr_min_opt.disabled = not on
	if _ssr_max_opt: _ssr_max_opt.disabled = not on

func _update_fsr_controls_state() -> void:
	var on = _fsr_check and _fsr_check.button_pressed
	if _fsr_scale_min_spin: _fsr_scale_min_spin.editable = on; _fsr_scale_min_spin.modulate = Color(1,1,1, 1.0 if on else 0.4)
	if _fsr_scale_max_spin: _fsr_scale_max_spin.editable = on; _fsr_scale_max_spin.modulate = Color(1,1,1, 1.0 if on else 0.4)

func _collect_custom_from_ui() -> void:
	if _name_edit: _custom["name"] = _name_edit.text
	if _res_min_spin: _custom["scale_min"] = _res_min_spin.value / 100.0
	if _res_max_spin: _custom["scale_max"] = _res_max_spin.value / 100.0
	if _shadow_min_opt: _custom["shadow_min"] = _idx_to_shadow(_shadow_min_opt.selected)
	if _shadow_max_opt: _custom["shadow_max"] = _idx_to_shadow(_shadow_max_opt.selected)
	if _sfilter_min_opt: _custom["shadow_filter_min"] = _sfilter_min_opt.selected
	if _sfilter_max_opt: _custom["shadow_filter_max"] = _sfilter_max_opt.selected
	if _fps_min_spin: _custom["fps_min"] = _fps_min_spin.value
	if _fps_max_spin: _custom["fps_max"] = _fps_max_spin.value
	if _tex_vp_opt: _custom["tex_viewport"] = _tex_vp_opt.selected
	if _aa_min_opt: _custom["aa_min"] = _aa_min_opt.selected
	if _aa_max_opt: _custom["aa_max"] = _aa_max_opt.selected; _custom["aa_mode"] = _aa_max_opt.selected
	if _vsync_opt: _custom["vsync_mode"] = _vsync_opt.selected
	if _fsr_check: _custom["fsr_enabled"] = _fsr_check.button_pressed
	if _fsr_scale_min_spin: _custom["fsr_scale_min"] = _fsr_scale_min_spin.value / 100.0
	if _fsr_scale_max_spin: _custom["fsr_scale_max"] = _fsr_scale_max_spin.value / 100.0
	if _sdfgi_check: _custom["sdfgi_enabled"] = _sdfgi_check.button_pressed
	if _sdfgi_rays_opt: _custom["sdfgi_rays"] = _sdfgi_rays_opt.selected
	if _sdfgi_conv_opt: _custom["sdfgi_converge"] = _sdfgi_conv_opt.selected
	if _sdfgi_light_opt: _custom["sdfgi_lights"] = _idx_to_sdfgi_lights(_sdfgi_light_opt.selected)
	if _ssil_check: _custom["ssil_enabled"] = _ssil_check.button_pressed
	if _ssil_max_opt: _custom["ssil_quality"] = _ssil_max_opt.selected
	if _ssao_check: _custom["ssao_enabled"] = _ssao_check.button_pressed
	if _ssao_max_opt: _custom["ssao_quality"] = _ssao_max_opt.selected
	if _ssr_check: _custom["ssr_enabled"] = _ssr_check.button_pressed
	if _ssr_max_opt: _custom["ssr_quality"] = _ssr_max_opt.selected
	if _lod_min_spin: _custom["lod_min"] = _lod_min_spin.value
	if _lod_max_spin: _custom["lod_max"] = _lod_max_spin.value; _custom["lod_threshold"] = (_custom.get("lod_min", 5.0) + _lod_max_spin.value) * 0.5
	if _smooth_spin: _custom["smooth_time"] = _smooth_spin.value
	if _compat_check: _custom["compatibility_mode"] = _compat_check.button_pressed
	if _mobile_check: _custom["mobile_mode"] = _mobile_check.button_pressed
	if _prints_check: _custom["show_prints"] = _prints_check.button_pressed
	_custom["tex_filter"] = _custom.get("tex_viewport", 1)

func _populate_ui_from_custom() -> void:
	if _name_edit: _name_edit.text = _custom.get("name", "Custom")
	if _res_min_spin: _res_min_spin.value = _custom.get("scale_min", 0.65) * 100.0
	if _res_max_spin: _res_max_spin.value = _custom.get("scale_max", 0.75) * 100.0
	if _shadow_min_opt: _shadow_min_opt.selected = _shadow_to_idx(_custom.get("shadow_min", 1024))
	if _shadow_max_opt: _shadow_max_opt.selected = _shadow_to_idx(_custom.get("shadow_max", 2048))
	if _sfilter_min_opt: _sfilter_min_opt.selected = clamp(_custom.get("shadow_filter_min", 0), 0, 2)
	if _sfilter_max_opt: _sfilter_max_opt.selected = clamp(_custom.get("shadow_filter_max", 1), 0, 2)
	if _fps_min_spin: _fps_min_spin.value = _custom.get("fps_min", 60.0)
	if _fps_max_spin: _fps_max_spin.value = _custom.get("fps_max", 144.0)
	if _tex_vp_opt: _tex_vp_opt.selected = clamp(_custom.get("tex_viewport", 1), 0, 1)
	if _aa_min_opt: _aa_min_opt.selected = clamp(_custom.get("aa_min", 0), 0, 2)
	if _aa_max_opt: _aa_max_opt.selected = clamp(_custom.get("aa_max", 1), 0, 2)
	if _vsync_opt: _vsync_opt.selected = clamp(_custom.get("vsync_mode", 0), 0, 3)
	if _fsr_check: _fsr_check.button_pressed = _custom.get("fsr_enabled", true)
	if _fsr_scale_min_spin: _fsr_scale_min_spin.value = _custom.get("fsr_scale_min", 0.50) * 100.0
	if _fsr_scale_max_spin: _fsr_scale_max_spin.value = _custom.get("fsr_scale_max", 0.75) * 100.0
	if _sdfgi_check: _sdfgi_check.button_pressed = _custom.get("sdfgi_enabled", false)
	if _sdfgi_rays_opt: _sdfgi_rays_opt.selected = clamp(_custom.get("sdfgi_rays", 0), 0, 3)
	if _sdfgi_conv_opt: _sdfgi_conv_opt.selected = clamp(_custom.get("sdfgi_converge", 0), 0, 5)
	if _sdfgi_light_opt: _sdfgi_light_opt.selected = _sdfgi_lights_to_idx(_custom.get("sdfgi_lights", 3))
	if _ssil_check: _ssil_check.button_pressed = _custom.get("ssil_enabled", false)
	if _ssil_max_opt: _ssil_max_opt.selected = clamp(_custom.get("ssil_quality", 0), 0, 4)
	if _ssao_check: _ssao_check.button_pressed = _custom.get("ssao_enabled", false)
	if _ssao_max_opt: _ssao_max_opt.selected = clamp(_custom.get("ssao_quality", 0), 0, 4)
	if _ssr_check: _ssr_check.button_pressed = _custom.get("ssr_enabled", false)
	if _ssr_max_opt: _ssr_max_opt.selected = clamp(_custom.get("ssr_quality", 0), 0, 4)
	if _lod_min_spin: _lod_min_spin.value = _custom.get("lod_min", 5.0)
	if _lod_max_spin: _lod_max_spin.value = _custom.get("lod_max", 15.0)
	if _smooth_spin: _smooth_spin.value = _custom.get("smooth_time", 1.5)
	if _compat_check: _compat_check.button_pressed = _custom.get("compatibility_mode", false)
	if _mobile_check: _mobile_check.button_pressed = _custom.get("mobile_mode", false)
	if _prints_check: _prints_check.button_pressed = _custom.get("show_prints", true)
	if _quick_prints_check: _quick_prints_check.button_pressed = _custom.get("show_prints", true)
	_update_sdfgi_controls_state(); _update_ssil_controls_state(); _update_ssao_controls_state(); _update_ssr_controls_state(); _update_fsr_controls_state()

func _refresh_mode_label() -> void:
	if not _current_mode_lbl: return
	var mode := ProjectSettings.get_setting(MODE_SETTING, "Balanced") as String
	var display : String = mode
	if mode == "Custom": display = _custom.get("name", "Custom")
	_current_mode_lbl.text = "Active Profile: [ " + display + " ]"
