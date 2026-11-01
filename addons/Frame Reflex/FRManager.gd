extends Node

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  FRManager — Adaptive Frame Rate & Quality Manager                           ║
# ║  Now with full Custom Mode support                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Rendering constants ────────────────────────────────────────────────────────
const FSR_OFF := Viewport.SCALING_3D_MODE_BILINEAR
const FSR1    := Viewport.SCALING_3D_MODE_FSR
const AA_OFF  := Viewport.MSAA_DISABLED

const SHADOW_LOW  : int = 512
const SHADOW_MID  : int = 1024
const SHADOW_HIGH : int = 2048

const SHADOW_FILTER_LOW  : int = 0
const SHADOW_FILTER_MID  : int = 1
const SHADOW_FILTER_HIGH : int = 1

# ── FPS thresholds ─────────────────────────────────────────────────────────────
const FPS_MINIMUM  : float = 100.0
const FPS_HIGH     : float = 200.0
const HYSTERESIS   : float = 5.0
const FRAMETIME_STUTTER_THRESHOLD_MS : float = 4.0
const FRAMETIME_TARGET_MS            : float = 11.1

# ── Adaptive scale ─────────────────────────────────────────────────────────────
const SCALE_STEP        : float = 0.025
const RECOVERY_COOLDOWN : float = 3.0
const CHECK_INTERVAL    : float = 1.0
const BASELINE_LERP     : float = 0.08
const WARMUP_DURATION   : float = 4.0

# ── FSR / AA dynamic control ───────────────────────────────────────────────────
const FSR_AA_ON_MARGIN  : float = 100.0
const FSR_AA_OFF_MARGIN : float = 50.0
const FSR_AA_LOCK_TIME  : float = 4.0

# ── Profile switch hysteresis ──────────────────────────────────────────────────
const PROFILE_SWITCH_COOLDOWN : float = 0.3

# ── Shadow hysteresis ─────────────────────────────────────────────────────────
const SHADOW_HYSTERESIS_CHECKS : int = 3

# ── Thermal throttle detection ─────────────────────────────────────────────────
const THERMAL_DRIFT_FRACTION : float = 0.20
const THERMAL_WINDOW         : float = 60.0
const THERMAL_CHECK_INTERVAL : float = 10.0
const MAX_THERMAL_SAMPLES    : int   = 60

# ── Background / benchmark ─────────────────────────────────────────────────────
const BG_FPS_CAP                : int   = 30
const DRAW_CALL_HIGH_THRESHOLD  : int   = 2000
const DRAW_CALL_LOW_THRESHOLD   : int   = 1200
const BENCHMARK_SAMPLE_DURATION : float = 2.0

# ── Project settings keys ──────────────────────────────────────────────────────
const LOD_SETTING              := "rendering/mesh_lod/lod_change/threshold_pixels"
const SHADOW_FILTER_SETTING    := "rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality"
const SSAO_SETTING             := "rendering/environment/ssao/quality"
const SSIL_SETTING             := "rendering/environment/ssil/quality"
const TEX_FILTER_SETTING       := "rendering/textures/default_filters/anisotropic_filtering_level"
const SDFGI_PROBE_RAYS_SETTING := "rendering/global_illumination/sdfgi/probe_ray_count"
const SDFGI_FRAMES_CONVERGE    := "rendering/global_illumination/sdfgi/frames_to_converge"
const SDFGI_FRAMES_UPDATE      := "rendering/global_illumination/sdfgi/frames_to_update_lights"
const CONFIG_PATH              := "user://fr_config.cfg"
const CUSTOM_CONFIG_PATH       := "user://fr_custom_mode.cfg"

const SDFGI_RAYS_LOW      : int = 0
const SDFGI_RAYS_MID      : int = 1
const SDFGI_RAYS_HIGH     : int = 3
const SDFGI_CONVERGE_LOW  : int = 0
const SDFGI_CONVERGE_MID  : int = 2
const SDFGI_CONVERGE_HIGH : int = 5
const SDFGI_LIGHT_LOW     : int = 3
const SDFGI_LIGHT_MID     : int = 2
const SDFGI_LIGHT_HIGH    : int = 1

# ── Built-in mode profiles ─────────────────────────────────────────────────────
const PROFILES := {
	"Performance" : {
		"scale_min": 0.60, "scale_max": 0.70, "lod_threshold": 15.0,
		"ssao_quality": 0, "ssil_quality": 0, "tex_filter": 0,
		"sdfgi_rays": SDFGI_RAYS_LOW, "sdfgi_converge": SDFGI_CONVERGE_LOW,
		"sdfgi_lights": SDFGI_LIGHT_LOW,
		"shadow_min": SHADOW_LOW,  "shadow_max": SHADOW_MID,
		"fps_min": 60.0, "fps_max": 120.0,
		"aa_mode": 0, "tex_viewport": 0,
		"ssao_enabled": false, "ssil_enabled": false,
		"sdfgi_enabled": false, "ssr_enabled": false,
		"smooth_time": 1.0,
	},
	"Balanced"    : {
		"scale_min": 0.65, "scale_max": 0.75, "lod_threshold": 15.0,
		"ssao_quality": 0, "ssil_quality": 0, "tex_filter": 1,
		"sdfgi_rays": SDFGI_RAYS_LOW, "sdfgi_converge": SDFGI_CONVERGE_LOW,
		"sdfgi_lights": SDFGI_LIGHT_LOW,
		"shadow_min": SHADOW_MID,  "shadow_max": SHADOW_MID,
		"fps_min": 60.0, "fps_max": 144.0,
		"aa_mode": 1, "tex_viewport": 1,
		"ssao_enabled": false, "ssil_enabled": false,
		"sdfgi_enabled": false, "ssr_enabled": false,
		"smooth_time": 1.5,
	},
	"Quality"     : {
		"scale_min": 0.75, "scale_max": 0.80, "lod_threshold": 10.0,
		"ssao_quality": 1, "ssil_quality": 1, "tex_filter": 1,
		"sdfgi_rays": SDFGI_RAYS_LOW, "sdfgi_converge": SDFGI_CONVERGE_LOW,
		"sdfgi_lights": SDFGI_LIGHT_MID,
		"shadow_min": SHADOW_MID,  "shadow_max": SHADOW_HIGH,
		"fps_min": 60.0, "fps_max": 240.0,
		"aa_mode": 1, "tex_viewport": 1,
		"ssao_enabled": true, "ssil_enabled": true,
		"sdfgi_enabled": false, "ssr_enabled": false,
		"smooth_time": 2.0,
	},
}

const SCENE_HINT_OFFSETS := {
	"light"  : { "scale_delta":  0.05, "lod_delta": -3.0 },
	"normal" : { "scale_delta":  0.0,  "lod_delta":  0.0 },
	"heavy"  : { "scale_delta": -0.05, "lod_delta":  3.0 },
}

