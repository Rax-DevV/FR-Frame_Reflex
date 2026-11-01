<h2>What is Frame Reflex?</h2>
<p>
  Frame Reflex is a <strong>single-script autoload plugin for Godot 4.3+</strong> that continuously measures your game's real runtime performance and adjusts the rendering pipeline on the fly &mdash; render scale, shadow quality, FSR,&nbsp;LOD budget, SSAO, SSIL, SDFGI, and more.
</p>
<p>
  <strong>No manual per-device config. No build variants. Drop it in and forget about it.</strong>
</p>
<hr>
<h2>How It Works ?</h2>
<p><strong>FrameReflex</strong> is a Godot 4 plugin that automatically adjusts rendering quality (resolution scale, shadows, LOD, FSR) in real-time to maintain a stable 60+ FPS target. It takes 2–10 seconds on startup to detect your device's performance, then keeps things running smoothly with three manual presets (Performance / Balanced / Quality / Custom) controllable from the editor.<br></p>
<hr>
<h2>Quality Profiles</h2>
<p>Four built-in profiles, each defining a <em>render scale band</em> (not a fixed value). The scale drifts continuously within that band in 2.5% steps, with a 3-second recovery cooldown and 5 FPS hysteresis buffer to prevent oscillation.</p>
<table>
  <tbody><tr>
	<th>Profile</th>
	<th>Render Scale</th>
	<th>LOD Threshold</th>
	<th>SSAO / SSIL</th>
	<th>Texture Filter</th>
  </tr>
  <tr>
	<td><strong>Performance</strong></td>
	<td>50 – 70%</td>
	<td>15 px</td>
	<td>Off</td>
	<td>Off</td>
  </tr>
  <tr>
	<td><strong>Balanced</strong></td>
	<td>60 – 75%</td>
	<td>10 px</td>
	<td>Off</td>
	<td>Low</td>
  </tr>
  <tr>
	<td><strong>Quality</strong></td>
	<td>70 – 80%</td>
	<td>5px</td>
	<td>On<br></td>
	<td>Low<br></td>
  </tr>
  <tr>
	<td><strong>Custom</strong></td>
	<td>Custom</td>
	<td>Custom</td><td>Custom<br><br></td>
	<td>Custom<br></td>
  </tr>
</tbody></table>
<hr>
<h2>NEW UPDATE = IMPROVED !</h2>
<p><img src="https://img.itch.zone/aW1nLzI3NzY2MTI5LnBuZw==/original/ng7glJ.png"></p>
<h2>Adaptive Systems&nbsp;</h2>
<p></p>
<h3>NEW&nbsp;&nbsp;CUSTOM MODE</h3>
<p>Customize your own mode and export it !&nbsp;</p>
<p><img src="https://img.itch.zone/aW1nLzI3NzY2MTQ0LnBuZw==/original/fr70F%2F.png"><br></p>
<p><br></p>
<h3>Stutter Detection</h3>
<p>Uses <strong>frame-time standard deviation</strong>, not just average FPS. Detects hitching even when average FPS looks healthy. Triggers an immediate scale-down when variance exceeds the threshold.</p>
<h3>Thermal Throttle Detection</h3>
<p>Tracks a rolling 60-second FPS baseline. If your device's performance drifts <strong>20% below that baseline</strong> (a sign of thermal throttling), it automatically steps the quality profile down &mdash; Performance → Balanced → Quality in reverse.</p>
<h3>Dynamic FSR</h3>
<p>Enables <strong>FSR 1 </strong>&nbsp;automatically when there's FPS headroom. Falls back to FXAA when FPS is lower.&nbsp;</p>
<h3>Dynamic Shadows</h3>
<p>Shadow atlas size and directional shadow filter quality (PCF disabled / PCF5 / PCF13) scale with FPS in three tiers &mdash; all without touching your scene or lights.</p>
<h3>Background Mode</h3>
<p>Caps FPS at <strong>30 when the window loses focus</strong>. Re-runs the warmup window when refocused so quality recalibrates cleanly.</p>
<h2>Smart Benchmark</h2>
<p>Call <code>FRManager.RunBenchmark()</code> on first launch to test all three profiles for 2 seconds each. Frame Reflex picks the <strong>highest-quality profile that sustains your FPS target</strong> and saves the result &mdash; so the best profile auto-loads on every future session.</p>
<hr>
<h2>Setup &mdash; 2 Steps</h2>
<ol>
  <li>Go to <strong>Project → Plugins → FR - Frame Reflex</strong> and set it to <strong>ON</strong></li>
  <li>Go to <strong>Project → AutoLoad</strong> and add <strong>FRManager.gd</strong></li></ol>
<hr>
<p><em>Compatible with Godot 4.3 and above. Works on Windows, macOS, Linux, and Android.</em></p>
<p>ـــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــ</p>
<p><strong>Having more FPS&nbsp;without effecting the quality ..!</strong></p>
<figure><strong><img src="https://img.itch.zone/aW1nLzI2ODAzNTQ3LnBuZw==/original/GvaS9i.png"></strong></figure>
<h4></h4>