# ── Default custom mode values ─────────────────────────────────────────────────
const CUSTOM_MODE_DEFAULTS := {
	"name":             "Custom",
	"scale_min":        0.65,
	"scale_max":        0.75,
	"shadow_min":       SHADOW_MID,
	"shadow_max":       SHADOW_HIGH,
	"shadow_filter_min": SHADOW_FILTER_LOW,
	"shadow_filter_max": SHADOW_FILTER_HIGH,
	"fps_min":          60.0,
	"fps_max":          144.0,
	"tex_viewport":     1,
	"aa_mode":          1,
	"aa_min":           0,
	"aa_max":           1,
	"sdfgi_enabled":    false,
	"sdfgi_rays":       SDFGI_RAYS_LOW,
	"sdfgi_converge":   SDFGI_CONVERGE_LOW,
	"sdfgi_lights":     SDFGI_LIGHT_LOW,
	"ssil_enabled":     false,
	"ssil_quality":     0,
	"ssao_enabled":     false,
	"ssao_quality":     0,
	"ssr_enabled":      false,
	"ssr_quality":      0,
	"lod_min":          5.0,
	"lod_max":          15.0,
	"lod_threshold":    10.0,
	"smooth_time":      1.5,
	"compatibility_mode": false,
	"mobile_mode":      false,
	"show_prints":      true,
	"tex_filter":       1,
	"fsr_enabled":      true,
	"fsr_scale_min":    0.50,
	"fsr_scale_max":    0.75,
	"vsync_mode":       0, # 0=Off 1=On 2=Adaptive 3=Mailbox — only used in Custom mode
}

# ── Signals ────────────────────────────────────────────────────────────────────
signal profile_changed(new_mode: String)
signal scale_changed(new_scale: float)
signal benchmark_done(results: Dictionary)
signal custom_mode_saved(config: Dictionary)

# ── Core state ─────────────────────────────────────────────────────────────────
var _enabled               : bool       = true
var _mode                  : String     = "Balanced"
var _profile                : Dictionary = {}
var _scene_hint            : String     = "normal"
var _baseline_fps          : float      = 0.0
var _current_scale         : float      = 0.0
var _current_shadow        : int        = SHADOW_MID
var _current_shadow_filter : int        = SHADOW_FILTER_MID

# ── Custom mode state ──────────────────────────────────────────────────────────
var _custom_config : Dictionary = {}

# ── Accumulators ──────────────────────────────────────────────────────────────
var _fps_accum      : float = 0.0
var _fps_count      : int   = 0
var _ft_accum       : float = 0.0
var _ft_sq_accum    : float = 0.0
var _ft_max         : float = 0.0

# ── Warmup accumulators ────────────────────────────────────────────────────────
var _warmup_fps_accum : float = 0.0
var _warmup_fps_count : int   = 0

# ── Timers ─────────────────────────────────────────────────────────────────────
var _check_timer          : float = 0.0
var _recovery_timer       : float = 0.0
var _warmup_done          : bool  = false
var _warmup_timer         : float = 0.0
var _profile_switch_timer : float = 0.0
var _fsr_aa_lock_timer    : float = 0.0
var _thermal_check_timer  : float = 0.0

# ── Flags ──────────────────────────────────────────────────────────────────────
var _low_fps             : bool   = false
var _fsr_aa_enabled      : bool   = false
var _is_in_background    : bool   = false
var _pending_mode        : String = ""
var _config_save_pending : bool   = false
var _fxaa_locked_off     : bool   = false

# ── Shadow hysteresis state ────────────────────────────────────────────────────
var _shadow_desired           : int = SHADOW_MID
var _shadow_consecutive_count : int = 0

# ── Thermal ────────────────────────────────────────────────────────────────────
var _thermal_samples      : Array[float] = []
var _thermal_baseline_fps : float        = 0.0
var _thermal_triggered    : bool         = false

# ── Benchmark ─────────────────────────────────────────────────────────────────
var _benchmarking      : bool          = false
var _benchmark_step    : int           = 0
var _benchmark_timer   : float         = 0.0
var _benchmark_accum   : float         = 0.0
var _benchmark_count   : int           = 0
var _benchmark_results : Dictionary    = {}
var _benchmark_steps   : Array[String] = ["Performance", "Balanced", "Quality"]

# ── Debug overlay ──────────────────────────────────────────────────────────────
var _debug_overlay_enabled : bool        = false
var _debug_canvas          : CanvasLayer = null
var _debug_label           : Label       = null

# ── Cached stats ──────────────────────────────────────────────────────────────
var _last_ft_stats       : Dictionary = {}
var _cached_desired_mode : String     = "Balanced"

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load_custom_config()
	_load_config()
	_cached_desired_mode = ProjectSettings.get_setting("fr/mode", "Balanced") as String
	_load_mode(_cached_desired_mode)
	if Engine.is_editor_hint():
		return
	Engine.max_fps = 0
	# Vsync is intentionally left untouched here — the player's own setting
	# (project default or their in-game options) is respected. Only Custom
	# mode is allowed to override it, via _apply_vsync().
	_connect_window_signals()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _enabled:
		return

	var all_modes : bool = PROFILES.has(_cached_desired_mode) or _cached_desired_mode == "Custom"
	if _cached_desired_mode != _mode and all_modes and not _config_save_pending:
		_config_save_pending = true
		_schedule_mode(_cached_desired_mode)
		_save_config(_cached_desired_mode)

	# ── Timers ──────────────────────────────────────────────────────────────
	_check_timer          += delta
	_recovery_timer       += delta
	_fsr_aa_lock_timer     = maxf(_fsr_aa_lock_timer - delta, 0.0)
	_thermal_check_timer  += delta

	# ── Profile switch deferred ──────────────────────────────────────────────
	if _profile_switch_timer > 0.0:
		_profile_switch_timer -= delta
		if _profile_switch_timer <= 0.0 and _pending_mode != "":
			_do_load_mode(_pending_mode)
			_pending_mode        = ""
			_config_save_pending = false

	# ── Warmup ──────────────────────────────────────────────────────────────
	if not _warmup_done:
		_warmup_timer     += delta
		_warmup_fps_accum += float(Engine.get_frames_per_second())
		_warmup_fps_count += 1
		if _warmup_timer >= WARMUP_DURATION:
			_warmup_done = true
			if _warmup_fps_count > 0:
				_baseline_fps         = _warmup_fps_accum / float(_warmup_fps_count)
				_thermal_baseline_fps = _baseline_fps
			_warmup_fps_accum = 0.0
			_warmup_fps_count = 0
			_fps_accum        = 0.0
			_fps_count        = 0
			_ft_accum         = 0.0
			_ft_sq_accum      = 0.0
			_ft_max           = 0.0
			_check_timer      = 0.0
			_fr_print("Warmup done — baseline %.1f fps" % _baseline_fps)
		return

	# ── Benchmark mode ───────────────────────────────────────────────────────
	if _benchmarking:
		_benchmark_timer += delta
		_benchmark_accum += float(Engine.get_frames_per_second())
		_benchmark_count += 1
		if _benchmark_timer >= BENCHMARK_SAMPLE_DURATION:
			_advance_benchmark_step()
		return

	# ── Accumulate per-frame data ────────────────────────────────────────────
	var current_fps : float = float(Engine.get_frames_per_second())
	var ft_ms       : float = delta * 1000.0
	_fps_accum   += current_fps
	_fps_count   += 1
	_ft_accum    += ft_ms
	_ft_sq_accum += ft_ms * ft_ms
	_ft_max       = maxf(_ft_max, ft_ms)

	if _debug_overlay_enabled and _debug_label != null:
		_update_debug_overlay(current_fps, ft_ms)

	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0

	_check_thermal()
	_evaluate()

# ══════════════════════════════════════════════════════════════════════════════
# PRINT HELPER — respects show_prints in custom mode
# ══════════════════════════════════════════════════════════════════════════════

func _fr_print(msg: String) -> void:
	# show_prints is a global toggle — it applies in every mode
	# (Performance / Balanced / Quality / Custom), not just Custom mode.
	if _custom_config.get("show_prints", true):
		print("[FR] " + msg)

# ══════════════════════════════════════════════════════════════════════════════
# DEBUG OVERLAY UPDATE
# ══════════════════════════════════════════════════════════════════════════════

func _update_debug_overlay(current_fps: float, ft_ms: float) -> void:
	if _debug_label == null:
		return
	var s := _last_ft_stats
	var mode_display : String = _mode
	if _mode == "Custom":
		mode_display = _custom_config.get("name", "Custom")
	_debug_label.text = (
		"[FRManager]\n"
		+ "Mode    : %s\n"      % mode_display
		+ "Scale   : %s\n"      % get_scale()
		+ "FPS     : %.0f\n"    % current_fps
		+ "FT      : %.2f ms\n" % ft_ms
		+ "Avg FPS : %.1f\n"    % s.get("avg_fps", 0.0)
		+ "StdDev  : %.2f ms\n" % s.get("stddev",  0.0)
		+ "P99     : %.2f ms\n" % s.get("p99",     0.0)
		+ "Shadow  : %s\n"      % get_shadow()
		+ "ShdFltr : %s\n"      % get_shadow_filter()
		+ "FSR     : %s\n"      % get_fsr()
		+ "AA      : %s\n"      % get_aa()
		+ "VSync   : %s\n"      % get_vsync_mode()
		+ "Thermal : %s\n"      % get_thermal_state()
		+ "Hint    : %s\n"      % _scene_hint
		+ "Baseline: %.1f\n"    % _baseline_fps
		+ "Recovery: %.1f s"    % _recovery_timer
	)

# ══════════════════════════════════════════════════════════════════════════════
# FRAME-TIME STATS
# ══════════════════════════════════════════════════════════════════════════════

func _consume_frametime_stats() -> Dictionary:
	if _fps_count == 0:
		return { "avg_fps": 0.0, "avg_ft": 0.0, "stddev": 0.0, "p99": 0.0 }

	var n        : int   = _fps_count
	var avg_fps  : float = _fps_accum / float(n)
	var avg_ft   : float = _ft_accum  / float(n)
	var variance : float = maxf((_ft_sq_accum / float(n)) - (avg_ft * avg_ft), 0.0)
	var stddev   : float = sqrt(variance)
	var p99      : float = _ft_max

	_fps_accum   = 0.0
	_fps_count   = 0
	_ft_accum    = 0.0
	_ft_sq_accum = 0.0
	_ft_max      = 0.0

	return { "avg_fps": avg_fps, "avg_ft": avg_ft, "stddev": stddev, "p99": p99 }

# ══════════════════════════════════════════════════════════════════════════════
# THERMAL THROTTLE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

func _check_thermal() -> void:
	if _fps_count > 0:
		_thermal_samples.append(_fps_accum / float(_fps_count))

	if _thermal_check_timer < THERMAL_CHECK_INTERVAL:
		return
	_thermal_check_timer = 0.0

	while _thermal_samples.size() > MAX_THERMAL_SAMPLES:
		_thermal_samples.pop_front()

	if _thermal_samples.size() < 6:
		return

	var sum : float = 0.0
	for v in _thermal_samples:
		sum += v
	var rolling_avg : float = sum / float(_thermal_samples.size())

	if _thermal_baseline_fps <= 0.0:
		_thermal_baseline_fps = rolling_avg
		return

	var drift : float = (_thermal_baseline_fps - rolling_avg) / _thermal_baseline_fps
	if drift >= THERMAL_DRIFT_FRACTION and not _thermal_triggered:
		_thermal_triggered = true
		_fr_print("Thermal throttle suspected — %.0f%% drift. Stepping down." % (drift * 100.0))
		_step_down_profile()
	elif drift < THERMAL_DRIFT_FRACTION * 0.5 and _thermal_triggered:
		_thermal_triggered = false
		_fr_print("Thermal pressure eased.")


func _step_down_profile() -> void:
	match _mode:
		"Quality"  : _schedule_mode("Balanced")
		"Balanced" : _schedule_mode("Performance")
		"Custom"   :
			var cur_min : float = _custom_config.get("scale_min", 0.65)
			if cur_min > 0.45:
				_custom_config["scale_min"] = maxf(cur_min - SCALE_STEP * 2.0, 0.45)
				_profile = _custom_config.duplicate()
				_fr_print("Custom thermal step-down: scale_min %.2f" % _custom_config["scale_min"])

# ══════════════════════════════════════════════════════════════════════════════
# DYNAMIC FSR / AA
# ══════════════════════════════════════════════════════════════════════════════

func _apply_screen_aa(vp: Viewport) -> void:
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED if _fxaa_locked_off \
		else Viewport.SCREEN_SPACE_AA_FXAA


func _update_fsr_aa(avg: float) -> void:
	if _fsr_aa_lock_timer > 0.0 or _low_fps:
		return
	# Custom mode: FSR disabled entirely when fsr_enabled = false
	if _mode == "Custom" and not _custom_config.get("fsr_enabled", true):
		if _fsr_aa_enabled:
			_set_fsr_aa(false)
		return
	var margin : float = avg - _get_fps_minimum()
	if _fsr_aa_enabled and margin < FSR_AA_OFF_MARGIN:
		_set_fsr_aa(false)
	elif not _fsr_aa_enabled and margin >= FSR_AA_ON_MARGIN:
		_set_fsr_aa(true)


func _set_fsr_aa(enabled: bool) -> void:
	if _fsr_aa_enabled == enabled:
		return
	_fsr_aa_enabled    = enabled
	_fsr_aa_lock_timer = FSR_AA_LOCK_TIME
	var vp := get_viewport()
	if vp == null:
		return
	vp.scaling_3d_scale = _current_scale
	if enabled:
		vp.scaling_3d_mode = FSR1
		vp.use_taa         = false
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_fr_print("FSR on")
	else:
		vp.scaling_3d_mode = FSR_OFF
		vp.use_taa         = false
		_apply_screen_aa(vp)
		_fr_print("FSR off → FXAA")

# ══════════════════════════════════════════════════════════════════════════════
# FPS HELPERS — custom-mode aware
# ══════════════════════════════════════════════════════════════════════════════

func _get_fps_minimum() -> float:
	if _mode == "Custom":
		return _custom_config.get("fps_min", FPS_MINIMUM)
	return FPS_MINIMUM


func _get_fps_high() -> float:
	if _mode == "Custom":
		return _custom_config.get("fps_max", FPS_HIGH)
	return FPS_HIGH


func _get_smooth_time() -> float:
	return _profile.get("smooth_time", 1.0)

# ══════════════════════════════════════════════════════════════════════════════
# EVALUATE
# ══════════════════════════════════════════════════════════════════════════════

func _evaluate() -> void:
	var stats : Dictionary = _consume_frametime_stats()
	var avg   : float      = stats["avg_fps"]
	if avg <= 0.0:
		return

	_last_ft_stats = stats

	_evaluate_shadow(_fps_to_shadow(avg))
	_update_fsr_aa(avg)

	var fps_min    : float = _get_fps_minimum()
	var stuttering : bool  = stats.get("stddev", 0.0) > FRAMETIME_STUTTER_THRESHOLD_MS

	if avg < fps_min or stuttering:
		_recovery_timer  = 0.0
		if not _low_fps:
			_low_fps         = true
			_fxaa_locked_off = true
			var vp := get_viewport()
			if vp:
				vp.scaling_3d_mode  = FSR_OFF
				vp.scaling_3d_scale = _current_scale
				vp.msaa_3d          = AA_OFF
				vp.use_taa          = false
				vp.screen_space_aa  = Viewport.SCREEN_SPACE_AA_DISABLED
		_apply_scale(maxf(_current_scale - SCALE_STEP, _effective_scale_min()))
	else:
		if _low_fps:
			_low_fps           = false
			_fsr_aa_lock_timer = 0.0
			_update_fsr_aa(avg)
		if avg >= fps_min + HYSTERESIS and _recovery_timer >= RECOVERY_COOLDOWN:
			_apply_scale(minf(_current_scale + SCALE_STEP, _effective_scale_max()))
		elif avg < fps_min + HYSTERESIS:
			_apply_scale(maxf(_current_scale - SCALE_STEP, _effective_scale_min()))

	_baseline_fps = lerpf(_baseline_fps, avg, BASELINE_LERP)

# ── Shadow hysteresis guard ────────────────────────────────────────────────────

func _evaluate_shadow(desired: int) -> void:
	if desired == _shadow_desired:
		_shadow_consecutive_count += 1
		if _shadow_consecutive_count >= SHADOW_HYSTERESIS_CHECKS:
			_apply_shadow(desired)
	else:
		_shadow_desired           = desired
		_shadow_consecutive_count = 1


func _effective_scale_min() -> float:
	var d : float = SCENE_HINT_OFFSETS.get(_scene_hint, {}).get("scale_delta", 0.0)
	return clampf(_profile.get("scale_min", 0.60) + d, 0.40, 1.0)


func _effective_scale_max() -> float:
	var d : float = SCENE_HINT_OFFSETS.get(_scene_hint, {}).get("scale_delta", 0.0)
	return clampf(_profile.get("scale_max", 0.70) + d, 0.40, 1.0)

# ══════════════════════════════════════════════════════════════════════════════
# BENCHMARK
# ══════════════════════════════════════════════════════════════════════════════

func _advance_benchmark_step() -> void:
	if _benchmark_step > 0 and _benchmark_step <= _benchmark_steps.size() and _benchmark_count > 0:
		var step_avg : float = _benchmark_accum / float(_benchmark_count)
		_benchmark_results[_benchmark_steps[_benchmark_step - 1]] = step_avg
		_fr_print("Benchmark %s: %.1f fps" % [_benchmark_steps[_benchmark_step - 1], step_avg])

	_benchmark_accum = 0.0
	_benchmark_count = 0
	_benchmark_timer = 0.0

	if _benchmark_step >= _benchmark_steps.size():
		_benchmarking = false
		var best_mode : String = "Balanced"
		var best_fps  : float  = 0.0
		for bmode in _benchmark_results:
			if _benchmark_results[bmode] > FPS_MINIMUM and _benchmark_results[bmode] > best_fps:
				best_fps  = _benchmark_results[bmode]
				best_mode = bmode
		_fr_print("Benchmark done. Best: %s (%.1f fps)" % [best_mode, best_fps])
		_save_config(best_mode)
		_schedule_mode(best_mode)
		emit_signal("benchmark_done", _benchmark_results.duplicate())
		return

	var next_mode : String = _benchmark_steps[_benchmark_step]
	_benchmark_step += 1
	_do_load_mode(next_mode)
	_fr_print("Benchmark step %d/%d: %s" % [_benchmark_step, _benchmark_steps.size(), next_mode])

# ══════════════════════════════════════════════════════════════════════════════
# BACKGROUND / FOREGROUND
# ══════════════════════════════════════════════════════════════════════════════

func _connect_window_signals() -> void:
	var win := get_window()
	if win == null:
		return
	if not win.focus_exited.is_connected(_on_focus_lost):
		win.focus_exited.connect(_on_focus_lost)
	if not win.focus_entered.is_connected(_on_focus_gained):
		win.focus_entered.connect(_on_focus_gained)


func _on_focus_lost() -> void:
	if _is_in_background:
		return
	_is_in_background = true
	Engine.max_fps    = BG_FPS_CAP
	_fr_print("Backgrounded — cap %d fps" % BG_FPS_CAP)


func _on_focus_gained() -> void:
	if not _is_in_background:
		return
	_is_in_background = false
	Engine.max_fps    = 0
	_warmup_done      = false
	_warmup_timer     = 0.0
	_warmup_fps_accum = 0.0
	_warmup_fps_count = 0
	_fps_accum        = 0.0
	_fps_count        = 0
	_ft_accum         = 0.0
	_ft_sq_accum      = 0.0
	_ft_max           = 0.0
	_check_timer      = 0.0
	_fr_print("Foregrounded — uncapped, re-warmup")

# ══════════════════════════════════════════════════════════════════════════════
# CONFIG PERSISTENCE
# ══════════════════════════════════════════════════════════════════════════════

func _save_config(mode: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("fr", "mode", mode)
	cfg.save(CONFIG_PATH)
	ProjectSettings.set_setting("fr/mode", mode)
	_cached_desired_mode = mode


func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var saved : String = cfg.get_value("fr", "mode", "Balanced") as String
		if PROFILES.has(saved) or saved == "Custom":
			ProjectSettings.set_setting("fr/mode", saved)
			_cached_desired_mode = saved
			_fr_print("Loaded profile: %s" % saved)

# ── Custom mode config ─────────────────────────────────────────────────────────

func _save_custom_config() -> void:
	var cfg := ConfigFile.new()
	for key in _custom_config:
		cfg.set_value("custom", key, _custom_config[key])
	cfg.save(CUSTOM_CONFIG_PATH)
	_fr_print("Custom mode saved: %s" % _custom_config.get("name", "Custom"))
	emit_signal("custom_mode_saved", _custom_config.duplicate())


func _load_custom_config() -> void:
	_custom_config = {}
	for key in CUSTOM_MODE_DEFAULTS:
		_custom_config[key] = CUSTOM_MODE_DEFAULTS[key]

	var cfg := ConfigFile.new()
	if cfg.load(CUSTOM_CONFIG_PATH) == OK:
		for key in CUSTOM_MODE_DEFAULTS:
			if cfg.has_section_key("custom", key):
				_custom_config[key] = cfg.get_value("custom", key)
		_fr_print("Custom mode loaded: %s" % _custom_config.get("name", "Custom"))

# ══════════════════════════════════════════════════════════════════════════════
# DEBUG OVERLAY — BUILD / REMOVE
# ══════════════════════════════════════════════════════════════════════════════

func _build_debug_overlay() -> void:
	_debug_canvas       = CanvasLayer.new()
	_debug_canvas.layer = 100
	add_child(_debug_canvas)
	var panel      := Panel.new()
	panel.position  = Vector2(10, 10)
	panel.size      = Vector2(310, 280)
	panel.modulate  = Color(1, 1, 1, 0.82)
	_debug_canvas.add_child(panel)
	_debug_label          = Label.new()
	_debug_label.position = Vector2(14, 10)
	_debug_label.size     = Vector2(290, 265)
	_debug_label.add_theme_font_size_override("font_size", 13)
	_debug_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.85))
	panel.add_child(_debug_label)


func _remove_debug_overlay() -> void:
	if _debug_canvas:
		_debug_canvas.queue_free()
		_debug_canvas = null
		_debug_label  = null

# ══════════════════════════════════════════════════════════════════════════════
# RENDERING HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _fps_to_shadow(fps: float) -> int:
	var s_min : int = _profile.get("shadow_min", SHADOW_LOW)
	var s_max : int = _profile.get("shadow_max", SHADOW_HIGH)
	var fp_high : float = _get_fps_high()
	var fp_min  : float = _get_fps_minimum()
	if fps >= fp_high:   return s_max
	elif fps >= fp_min:  return s_min + (s_max - s_min) / 2
	else:                return s_min


func _shadow_to_filter(size: int) -> int:
	if _mode == "Custom":
		var f_min : int = _custom_config.get("shadow_filter_min", SHADOW_FILTER_LOW)
		var f_max : int = _custom_config.get("shadow_filter_max", SHADOW_FILTER_HIGH)
		return f_max if size >= _profile.get("shadow_max", SHADOW_HIGH) else f_min
	return SHADOW_FILTER_HIGH if size == SHADOW_HIGH else (SHADOW_FILTER_MID if size == SHADOW_MID else SHADOW_FILTER_LOW)


func _apply_shadow(size: int) -> void:
	if _current_shadow == size:
		return
	_current_shadow = size
	var vp := get_viewport()
	if vp == null:
		return
	vp.positional_shadow_atlas_size = size
	RenderingServer.directional_shadow_atlas_set_size(size, true)
	_apply_shadow_filter(_shadow_to_filter(size))


func _apply_shadow_filter(quality: int) -> void:
	if _current_shadow_filter == quality:
		return
	_current_shadow_filter = quality
	ProjectSettings.set_setting(SHADOW_FILTER_SETTING, quality)


func _apply_scale(scale: float) -> void:
	if _current_scale == scale:
		return
	_current_scale = scale
	emit_signal("scale_changed", scale)
	var vp := get_viewport()
	if vp == null:
		return
	# In Custom mode, clamp the rendering scale to the FSR min/max window
	var final_scale : float = scale
	if _mode == "Custom":
		var fsr_on  : bool  = _custom_config.get("fsr_enabled", true)
		var fsr_min : float = _custom_config.get("fsr_scale_min", 0.50)
		var fsr_max : float = _custom_config.get("fsr_scale_max", 0.75)
		final_scale = clampf(scale, fsr_min, fsr_max) if fsr_on else scale
	vp.scaling_3d_scale = final_scale
	vp.scaling_3d_mode  = FSR1 if (_fsr_aa_enabled and not _low_fps) else FSR_OFF


func _apply_lod() -> void:
	if _profile.is_empty():
		return
	var threshold : float = _profile.get("lod_threshold", 10.0) \
		+ SCENE_HINT_OFFSETS.get(_scene_hint, {}).get("lod_delta", 0.0)
	if _mode == "Custom":
		var lod_min : float = _custom_config.get("lod_min", 5.0)
		var lod_max : float = _custom_config.get("lod_max", 15.0)
		threshold = clampf(threshold, lod_min, lod_max)
	ProjectSettings.set_setting(LOD_SETTING, threshold)
	var vp := get_viewport()
	if vp:
		vp.mesh_lod_threshold = threshold


func _apply_effects() -> void:
	if _profile.is_empty():
		return

	# ── Compatibility / Mobile override — disables heavy GI effects ───────────
	var compat : bool = _profile.get("compatibility_mode", false)
	var mobile : bool = _profile.get("mobile_mode", false)
	var force_off : bool = compat or mobile

	# SSAO
	var ssao_on  : bool = _profile.get("ssao_enabled", false) and not force_off
	var ssao_q   : int  = _profile.get("ssao_quality", 0) if ssao_on else 0
	ProjectSettings.set_setting(SSAO_SETTING, ssao_q)

	# SSIL
	var ssil_on  : bool = _profile.get("ssil_enabled", false) and not force_off
	var ssil_q   : int  = _profile.get("ssil_quality", 0) if ssil_on else 0
	ProjectSettings.set_setting(SSIL_SETTING, ssil_q)

	# SDFGI — disable rays when off
	var sdfgi_on : bool = _profile.get("sdfgi_enabled", false) and not force_off
	ProjectSettings.set_setting(SDFGI_PROBE_RAYS_SETTING,
		_profile.get("sdfgi_rays", SDFGI_RAYS_LOW) if sdfgi_on else SDFGI_RAYS_LOW)
	ProjectSettings.set_setting(SDFGI_FRAMES_CONVERGE,
		_profile.get("sdfgi_converge", SDFGI_CONVERGE_LOW) if sdfgi_on else SDFGI_CONVERGE_LOW)
	ProjectSettings.set_setting(SDFGI_FRAMES_UPDATE,
		_profile.get("sdfgi_lights", SDFGI_LIGHT_LOW) if sdfgi_on else SDFGI_LIGHT_LOW)

	# Texture filter / anisotropic
	ProjectSettings.set_setting(TEX_FILTER_SETTING, _profile.get("tex_filter", 0))

	# Viewport texture filter (nearest / linear)
	var vp := get_viewport()
	if vp:
		var tex_vp : int = _profile.get("tex_viewport", 1)
		if tex_vp == 0:
			vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		else:
			vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

	# AA mode — 0 = off, 1 = FXAA, 2 = TAA
	var aa_mode : int = _profile.get("aa_mode", 1)
	if vp:
		match aa_mode:
			0:
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
				vp.use_taa         = false
			1:
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if not _fxaa_locked_off \
					else Viewport.SCREEN_SPACE_AA_DISABLED
				vp.use_taa         = false
			2:
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
				vp.use_taa         = true


func _apply_custom_ssr() -> void:
	# SSR quality is a project-setting integer 0-4.
	# It only applies to the current Environment resource, but we mirror it
	# to a project setting that custom shaders / WorldEnvironment can read.
	if _mode != "Custom":
		return
	var ssr_on : bool = _custom_config.get("ssr_enabled", false)
	var compat : bool = _custom_config.get("compatibility_mode", false)
	var mobile : bool = _custom_config.get("mobile_mode", false)
	var q      : int  = _custom_config.get("ssr_quality", 0) if (ssr_on and not compat and not mobile) else 0
	ProjectSettings.set_setting("rendering/environment/screen_space_reflection/roughness_quality", q)


func _apply_vsync() -> void:
	# Only Custom mode is allowed to touch vsync. Performance / Balanced /
	# Quality never call this — the player's own vsync setting (project
	# default, or whatever they picked in their own options menu) stays
	# untouched in those modes.
	if _mode != "Custom":
		return
	var mode : int = clamp(_custom_config.get("vsync_mode", 0), 0, 3)
	DisplayServer.window_set_vsync_mode(mode)


func _reset_to_defaults() -> void:
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_mode              = FSR_OFF
		vp.scaling_3d_scale             = 1.0
		vp.msaa_3d                      = AA_OFF
		vp.use_taa                      = false
		vp.screen_space_aa              = Viewport.SCREEN_SPACE_AA_DISABLED
		vp.positional_shadow_atlas_size = SHADOW_MID
		vp.mesh_lod_threshold           = 2.0
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_MID, true)
	ProjectSettings.set_setting(LOD_SETTING,              1.0)
	ProjectSettings.set_setting(SSAO_SETTING,             0)
	ProjectSettings.set_setting(SSIL_SETTING,             0)
	ProjectSettings.set_setting(TEX_FILTER_SETTING,       0)
	ProjectSettings.set_setting(SDFGI_PROBE_RAYS_SETTING, SDFGI_RAYS_LOW)
	ProjectSettings.set_setting(SDFGI_FRAMES_CONVERGE,    SDFGI_CONVERGE_LOW)
	ProjectSettings.set_setting(SDFGI_FRAMES_UPDATE,      SDFGI_LIGHT_LOW)
	ProjectSettings.set_setting("rendering/environment/screen_space_reflection/roughness_quality", 0)
	_apply_shadow_filter(SHADOW_FILTER_LOW)
	Engine.max_fps = 0
	# Vsync is left as-is — not reset, not forced. See _apply_vsync().
	_current_scale             = 0.0
	_current_shadow            = SHADOW_MID
	_current_shadow_filter     = SHADOW_FILTER_MID
	_fsr_aa_enabled            = false
	_fsr_aa_lock_timer         = 0.0
	_low_fps                   = false
	_warmup_done               = false
	_warmup_timer              = 0.0
	_warmup_fps_accum          = 0.0
	_warmup_fps_count          = 0
	_fps_accum                 = 0.0
	_fps_count                 = 0
	_ft_accum                  = 0.0
	_ft_sq_accum               = 0.0
	_ft_max                    = 0.0
	_check_timer               = 0.0
	_recovery_timer            = 0.0
	_baseline_fps              = 0.0
	_config_save_pending       = false
	_fxaa_locked_off           = false
	_shadow_desired            = SHADOW_MID
	_shadow_consecutive_count  = 0
	_thermal_samples.clear()
	_thermal_triggered         = false
	_thermal_baseline_fps      = 0.0
	_last_ft_stats             = {}
	_fr_print("Reset to defaults.")


func _schedule_mode(mode: String) -> void:
	if _profile_switch_timer > 0.0:
		_pending_mode = mode
		return
	if _mode == mode:
		return
	_pending_mode         = mode
	_profile_switch_timer = PROFILE_SWITCH_COOLDOWN


func _do_load_mode(mode: String) -> void:
	var is_builtin : bool = PROFILES.has(mode)
	var is_custom  : bool = mode == "Custom"
	if not is_builtin and not is_custom:
		return

	var prev_mode : String = _mode
	_mode = mode

	if is_custom:
		_profile = _custom_config.duplicate()
	else:
		_profile = PROFILES[mode].duplicate()

	_warmup_done       = false
	_warmup_timer      = 0.0
	_warmup_fps_accum  = 0.0
	_warmup_fps_count  = 0
	_low_fps           = false
	_recovery_timer    = 0.0
	_fsr_aa_enabled    = false
	_fsr_aa_lock_timer = 0.0
	_fps_accum         = 0.0
	_fps_count         = 0
	_ft_accum          = 0.0
	_ft_sq_accum       = 0.0
	_ft_max            = 0.0
	_shadow_desired           = _profile.get("shadow_min", SHADOW_MID)
	_shadow_consecutive_count = 0

	_apply_scale(_profile.get("scale_min", 0.65))
	_apply_lod()
	_apply_effects()
	if is_custom:
		_apply_custom_ssr()
		_apply_vsync()

	var vp := get_viewport()
	if vp:
		vp.scaling_3d_mode = FSR_OFF
		vp.msaa_3d         = AA_OFF
		vp.use_taa         = false
		_apply_screen_aa(vp)

	if prev_mode != mode:
		emit_signal("profile_changed", mode)
	_fr_print("Mode loaded: %s" % mode)


func _load_mode(mode: String) -> void:
	_do_load_mode(mode)

# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API — BUILT-IN MODES
# ══════════════════════════════════════════════════════════════════════════════

func SetEnabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	if not _enabled:
		_reset_to_defaults()
	else:
		_load_mode(_mode)


func is_enabled() -> bool:
	return _enabled


func Performance() -> void:
	if not _enabled: return
	_schedule_mode("Performance")
	_save_config("Performance")


func Balanced() -> void:
	if not _enabled: return
	_schedule_mode("Balanced")
	_save_config("Balanced")


func Quality() -> void:
	if not _enabled: return
	_schedule_mode("Quality")
	_save_config("Quality")


func SetSceneHint(hint: String) -> void:
	if not SCENE_HINT_OFFSETS.has(hint):
		push_warning("[FR] Unknown scene hint '%s'. Use 'light', 'normal', or 'heavy'." % hint)
		return
	_scene_hint = hint
	_apply_lod()
	_fr_print("Scene hint: '%s'" % hint)


func RunBenchmark() -> void:
	if _benchmarking: return
	_fr_print("Benchmark started.")
	_benchmarking      = true
	_benchmark_step    = 0
	_benchmark_timer   = 0.0
	_benchmark_results = {}
	_benchmark_accum   = 0.0
	_benchmark_count   = 0
	_advance_benchmark_step()


func SetDebugOverlay(value: bool) -> void:
	_debug_overlay_enabled = value
	if value:
		if _debug_canvas == null:
			_build_debug_overlay()
	else:
		_remove_debug_overlay()

# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API — CUSTOM MODE
# ══════════════════════════════════════════════════════════════════════════════

## Activate Custom mode — loads saved custom config and switches to it.
func Custom() -> void:
	if not _enabled: return
	_schedule_mode("Custom")
	_save_config("Custom")


## Apply a full custom config dictionary at once.
## Keys match CUSTOM_MODE_DEFAULTS.  Missing keys keep current values.
func SetCustomConfig(cfg: Dictionary) -> void:
	for key in cfg:
		_custom_config[key] = cfg[key]
	_save_custom_config()
	if _mode == "Custom":
		_profile = _custom_config.duplicate()
		_apply_lod()
		_apply_effects()
		_apply_custom_ssr()
		_apply_vsync()


## Get a copy of the current custom config.
func GetCustomConfig() -> Dictionary:
	return _custom_config.duplicate()


## Rename the custom mode.
func SetCustomName(new_name: String) -> void:
	_custom_config["name"] = new_name
	_save_custom_config()


## Individual setters for the custom mode — usable at runtime.

func SetCustomResolution(scale_min: float, scale_max: float) -> void:
	_custom_config["scale_min"] = clampf(scale_min, 0.30, 1.0)
	_custom_config["scale_max"] = clampf(scale_max, 0.30, 1.0)
	if _mode == "Custom":
		_profile["scale_min"] = _custom_config["scale_min"]
		_profile["scale_max"] = _custom_config["scale_max"]
	_save_custom_config()


func SetCustomShadow(shadow_min: int, shadow_max: int) -> void:
	_custom_config["shadow_min"] = shadow_min
	_custom_config["shadow_max"] = shadow_max
	if _mode == "Custom":
		_profile["shadow_min"] = shadow_min
		_profile["shadow_max"] = shadow_max
	_save_custom_config()


func SetCustomShadowFilter(filter_min: int, filter_max: int) -> void:
	_custom_config["shadow_filter_min"] = filter_min
	_custom_config["shadow_filter_max"] = filter_max
	_save_custom_config()


func SetCustomFPSRange(fps_min: float, fps_max: float) -> void:
	_custom_config["fps_min"] = maxf(fps_min, 10.0)
	_custom_config["fps_max"] = maxf(fps_max, fps_min)
	if _mode == "Custom":
		_profile["fps_min"] = _custom_config["fps_min"]
		_profile["fps_max"] = _custom_config["fps_max"]
	_save_custom_config()


func SetCustomTexViewport(mode: int) -> void:
	# 0 = Nearest, 1 = Linear
	_custom_config["tex_viewport"] = clamp(mode, 0, 1)
	if _mode == "Custom":
		_apply_effects()
	_save_custom_config()


func SetCustomAA(aa_min: int, aa_max: int) -> void:
	# 0 = Off, 1 = FXAA, 2 = TAA
	_custom_config["aa_min"]  = clamp(aa_min, 0, 2)
	_custom_config["aa_max"]  = clamp(aa_max, 0, 2)
	_custom_config["aa_mode"] = _custom_config["aa_max"]
	if _mode == "Custom":
		_profile["aa_mode"] = _custom_config["aa_mode"]
		_apply_effects()
	_save_custom_config()


func SetCustomSDFGI(enabled: bool, rays: int, converge: int, lights: int) -> void:
	_custom_config["sdfgi_enabled"]  = enabled
	_custom_config["sdfgi_rays"]     = clamp(rays,     0, 3)
	_custom_config["sdfgi_converge"] = clamp(converge, 0, 5)
	_custom_config["sdfgi_lights"]   = clamp(lights,   1, 3)
	if _mode == "Custom":
		_profile["sdfgi_enabled"]  = enabled
		_profile["sdfgi_rays"]     = _custom_config["sdfgi_rays"]
		_profile["sdfgi_converge"] = _custom_config["sdfgi_converge"]
		_profile["sdfgi_lights"]   = _custom_config["sdfgi_lights"]
		_apply_effects()
	_save_custom_config()


func SetCustomSSIL(enabled: bool, quality_min: int, quality_max: int) -> void:
	_custom_config["ssil_enabled"] = enabled
	_custom_config["ssil_quality"] = clamp(quality_max, 0, 4)
	if _mode == "Custom":
		_profile["ssil_enabled"] = enabled
		_profile["ssil_quality"] = _custom_config["ssil_quality"]
		_apply_effects()
	_save_custom_config()


func SetCustomSSAO(enabled: bool, quality_min: int, quality_max: int) -> void:
	_custom_config["ssao_enabled"] = enabled
	_custom_config["ssao_quality"] = clamp(quality_max, 0, 4)
	if _mode == "Custom":
		_profile["ssao_enabled"] = enabled
		_profile["ssao_quality"] = _custom_config["ssao_quality"]
		_apply_effects()
	_save_custom_config()


func SetCustomSSR(enabled: bool, quality_min: int, quality_max: int) -> void:
	_custom_config["ssr_enabled"] = enabled
	_custom_config["ssr_quality"] = clamp(quality_max, 0, 4)
	if _mode == "Custom":
		_apply_custom_ssr()
	_save_custom_config()


## FSR on/off + scale range (fsr_scale_min / fsr_scale_max are the rendering
## scale bounds that FSR operates within — independent of the adaptive
## scale_min / scale_max so you can keep FSR upscaling in a specific window).
func SetCustomFSR(enabled: bool, scale_min: float, scale_max: float) -> void:
	_custom_config["fsr_enabled"]   = enabled
	_custom_config["fsr_scale_min"] = clampf(scale_min, 0.30, 1.0)
	_custom_config["fsr_scale_max"] = clampf(scale_max, 0.30, 1.0)
	if _mode == "Custom":
		_profile["fsr_enabled"]   = enabled
		_profile["fsr_scale_min"] = _custom_config["fsr_scale_min"]
		_profile["fsr_scale_max"] = _custom_config["fsr_scale_max"]
		# Immediately push the FSR state
		if not enabled:
			_set_fsr_aa(false)
		else:
			_update_fsr_aa(_baseline_fps)
	_save_custom_config()
	_fr_print("FSR %s  scale %.0f%%–%.0f%%" % [
		"ON" if enabled else "OFF",
		_custom_config["fsr_scale_min"] * 100.0,
		_custom_config["fsr_scale_max"] * 100.0,
	])


## Vsync for Custom mode only. 0=Off 1=On 2=Adaptive 3=Mailbox.
## Built-in modes (Performance/Balanced/Quality) never call this — they
## always leave the player's own vsync setting untouched.
func SetCustomVsync(mode: int) -> void:
	_custom_config["vsync_mode"] = clamp(mode, 0, 3)
	if _mode == "Custom":
		_apply_vsync()
	_save_custom_config()
	_fr_print("Vsync: %s" % get_vsync_mode())


func SetCustomLOD(lod_min: float, lod_max: float) -> void:
	_custom_config["lod_min"]       = maxf(lod_min, 0.0)
	_custom_config["lod_max"]       = maxf(lod_max, lod_min)
	_custom_config["lod_threshold"] = (lod_min + lod_max) * 0.5
	if _mode == "Custom":
		_profile["lod_threshold"] = _custom_config["lod_threshold"]
		_profile["lod_min"]       = _custom_config["lod_min"]
		_profile["lod_max"]       = _custom_config["lod_max"]
		_apply_lod()
	_save_custom_config()


func SetCustomSmoothTime(seconds: float) -> void:
	_custom_config["smooth_time"] = maxf(seconds, 0.1)
	if _mode == "Custom":
		_profile["smooth_time"] = _custom_config["smooth_time"]
	_save_custom_config()


func SetCompatibilityMode(enabled: bool) -> void:
	_custom_config["compatibility_mode"] = enabled
	if enabled:
		_custom_config["mobile_mode"] = false
	if _mode == "Custom":
		_profile["compatibility_mode"] = enabled
		_profile["mobile_mode"]        = _custom_config["mobile_mode"]
		_apply_effects()
		_apply_custom_ssr()
	_save_custom_config()
	_fr_print("Compatibility mode: %s" % str(enabled))


func SetMobileMode(enabled: bool) -> void:
	_custom_config["mobile_mode"] = enabled
	if enabled:
		_custom_config["compatibility_mode"] = false
	if _mode == "Custom":
		_profile["mobile_mode"]        = enabled
		_profile["compatibility_mode"] = _custom_config["compatibility_mode"]
		_apply_effects()
		_apply_custom_ssr()
	_save_custom_config()
	_fr_print("Mobile mode: %s" % str(enabled))


## Toggles the [FR] debug prints in the output console.
## This is global — it applies in every mode (Performance / Balanced /
## Quality / Custom), not just Custom mode.
func SetShowPrints(enabled: bool) -> void:
	_custom_config["show_prints"] = enabled
	_save_custom_config()
	print("[FR] Prints %s" % ("enabled" if enabled else "disabled"))


func is_show_prints_enabled() -> bool:
	return _custom_config.get("show_prints", true)


## Reset custom config to factory defaults and reload if active.
func ResetCustomToDefaults() -> void:
	_custom_config = {}
	for key in CUSTOM_MODE_DEFAULTS:
		_custom_config[key] = CUSTOM_MODE_DEFAULTS[key]
	_save_custom_config()
	if _mode == "Custom":
		_profile = _custom_config.duplicate()
		_apply_lod()
		_apply_effects()
		_apply_custom_ssr()
		_apply_vsync()
	_fr_print("Custom mode reset to defaults.")

func ExportCustomMode() -> String:
	var lines : Array[String] = []
	lines.append("# FR Custom Mode Export — " + _custom_config.get("name", "Custom"))
	lines.append("{")
	for key in _custom_config:
		var val = _custom_config[key]
		if val is String:
			lines.append('\t"%s": "%s",' % [key, val])
		elif val is bool:
			lines.append('\t"%s": %s,' % [key, "true" if val else "false"])
		elif val is float:
			lines.append('\t"%s": %.4f,' % [key, val])
		else:
			lines.append('\t"%s": %s,' % [key, str(val)])
	lines.append("}")
	var result : String = "\n".join(lines)
	_fr_print("Custom mode exported.")
	return result


## Import a custom config from a dictionary (e.g. parsed from ExportCustomMode).
func ImportCustomMode(cfg: Dictionary) -> void:
	for key in CUSTOM_MODE_DEFAULTS:
		if cfg.has(key):
			_custom_config[key] = cfg[key]
	_save_custom_config()
	if _mode == "Custom":
		_profile = _custom_config.duplicate()
		_apply_lod()
		_apply_effects()
		_apply_custom_ssr()
		_apply_vsync()
	_fr_print("Custom mode imported: %s" % _custom_config.get("name", "Custom"))

# ══════════════════════════════════════════════════════════════════════════════
# GETTERS
# ══════════════════════════════════════════════════════════════════════════════

func get_mode() -> String:
	if _mode == "Custom":
		return _custom_config.get("name", "Custom")
	return _mode

func get_mode_key()       -> String: return _mode
func get_scene_hint()     -> String: return _scene_hint
func get_scale()          -> String: return "%d%%" % int(_current_scale * 100)
func get_scale_float()    -> float:  return _current_scale
func get_shadow()         -> String: return str(_current_shadow)
func get_physics_ticks()  -> int:    return Engine.physics_ticks_per_second
func get_recovery_timer() -> float:  return _recovery_timer
func get_baseline_fps()   -> float:  return _baseline_fps
func get_thermal_state()  -> String: return "triggered" if _thermal_triggered else "ok"
func is_in_background()   -> bool:   return _is_in_background
func is_benchmarking()    -> bool:   return _benchmarking
func get_lod_threshold()  -> float:  return _profile.get("lod_threshold", 1.0)
func get_custom_name()    -> String: return _custom_config.get("name", "Custom")

func get_shadow_filter() -> String:
	match _current_shadow_filter:
		SHADOW_FILTER_HIGH : return "High (PCF13)"
		SHADOW_FILTER_MID  : return "Mid (PCF5)"
		_                  : return "Low (disabled)"

func get_fsr() -> String:
	if _mode == "Custom":
		if not _custom_config.get("fsr_enabled", true):
			return "OFF (disabled)"
		if _fsr_aa_enabled:
			return "FSR 1  %.0f%%–%.0f%%" % [
				_custom_config.get("fsr_scale_min", 0.50) * 100.0,
				_custom_config.get("fsr_scale_max", 0.75) * 100.0,
			]
		return "FSR ready  %.0f%%–%.0f%%" % [
			_custom_config.get("fsr_scale_min", 0.50) * 100.0,
			_custom_config.get("fsr_scale_max", 0.75) * 100.0,
		]
	return "FSR 1" if _fsr_aa_enabled else "OFF"

func get_aa() -> String:
	if _fsr_aa_enabled and not _low_fps:
		return "Disabled (FSR active)"
	if _fxaa_locked_off:
		return "Disabled (low FPS lock)"
	return "FXAA"

func get_vsync_mode() -> String:
	if _mode != "Custom":
		return "Player-controlled"
	match int(_custom_config.get("vsync_mode", 0)):
		1: return "Enabled"
		2: return "Adaptive"
		3: return "Mailbox"
		_: return "Disabled"

func get_ssao_quality() -> String:
	var labels : Array[String] = ["Very Low", "Low", "Low-Med", "Medium", "High"]
	var q : int = _profile.get("ssao_quality", 0)
	return labels[q] if q >= 0 and q < labels.size() else "?"

func get_ssil_quality() -> String:
	var labels : Array[String] = ["Very Low", "Low", "Low-Med", "Medium", "High"]
	var q : int = _profile.get("ssil_quality", 0)
	return labels[q] if q >= 0 and q < labels.size() else "?"

func get_sdfgi_quality() -> String:
	if _profile.is_empty(): return "?"
	var rays_map  := { 0: "8 rays",  1: "16 rays", 2: "32 rays", 3: "64 rays" }
	var conv_map  := { 0: "5f",  1: "10f", 2: "15f", 3: "20f", 4: "25f", 5: "30f" }
	var light_map := { 1: "every 2f", 2: "every 4f", 3: "every 8f" }
	return "Rays:%s  Conv:%s  Lights:%s" % [
		rays_map.get(_profile.get("sdfgi_rays",     SDFGI_RAYS_LOW),     "?"),
		conv_map.get(_profile.get("sdfgi_converge", SDFGI_CONVERGE_LOW), "?"),
		light_map.get(_profile.get("sdfgi_lights",  SDFGI_LIGHT_LOW),    "?"),
	]

func get_ssr_quality() -> String:
	if _mode != "Custom": return "N/A"
	var labels : Array[String] = ["Disabled", "Low", "Medium", "High", "Ultra"]
	var q : int = _custom_config.get("ssr_quality", 0)
	if not _custom_config.get("ssr_enabled", false): return "Disabled"
	return labels[q] if q >= 0 and q < labels.size() else "?"

func get_frametime_stats() -> Dictionary: return _last_ft_stats
